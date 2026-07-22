import 'dart:convert';

class TriviaQuestion {
  const TriviaQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.category,
    required this.xpReward,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String category;
  final int xpReward;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory TriviaQuestion.fromMap(Map<String, Object?> map) {
    final raw = jsonDecode('${map['options_json'] ?? '[]'}');
    return TriviaQuestion(
      id: '${map['id'] ?? ''}',
      question: '${map['question'] ?? ''}',
      options: raw is List ? raw.map((item) => '$item').toList() : const [],
      correctIndex: (map['correct_index'] as num?)?.toInt() ?? 0,
      explanation: '${map['explanation'] ?? ''}',
      category: '${map['category'] ?? ''}',
      xpReward: (map['xp_reward'] as num?)?.toInt() ?? 0,
      isActive: (map['is_active'] as num?)?.toInt() == 1,
      createdAt: DateTime.tryParse('${map['created_at']}') ?? DateTime(1970),
      updatedAt: DateTime.tryParse('${map['updated_at']}') ?? DateTime(1970),
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'question': question,
    'options_json': jsonEncode(options),
    'correct_index': correctIndex,
    'explanation': explanation,
    'category': category,
    'xp_reward': xpReward,
    'is_active': isActive ? 1 : 0,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };

  TriviaQuestion copyWith({
    String? id,
    String? question,
    List<String>? options,
    int? correctIndex,
    String? explanation,
    String? category,
    int? xpReward,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TriviaQuestion(
    id: id ?? this.id,
    question: question ?? this.question,
    options: options ?? this.options,
    correctIndex: correctIndex ?? this.correctIndex,
    explanation: explanation ?? this.explanation,
    category: category ?? this.category,
    xpReward: xpReward ?? this.xpReward,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class TriviaDailySession {
  const TriviaDailySession({
    required this.id,
    required this.userId,
    required this.questDate,
    required this.score,
    required this.xpEarned,
    required this.answeredCount,
    required this.isCompleted,
    this.completedAt,
  });

  final String id;
  final String userId;
  final String questDate;
  final int score;
  final int xpEarned;
  final int answeredCount;
  final bool isCompleted;
  final DateTime? completedAt;

  factory TriviaDailySession.fromMap(Map<String, Object?> map) =>
      TriviaDailySession(
        id: '${map['id'] ?? ''}',
        userId: '${map['user_id'] ?? ''}',
        questDate: '${map['quest_date'] ?? ''}',
        score: (map['score'] as num?)?.toInt() ?? 0,
        xpEarned: (map['xp_earned'] as num?)?.toInt() ?? 0,
        answeredCount: (map['answered_count'] as num?)?.toInt() ?? 0,
        isCompleted: (map['is_completed'] as num?)?.toInt() == 1,
        completedAt: DateTime.tryParse('${map['completed_at'] ?? ''}'),
      );

  Map<String, Object?> toMap() => {
    'id': id,
    'user_id': userId,
    'quest_date': questDate,
    'score': score,
    'xp_earned': xpEarned,
    'answered_count': answeredCount,
    'is_completed': isCompleted ? 1 : 0,
    'completed_at': completedAt?.toUtc().toIso8601String(),
  };

  TriviaDailySession copyWith({
    String? id,
    String? userId,
    String? questDate,
    int? score,
    int? xpEarned,
    int? answeredCount,
    bool? isCompleted,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) => TriviaDailySession(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    questDate: questDate ?? this.questDate,
    score: score ?? this.score,
    xpEarned: xpEarned ?? this.xpEarned,
    answeredCount: answeredCount ?? this.answeredCount,
    isCompleted: isCompleted ?? this.isCompleted,
    completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
  );
}

class QuestProfile {
  const QuestProfile({
    required this.userId,
    required this.xp,
    required this.currentStreak,
    required this.longestStreak,
    this.lastCompletedDate,
  });

  final String userId;
  final int xp;
  final int currentStreak;
  final int longestStreak;
  final String? lastCompletedDate;

  factory QuestProfile.fromMap(Map<String, Object?> map) => QuestProfile(
    userId: '${map['user_id'] ?? ''}',
    xp: (map['xp'] as num?)?.toInt() ?? 0,
    currentStreak: (map['current_streak'] as num?)?.toInt() ?? 0,
    longestStreak: (map['longest_streak'] as num?)?.toInt() ?? 0,
    lastCompletedDate: map['last_completed_date']?.toString(),
  );

  Map<String, Object?> toMap() => {
    'user_id': userId,
    'xp': xp,
    'current_streak': currentStreak,
    'longest_streak': longestStreak,
    'last_completed_date': lastCompletedDate,
  };

  QuestProfile copyWith({
    String? userId,
    int? xp,
    int? currentStreak,
    int? longestStreak,
    String? lastCompletedDate,
    bool clearLastCompletedDate = false,
  }) => QuestProfile(
    userId: userId ?? this.userId,
    xp: xp ?? this.xp,
    currentStreak: currentStreak ?? this.currentStreak,
    longestStreak: longestStreak ?? this.longestStreak,
    lastCompletedDate: clearLastCompletedDate
        ? null
        : lastCompletedDate ?? this.lastCompletedDate,
  );
}

class QuestBadge {
  const QuestBadge({
    required this.code,
    required this.name,
    required this.description,
    required this.iconCode,
    required this.requirementType,
    required this.requirementValue,
    this.unlockedAt,
  });

  final String code;
  final String name;
  final String description;
  final int iconCode;
  final String requirementType;
  final int requirementValue;
  final DateTime? unlockedAt;

  factory QuestBadge.fromMap(Map<String, Object?> map) => QuestBadge(
    code: '${map['code'] ?? ''}',
    name: '${map['name'] ?? ''}',
    description: '${map['description'] ?? ''}',
    iconCode: (map['icon_code'] as num?)?.toInt() ?? 0xe838,
    requirementType: '${map['requirement_type'] ?? ''}',
    requirementValue: (map['requirement_value'] as num?)?.toInt() ?? 0,
    unlockedAt: DateTime.tryParse('${map['unlocked_at'] ?? ''}'),
  );

  Map<String, Object?> toMap() => {
    'code': code,
    'name': name,
    'description': description,
    'icon_code': iconCode,
    'requirement_type': requirementType,
    'requirement_value': requirementValue,
    'unlocked_at': unlockedAt?.toUtc().toIso8601String(),
  };

  QuestBadge copyWith({
    String? code,
    String? name,
    String? description,
    int? iconCode,
    String? requirementType,
    int? requirementValue,
    DateTime? unlockedAt,
    bool clearUnlockedAt = false,
  }) => QuestBadge(
    code: code ?? this.code,
    name: name ?? this.name,
    description: description ?? this.description,
    iconCode: iconCode ?? this.iconCode,
    requirementType: requirementType ?? this.requirementType,
    requirementValue: requirementValue ?? this.requirementValue,
    unlockedAt: clearUnlockedAt ? null : unlockedAt ?? this.unlockedAt,
  );
}

class TriviaAnswerResult {
  const TriviaAnswerResult({
    required this.isCorrect,
    required this.correctIndex,
    required this.explanation,
    required this.session,
    required this.profile,
    required this.newBadges,
  });

  final bool isCorrect;
  final int correctIndex;
  final String explanation;
  final TriviaDailySession session;
  final QuestProfile profile;
  final List<QuestBadge> newBadges;

  factory TriviaAnswerResult.fromMap(Map<String, Object?> map) =>
      TriviaAnswerResult(
        isCorrect: map['is_correct'] == true || map['is_correct'] == 1,
        correctIndex: (map['correct_index'] as num?)?.toInt() ?? 0,
        explanation: '${map['explanation'] ?? ''}',
        session: TriviaDailySession.fromMap(
          Map<String, Object?>.from(map['session'] as Map? ?? const {}),
        ),
        profile: QuestProfile.fromMap(
          Map<String, Object?>.from(map['profile'] as Map? ?? const {}),
        ),
        newBadges: (map['new_badges'] as List? ?? const [])
            .whereType<Map>()
            .map((item) => QuestBadge.fromMap(Map<String, Object?>.from(item)))
            .toList(),
      );

  Map<String, Object?> toMap() => {
    'is_correct': isCorrect,
    'correct_index': correctIndex,
    'explanation': explanation,
    'session': session.toMap(),
    'profile': profile.toMap(),
    'new_badges': newBadges.map((item) => item.toMap()).toList(),
  };

  TriviaAnswerResult copyWith({
    bool? isCorrect,
    int? correctIndex,
    String? explanation,
    TriviaDailySession? session,
    QuestProfile? profile,
    List<QuestBadge>? newBadges,
  }) => TriviaAnswerResult(
    isCorrect: isCorrect ?? this.isCorrect,
    correctIndex: correctIndex ?? this.correctIndex,
    explanation: explanation ?? this.explanation,
    session: session ?? this.session,
    profile: profile ?? this.profile,
    newBadges: newBadges ?? this.newBadges,
  );
}

class QuestStreakCalculator {
  QuestStreakCalculator._();

  static int nextStreak({
    required String? lastCompletedDate,
    required DateTime completedAt,
    required int currentStreak,
  }) {
    final today = DateTime(
      completedAt.year,
      completedAt.month,
      completedAt.day,
    );
    final last = DateTime.tryParse(lastCompletedDate ?? '');
    if (last == null) return 1;
    final normalizedLast = DateTime(last.year, last.month, last.day);
    final difference = today.difference(normalizedLast).inDays;
    if (difference == 0) return currentStreak;
    if (difference == 1) return currentStreak + 1;
    return 1;
  }
}
