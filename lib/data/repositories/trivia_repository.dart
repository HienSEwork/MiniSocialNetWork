import 'package:sqflite/sqflite.dart';

import '../local/local_database.dart';
import '../models/trivia_models.dart';
import '../providers/module_state.dart';

typedef TriviaDashboardData = ({
  List<TriviaQuestion> questions,
  TriviaDailySession session,
  QuestProfile profile,
  List<QuestBadge> badges,
  Set<String> answeredQuestionIds,
});

class TriviaRepository {
  TriviaRepository({LocalDatabase? database})
    : _store = database ?? LocalDatabase.instance;

  final LocalDatabase _store;

  Future<TriviaDashboardData> loadDaily(String userId, {DateTime? now}) async {
    try {
      final db = await _store.database;
      final date = (now ?? DateTime.now()).toLocal();
      final dateKey = _dateKey(date);
      final sessionId = '$userId@$dateKey';
      await db.transaction((txn) async {
        await txn.insert('quest_profiles', {
          'user_id': userId,
          'xp': 0,
          'current_streak': 0,
          'longest_streak': 0,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
        final existing = await txn.query(
          'trivia_daily_sessions',
          where: 'id = ?',
          whereArgs: [sessionId],
          limit: 1,
        );
        if (existing.isEmpty) {
          final bank = await txn.query(
            'trivia_questions',
            where: 'is_active = 1',
            orderBy: 'id ASC',
          );
          if (bank.length < 3) {
            throw const ModuleDataException(
              'Ngân hàng câu hỏi cần ít nhất 3 câu đang hoạt động.',
            );
          }
          await txn.insert('trivia_daily_sessions', {
            'id': sessionId,
            'user_id': userId,
            'quest_date': dateKey,
            'score': 0,
            'xp_earned': 0,
            'answered_count': 0,
            'is_completed': 0,
          });
          final dayNumber =
              DateTime(
                date.year,
                date.month,
                date.day,
              ).millisecondsSinceEpoch ~/
              Duration.millisecondsPerDay;
          final start = dayNumber % bank.length;
          for (var position = 0; position < 3; position++) {
            final row = bank[(start + position) % bank.length];
            await txn.insert('trivia_daily_questions', {
              'session_id': sessionId,
              'question_id': row['id'],
              'position': position,
            });
          }
        }
      });

      final sessionRows = await db.query(
        'trivia_daily_sessions',
        where: 'id = ?',
        whereArgs: [sessionId],
        limit: 1,
      );
      final questionRows = await db.rawQuery(
        '''
          SELECT q.*
          FROM trivia_daily_questions d
          JOIN trivia_questions q ON q.id = d.question_id
          WHERE d.session_id = ?
          ORDER BY d.position ASC
        ''',
        [sessionId],
      );
      final profileRows = await db.query(
        'quest_profiles',
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      );
      final answerRows = await db.query(
        'trivia_answers',
        columns: ['question_id'],
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
      final badgeRows = await db.rawQuery(
        '''
          SELECT b.*, u.unlocked_at
          FROM user_quest_badges u
          JOIN quest_badges b ON b.code = u.badge_code
          WHERE u.user_id = ?
          ORDER BY u.unlocked_at DESC
        ''',
        [userId],
      );
      if (sessionRows.isEmpty || profileRows.isEmpty) {
        throw const ModuleDataException(
          'Không thể khởi tạo Daily Quest hôm nay.',
        );
      }
      return (
        questions: questionRows.map(TriviaQuestion.fromMap).toList(),
        session: TriviaDailySession.fromMap(sessionRows.first),
        profile: QuestProfile.fromMap(profileRows.first),
        badges: badgeRows.map(QuestBadge.fromMap).toList(),
        answeredQuestionIds: answerRows
            .map((row) => '${row['question_id']}')
            .toSet(),
      );
    } on ModuleDataException {
      rethrow;
    } on DatabaseException catch (error) {
      throw ModuleDataException(
        'Không thể tải Daily Quest. Hãy thử lại.',
        error,
      );
    } catch (error) {
      throw ModuleDataException('Dữ liệu Daily Quest không hợp lệ.', error);
    }
  }

  Future<TriviaAnswerResult> answer({
    required String userId,
    required String questionId,
    required int selectedIndex,
    DateTime? now,
  }) async {
    try {
      final db = await _store.database;
      final completedAt = (now ?? DateTime.now()).toLocal();
      final dateKey = _dateKey(completedAt);
      final sessionId = '$userId@$dateKey';
      return await db.transaction((txn) async {
        final sessionRows = await txn.query(
          'trivia_daily_sessions',
          where: 'id = ?',
          whereArgs: [sessionId],
          limit: 1,
        );
        if (sessionRows.isEmpty) {
          throw const ModuleDataException(
            'Phiên Daily Quest chưa sẵn sàng. Hãy tải lại.',
          );
        }
        final session = TriviaDailySession.fromMap(sessionRows.first);
        if (session.isCompleted) {
          throw const ModuleDataException(
            'Bạn đã hoàn thành thử thách hôm nay.',
          );
        }
        final assigned = await txn.rawQuery(
          '''
            SELECT q.* FROM trivia_daily_questions d
            JOIN trivia_questions q ON q.id = d.question_id
            WHERE d.session_id = ? AND q.id = ?
          ''',
          [sessionId, questionId],
        );
        if (assigned.isEmpty) {
          throw const ModuleDataException(
            'Câu hỏi không thuộc thử thách hôm nay.',
          );
        }
        final previous = await txn.query(
          'trivia_answers',
          where: 'session_id = ? AND question_id = ?',
          whereArgs: [sessionId, questionId],
          limit: 1,
        );
        if (previous.isNotEmpty) {
          throw const ModuleDataException('Câu hỏi này đã được trả lời.');
        }
        final question = TriviaQuestion.fromMap(assigned.first);
        if (selectedIndex < 0 || selectedIndex >= question.options.length) {
          throw const ModuleDataException('Lựa chọn trả lời không hợp lệ.');
        }
        final correct = selectedIndex == question.correctIndex;
        final newAnswered = session.answeredCount + 1;
        final newScore = session.score + (correct ? 10 : 0);
        final gainedXp = correct ? question.xpReward : 0;
        final newXpEarned = session.xpEarned + gainedXp;
        final completed = newAnswered >= 3;
        await txn.insert('trivia_answers', {
          'session_id': sessionId,
          'question_id': questionId,
          'selected_index': selectedIndex,
          'is_correct': correct ? 1 : 0,
          'answered_at': completedAt.toUtc().toIso8601String(),
        });
        await txn.update(
          'trivia_daily_sessions',
          {
            'score': newScore,
            'xp_earned': newXpEarned,
            'answered_count': newAnswered,
            'is_completed': completed ? 1 : 0,
            'completed_at': completed
                ? completedAt.toUtc().toIso8601String()
                : null,
          },
          where: 'id = ?',
          whereArgs: [sessionId],
        );

        final profileRows = await txn.query(
          'quest_profiles',
          where: 'user_id = ?',
          whereArgs: [userId],
          limit: 1,
        );
        var profile = profileRows.isEmpty
            ? QuestProfile(
                userId: userId,
                xp: 0,
                currentStreak: 0,
                longestStreak: 0,
              )
            : QuestProfile.fromMap(profileRows.first);
        var streak = profile.currentStreak;
        if (completed) {
          streak = QuestStreakCalculator.nextStreak(
            lastCompletedDate: profile.lastCompletedDate,
            completedAt: completedAt,
            currentStreak: profile.currentStreak,
          );
        }
        profile = profile.copyWith(
          xp: profile.xp + gainedXp,
          currentStreak: streak,
          longestStreak: streak > profile.longestStreak
              ? streak
              : profile.longestStreak,
          lastCompletedDate: completed ? dateKey : profile.lastCompletedDate,
        );
        await txn.insert(
          'quest_profiles',
          profile.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        final newBadges = <QuestBadge>[];
        if (completed) {
          final badgeCodes = <String>['quest-first'];
          if (streak >= 3) badgeCodes.add('quest-streak-3');
          if (profile.xp >= 100) badgeCodes.add('quest-xp-100');
          if (newScore == 30) badgeCodes.add('quest-perfect');
          for (final code in badgeCodes) {
            final inserted = await txn.insert('user_quest_badges', {
              'user_id': userId,
              'badge_code': code,
              'unlocked_at': completedAt.toUtc().toIso8601String(),
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
            if (inserted > 0) {
              final rows = await txn.query(
                'quest_badges',
                where: 'code = ?',
                whereArgs: [code],
                limit: 1,
              );
              if (rows.isNotEmpty) {
                newBadges.add(
                  QuestBadge.fromMap({
                    ...rows.first,
                    'unlocked_at': completedAt.toUtc().toIso8601String(),
                  }),
                );
              }
            }
          }
        }
        return TriviaAnswerResult(
          isCorrect: correct,
          correctIndex: question.correctIndex,
          explanation: question.explanation,
          session: session.copyWith(
            score: newScore,
            xpEarned: newXpEarned,
            answeredCount: newAnswered,
            isCompleted: completed,
            completedAt: completed ? completedAt : null,
          ),
          profile: profile,
          newBadges: newBadges,
        );
      });
    } on ModuleDataException {
      rethrow;
    } on DatabaseException catch (error) {
      throw ModuleDataException(
        'Không thể lưu câu trả lời. Hãy thử lại.',
        error,
      );
    } catch (error) {
      throw ModuleDataException('Không thể xử lý câu trả lời.', error);
    }
  }

  Future<List<TriviaQuestion>> listAllQuestions() async {
    try {
      final db = await _store.database;
      final rows = await db.query(
        'trivia_questions',
        orderBy: 'updated_at DESC',
      );
      return rows.map(TriviaQuestion.fromMap).toList();
    } on DatabaseException catch (error) {
      throw ModuleDataException('Không thể tải ngân hàng câu hỏi.', error);
    } catch (error) {
      throw ModuleDataException('Dữ liệu câu hỏi không hợp lệ.', error);
    }
  }

  Future<void> createQuestion(
    String adminUserId,
    TriviaQuestion question,
  ) async {
    try {
      final db = await _store.database;
      await _requireAdmin(db, adminUserId);
      await db.insert('trivia_questions', question.toMap());
    } on ModuleDataException {
      rethrow;
    } on DatabaseException catch (error) {
      throw ModuleDataException('Không thể thêm câu hỏi.', error);
    }
  }

  Future<void> updateQuestion(
    String adminUserId,
    TriviaQuestion question,
  ) async {
    try {
      final db = await _store.database;
      await _requireAdmin(db, adminUserId);
      final changed = await db.update(
        'trivia_questions',
        question.copyWith(updatedAt: DateTime.now()).toMap(),
        where: 'id = ?',
        whereArgs: [question.id],
      );
      if (changed == 0) {
        throw const ModuleDataException('Không tìm thấy câu hỏi.');
      }
    } on ModuleDataException {
      rethrow;
    } on DatabaseException catch (error) {
      throw ModuleDataException('Không thể cập nhật câu hỏi.', error);
    }
  }

  Future<void> deleteQuestion(String adminUserId, String id) async {
    try {
      final db = await _store.database;
      await _requireAdmin(db, adminUserId);
      final assigned =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM trivia_daily_questions WHERE question_id = ?',
              [id],
            ),
          ) ??
          0;
      if (assigned > 0) {
        await db.update(
          'trivia_questions',
          {
            'is_active': 0,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      } else {
        await db.delete('trivia_questions', where: 'id = ?', whereArgs: [id]);
      }
    } on ModuleDataException {
      rethrow;
    } on DatabaseException catch (error) {
      throw ModuleDataException('Không thể xóa câu hỏi.', error);
    }
  }

  Future<void> _requireAdmin(DatabaseExecutor db, String userId) async {
    final rows = await db.query(
      'users',
      columns: ['role'],
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty || rows.first['role'] != 'Admin') {
      throw const ModuleDataException(
        'Bạn không có quyền quản trị module này.',
      );
    }
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
