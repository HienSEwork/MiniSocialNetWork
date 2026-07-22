import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'tech_modules_schema.dart';

class LocalDatabase {
  LocalDatabase._();

  static final LocalDatabase instance = LocalDatabase._();

  Database? _database;

  Future<Database> get database async => _database ??= await openDatabase(
    p.join(await getDatabasesPath(), 'technet.sqlite3'),
    version: 2,
    onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
    onCreate: (db, _) async {
      await _createSchema(db);
      await TechModulesSchema.create(db);
      await _seed(db);
      await TechModulesSchema.seed(db);
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await TechModulesSchema.create(db);
        await TechModulesSchema.seed(db);
      }
    },
    onOpen: TechModulesSchema.seed,
  );

  static String passwordHash(String email, String password) => sha256
      .convert(utf8.encode('${email.trim().toLowerCase()}::$password'))
      .toString();

  static String newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL UNIQUE COLLATE NOCASE,
        password_hash TEXT NOT NULL,
        display_name TEXT NOT NULL,
        avatar_url TEXT,
        bio TEXT,
        role TEXT NOT NULL DEFAULT 'User',
        created_date TEXT NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        reset_token TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE groups (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        avatar_url TEXT,
        owner_id TEXT NOT NULL REFERENCES users(id),
        created_date TEXT NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE group_members (
        group_id TEXT NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
        user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        role INTEGER NOT NULL DEFAULT 2,
        joined_date TEXT NOT NULL,
        PRIMARY KEY (group_id, user_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE posts (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL REFERENCES users(id),
        group_id TEXT REFERENCES groups(id),
        content TEXT NOT NULL DEFAULT '',
        media_url TEXT,
        media_type INTEGER NOT NULL DEFAULT 0,
        created_date TEXT NOT NULL,
        updated_date TEXT,
        is_deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE comments (
        id TEXT PRIMARY KEY,
        post_id TEXT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
        user_id TEXT NOT NULL REFERENCES users(id),
        content TEXT NOT NULL,
        created_date TEXT NOT NULL,
        updated_date TEXT,
        is_deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE reactions (
        id TEXT PRIMARY KEY,
        post_id TEXT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
        user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        type INTEGER NOT NULL,
        created_date TEXT NOT NULL,
        UNIQUE(post_id, user_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        sender_id TEXT NOT NULL REFERENCES users(id),
        receiver_id TEXT REFERENCES users(id),
        group_id TEXT REFERENCES groups(id),
        content TEXT NOT NULL,
        created_date TEXT NOT NULL,
        is_group_message INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        actor_id TEXT REFERENCES users(id),
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        link TEXT,
        is_read INTEGER NOT NULL DEFAULT 0,
        created_date TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE stories (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL REFERENCES users(id),
        content TEXT NOT NULL DEFAULT '',
        media_url TEXT,
        media_type INTEGER NOT NULL DEFAULT 0,
        created_date TEXT NOT NULL,
        updated_date TEXT,
        expires_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE story_reactions (
        story_id TEXT NOT NULL REFERENCES stories(id) ON DELETE CASCADE,
        user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        type INTEGER NOT NULL,
        created_date TEXT NOT NULL,
        PRIMARY KEY(story_id, user_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE portfolios (
        user_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
        title TEXT NOT NULL DEFAULT '',
        bio TEXT NOT NULL DEFAULT '',
        skills TEXT NOT NULL DEFAULT '',
        github_url TEXT,
        website_url TEXT,
        location TEXT,
        featured_project_name TEXT,
        featured_project_url TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE achievement_definitions (
        code TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        icon TEXT NOT NULL,
        sort_order INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE user_achievements (
        user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        code TEXT NOT NULL REFERENCES achievement_definitions(code),
        unlocked_at TEXT NOT NULL,
        PRIMARY KEY(user_id, code)
      )
    ''');
    await db.execute('''
      CREATE TABLE marketplace_items (
        id TEXT PRIMARY KEY,
        seller_id TEXT NOT NULL REFERENCES users(id),
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        price REAL NOT NULL,
        category TEXT NOT NULL,
        item_condition TEXT NOT NULL,
        media_url TEXT,
        status INTEGER NOT NULL DEFAULT 0,
        created_date TEXT NOT NULL,
        updated_date TEXT,
        is_deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE friendships (
        id TEXT PRIMARY KEY,
        requester_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        addressee_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        status TEXT NOT NULL DEFAULT 'pending',
        created_date TEXT NOT NULL,
        UNIQUE(requester_id, addressee_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE jobs (
        id TEXT PRIMARY KEY,
        company TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        location TEXT NOT NULL,
        work_type TEXT NOT NULL,
        level TEXT NOT NULL,
        stack TEXT NOT NULL,
        salary TEXT NOT NULL,
        accent INTEGER NOT NULL,
        posted_date TEXT NOT NULL,
        deadline TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE saved_jobs (
        user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        job_id TEXT NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
        created_date TEXT NOT NULL,
        PRIMARY KEY(user_id, job_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE job_interests (
        user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        job_id TEXT NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
        note TEXT NOT NULL DEFAULT '',
        created_date TEXT NOT NULL,
        PRIMARY KEY(user_id, job_id)
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_posts_created ON posts(created_date DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_messages_private ON messages(sender_id, receiver_id)',
    );
    await db.execute(
      'CREATE INDEX idx_jobs_active ON jobs(is_active, posted_date DESC)',
    );
  }

  Future<void> _seed(Database db) async {
    final batch = db.batch();
    final now = DateTime.now().toUtc();
    const password = 'Password123!';
    final users =
        <({String id, String email, String name, String bio, String role})>[
          (
            id: 'admin-001',
            email: 'admin@minisocial.local',
            name: 'Admin Demo',
            bio: 'System owner & community curator.',
            role: 'Admin',
          ),
          (
            id: 'alice-001',
            email: 'alice@minisocial.local',
            name: 'Alice',
            bio: 'Frontend-minded social user.',
            role: 'User',
          ),
          (
            id: 'bob-001',
            email: 'bob@minisocial.local',
            name: 'Bob',
            bio: 'Backend-focused community member.',
            role: 'User',
          ),
          for (var i = 0; i < _demoNames.length; i++)
            (
              id: 'demo-${(i + 1).toString().padLeft(2, '0')}',
              email:
                  'demo${(i + 1).toString().padLeft(2, '0')}@minisocial.local',
              name: _demoNames[i],
              bio: _demoBios[i % _demoBios.length],
              role: 'User',
            ),
        ];
    for (var i = 0; i < users.length; i++) {
      final user = users[i];
      batch.insert('users', {
        'id': user.id,
        'email': user.email,
        'password_hash': passwordHash(user.email, password),
        'display_name': user.name,
        'avatar_url': null,
        'bio': user.bio,
        'role': user.role,
        'created_date': now.subtract(Duration(days: 50 - i)).toIso8601String(),
      });
    }
    await batch.commit(noResult: true);

    final contentBatch = db.batch();
    final groupSeeds = <({String name, String description, String asset})>[
      (
        name: 'Engineering Circle',
        description: 'Technical planning, architecture and team updates.',
        asset: 'assets/images/group_dotnet_backend.png',
      ),
      (
        name: 'Product Lab',
        description: 'Backlog discussion and feature experiments.',
        asset: 'assets/images/group_productivity.png',
      ),
      for (var i = 0; i < _groupNames.length; i++)
        (
          name: _groupNames[i],
          description: _groupDescriptions[i],
          asset: _groupAssets[i],
        ),
    ];
    for (var i = 0; i < groupSeeds.length; i++) {
      final id = 'group-${(i + 1).toString().padLeft(2, '0')}';
      final owner = i < 2
          ? (i == 0 ? 'admin-001' : 'alice-001')
          : 'demo-${((i - 2) % 30 + 1).toString().padLeft(2, '0')}';
      contentBatch.insert('groups', {
        'id': id,
        'name': groupSeeds[i].name,
        'description': groupSeeds[i].description,
        'avatar_url': groupSeeds[i].asset,
        'owner_id': owner,
        'created_date': now.subtract(Duration(days: 34 - i)).toIso8601String(),
      });
      contentBatch.insert('group_members', {
        'group_id': id,
        'user_id': owner,
        'role': 0,
        'joined_date': now.subtract(Duration(days: 34 - i)).toIso8601String(),
      });
      for (var memberOffset = 1; memberOffset <= 5; memberOffset++) {
        final member =
            'demo-${((i * 3 + memberOffset) % 30 + 1).toString().padLeft(2, '0')}';
        if (member == owner) continue;
        contentBatch.insert('group_members', {
          'group_id': id,
          'user_id': member,
          'role': 2,
          'joined_date': now
              .subtract(Duration(days: 20 - memberOffset))
              .toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }

    for (var i = 0; i < 60; i++) {
      final id = 'post-${(i + 1).toString().padLeft(3, '0')}';
      final userId = i < 3
          ? ['admin-001', 'alice-001', 'bob-001'][i]
          : 'demo-${((i - 3) % 30 + 1).toString().padLeft(2, '0')}';
      final groupId = i % 4 == 0
          ? 'group-${(i % 22 + 1).toString().padLeft(2, '0')}'
          : null;
      contentBatch.insert('posts', {
        'id': id,
        'user_id': userId,
        'group_id': groupId,
        'content': _postBodies[i % _postBodies.length],
        'media_url': i == 8
            ? 'assets/images/technet-ai-workflow.png'
            : i == 19
            ? 'assets/images/technet-pc-gear.png'
            : null,
        'media_type': i == 8 || i == 19 ? 1 : 0,
        'created_date': now
            .subtract(Duration(hours: 2 + i * 5))
            .toIso8601String(),
      });
      for (var c = 0; c < 2; c++) {
        contentBatch.insert('comments', {
          'id': 'comment-$i-$c',
          'post_id': id,
          'user_id':
              'demo-${((i + c + 6) % 30 + 1).toString().padLeft(2, '0')}',
          'content': _commentBodies[(i + c) % _commentBodies.length],
          'created_date': now
              .subtract(Duration(hours: 1 + i * 5 - c))
              .toIso8601String(),
        });
      }
      for (var r = 0; r < 3; r++) {
        contentBatch.insert('reactions', {
          'id': 'reaction-$i-$r',
          'post_id': id,
          'user_id':
              'demo-${((i + r + 11) % 30 + 1).toString().padLeft(2, '0')}',
          'type': (i + r) % 3,
          'created_date': now
              .subtract(Duration(hours: i * 5))
              .toIso8601String(),
        });
      }
    }

    for (var i = 0; i < 16; i++) {
      contentBatch.insert('stories', {
        'id': 'story-${(i + 1).toString().padLeft(2, '0')}',
        'user_id': 'demo-${(i + 1).toString().padLeft(2, '0')}',
        'content': _storyBodies[i],
        'media_url': i == 0 ? 'assets/images/technet-pc-gear.png' : null,
        'media_type': i == 0 ? 1 : 0,
        'created_date': now
            .subtract(Duration(minutes: 35 * i))
            .toIso8601String(),
        'expires_at': now
            .add(Duration(hours: 24, minutes: -35 * i))
            .toIso8601String(),
      });
    }

    for (var i = 0; i < 30; i++) {
      final userId = 'demo-${(i + 1).toString().padLeft(2, '0')}';
      contentBatch.insert('portfolios', {
        'user_id': userId,
        'title': _portfolioTitles[i % _portfolioTitles.length],
        'bio': _portfolioBios[i % _portfolioBios.length],
        'skills': _portfolioSkills[i % _portfolioSkills.length],
        'github_url':
            'https://github.com/demo${(i + 1).toString().padLeft(2, '0')}',
        'website_url': 'https://example.dev/demo${i + 1}',
        'location': i.isEven ? 'TP. Hồ Chí Minh' : 'Hà Nội',
        'featured_project_name':
            _portfolioProjects[i % _portfolioProjects.length],
        'featured_project_url': 'https://example.dev/projects/${i + 1}',
      });
    }

    for (var i = 0; i < _marketplaceTitles.length; i++) {
      contentBatch.insert('marketplace_items', {
        'id': 'market-${(i + 1).toString().padLeft(2, '0')}',
        'seller_id': 'demo-${((i * 2) % 30 + 1).toString().padLeft(2, '0')}',
        'title': _marketplaceTitles[i],
        'description':
            'Đồ công nghệ đã kiểm tra, phù hợp học tập và làm việc. Ưu tiên giao dịch trong cộng đồng.',
        'price': _marketplacePrices[i],
        'category': _marketplaceCategories[i],
        'item_condition': i % 3 == 0 ? 'Như mới' : 'Đã sử dụng tốt',
        'status': i % 5 == 0 ? 1 : 0,
        'created_date': now.subtract(Duration(days: i + 1)).toIso8601String(),
      });
    }
    await contentBatch.commit(noResult: true);

    await _seedSocialAndAchievements(db, now);
    await _seedJobs(db, now);
  }

  Future<void> _seedSocialAndAchievements(Database db, DateTime now) async {
    final batch = db.batch();
    for (var i = 0; i < 12; i++) {
      final a = 'demo-${(i + 1).toString().padLeft(2, '0')}';
      final b = 'demo-${(i + 2).toString().padLeft(2, '0')}';
      batch.insert('friendships', {
        'id': 'friend-${i + 1}',
        'requester_id': a,
        'addressee_id': b,
        'status': i < 9 ? 'accepted' : 'pending',
        'created_date': now.subtract(Duration(days: i + 2)).toIso8601String(),
      });
    }
    batch.insert('friendships', {
      'id': 'friend-request-demo01-a',
      'requester_id': 'demo-18',
      'addressee_id': 'demo-01',
      'status': 'pending',
      'created_date': now.subtract(const Duration(hours: 9)).toIso8601String(),
    });
    batch.insert('friendships', {
      'id': 'friend-request-demo01-b',
      'requester_id': 'demo-23',
      'addressee_id': 'demo-01',
      'status': 'pending',
      'created_date': now.subtract(const Duration(days: 1)).toIso8601String(),
    });
    for (var i = 0; i < 5; i++) {
      batch.insert('notifications', {
        'id': 'notification-seed-${i + 1}',
        'user_id': 'demo-01',
        'actor_id': 'demo-${(i + 2).toString().padLeft(2, '0')}',
        'type': i.isEven ? 'reaction' : 'comment',
        'title': i.isEven ? 'Bài viết có cảm xúc mới' : 'Có bình luận mới',
        'message': i.isEven
            ? 'Một thành viên vừa thả cảm xúc cho bài viết của bạn.'
            : 'Cuộc trò chuyện dưới bài viết của bạn vừa có cập nhật.',
        'link': '/posts/post-${(i + 1).toString().padLeft(3, '0')}',
        'is_read': i > 2 ? 1 : 0,
        'created_date': now
            .subtract(Duration(hours: i * 4 + 1))
            .toIso8601String(),
      });
    }
    for (var i = 0; i < 24; i++) {
      final isGroup = i % 3 == 0;
      batch.insert('messages', {
        'id': 'message-${i + 1}',
        'sender_id': 'demo-${(i % 10 + 1).toString().padLeft(2, '0')}',
        'receiver_id': isGroup
            ? null
            : 'demo-${((i + 1) % 10 + 1).toString().padLeft(2, '0')}',
        'group_id': isGroup
            ? 'group-${(i % 6 + 1).toString().padLeft(2, '0')}'
            : null,
        'content': _chatBodies[i % _chatBodies.length],
        'created_date': now.subtract(Duration(hours: 26 - i)).toIso8601String(),
        'is_group_message': isGroup ? 1 : 0,
      });
    }
    const achievements = [
      (
        'first-post',
        'Bài viết đầu tiên',
        'Đăng bài đầu tiên trong cộng đồng.',
        'edit_note',
      ),
      (
        'first-story',
        'Story đầu tiên',
        'Chia sẻ story đầu tiên trên TechNet.',
        'auto_awesome',
      ),
      (
        'joined-group',
        'Thành viên cộng đồng',
        'Tham gia ít nhất một nhóm.',
        'groups',
      ),
      (
        'portfolio-ready',
        'Portfolio sẵn sàng',
        'Hoàn thiện kỹ năng hoặc dự án nổi bật.',
        'workspaces',
      ),
      (
        'got-reaction',
        'Được quan tâm',
        'Bài viết của bạn đã nhận reaction.',
        'favorite',
      ),
    ];
    for (var i = 0; i < achievements.length; i++) {
      final a = achievements[i];
      batch.insert('achievement_definitions', {
        'code': a.$1,
        'name': a.$2,
        'description': a.$3,
        'icon': a.$4,
        'sort_order': i + 1,
      });
      for (var u = 1; u <= 15; u++) {
        if ((u + i) % 3 == 0) continue;
        batch.insert('user_achievements', {
          'user_id': 'demo-${u.toString().padLeft(2, '0')}',
          'code': a.$1,
          'unlocked_at': now.subtract(Duration(days: u + i)).toIso8601String(),
        });
      }
    }
    await batch.commit(noResult: true);
  }

  Future<void> _seedJobs(Database db, DateTime now) async {
    final batch = db.batch();
    for (var i = 0; i < _jobSeeds.length; i++) {
      final job = _jobSeeds[i];
      batch.insert('jobs', {
        'id': 'job-${(i + 1).toString().padLeft(2, '0')}',
        'company': job.$1,
        'title': job.$2,
        'description': job.$3,
        'location': job.$4,
        'work_type': job.$5,
        'level': job.$6,
        'stack': job.$7,
        'salary': job.$8,
        'accent': i % 4,
        'posted_date': now.subtract(Duration(days: i ~/ 2)).toIso8601String(),
        'deadline': now.add(Duration(days: 18 + i)).toIso8601String(),
      });
    }
    await batch.commit(noResult: true);
  }
}

const _demoNames = [
  'Nguyễn Minh Anh',
  'Trần Quốc Bảo',
  'Lê Hoàng Chi',
  'Phạm Gia Duy',
  'Vũ Thu Hà',
  'Đỗ Minh Khang',
  'Bùi Ngọc Lan',
  'Hoàng Tuấn Long',
  'Đặng Mai Linh',
  'Ngô Đức Mạnh',
  'Dương Nhật Nam',
  'Lý Bảo Ngân',
  'Đinh Quang Phúc',
  'Trịnh Hải Quân',
  'Cao Minh Thư',
  'Mai Anh Tú',
  'Tạ Khánh Vy',
  'Chu Thành Vinh',
  'Hồ Gia Hân',
  'Võ Trung Kiên',
  'Lâm Yến Nhi',
  'Quách Đình Phong',
  'Phan Thanh Tâm',
  'Nông Bảo Trâm',
  'Kiều Anh Tuấn',
  'Tống Minh Uyên',
  'Thái Quốc Việt',
  'La Hoài An',
  'Hà Đức Bình',
  'Đoàn Kim Chi',
];

const _demoBios = [
  'Flutter developer, mê những tương tác nhỏ nhưng hữu ích.',
  '.NET backend engineer, thích hệ thống rõ ràng và dễ vận hành.',
  'Đang học AI workflow, RAG và cách đưa thử nghiệm thành sản phẩm.',
  'Data analyst quan tâm dashboard, SQL và câu chuyện phía sau số liệu.',
  'Sinh viên IT, thích build project end-to-end cùng cộng đồng.',
];

const _groupNames = [
  'AI Lab Việt',
  'Flutter Mobile',
  '.NET Backend',
  'PC & Workstation',
  'GPU Gaming',
  'Laptop Creator',
  'Tech News',
  'Machine Learning',
  'Cybersecurity',
  'DevOps & Cloud',
  'Data Analyst',
  'Game Dev',
  'IoT Makers',
  'Open Source',
  'Gear & Setup',
  'Prompt Engineering',
  'Web Performance',
  'Productivity',
  'Startup AI',
  'Sinh viên IT',
];

const _groupDescriptions = [
  'Thử nghiệm AI có trách nhiệm, chia sẻ paper và workflow.',
  'Flutter, Dart, UI mobile và kinh nghiệm phát hành ứng dụng.',
  'ASP.NET Core, kiến trúc, database và vận hành backend.',
  'Cấu hình máy cho dev, creator và AI local.',
  'GPU, hiệu năng game và tối ưu phần cứng.',
  'Laptop cho designer, video editor và lập trình viên.',
  'Tin công nghệ được tóm tắt và thảo luận có nguồn.',
  'ML thực chiến, dataset, đánh giá model và MLOps.',
  'Bảo mật cá nhân, ứng dụng và hạ tầng.',
  'Docker, CI/CD, cloud cost và observability.',
  'SQL, BI, dashboard và data storytelling.',
  'Thiết kế game, engine và phát hành indie.',
  'Phần cứng nhỏ, cảm biến và dự án IoT.',
  'Cùng đọc code, đóng góp và duy trì dự án mở.',
  'Góc làm việc, bàn phím, chuột và âm thanh.',
  'Prompt rõ ràng, eval và AI workflow đáng tin cậy.',
  'Core Web Vitals và trải nghiệm web nhanh.',
  'Công cụ và thói quen làm việc bền vững.',
  'Sản phẩm AI, go-to-market và bài học startup.',
  'Học tập, thực tập và project đầu tay ngành IT.',
];

const _groupAssets = [
  'assets/images/group_ai_lab.png',
  'assets/images/group_flutter_mobile.png',
  'assets/images/group_dotnet_backend.png',
  'assets/images/group_pc_workstation.png',
  'assets/images/group_gpu_gaming.png',
  'assets/images/group_laptop_creator.png',
  'assets/images/group_tech_news.png',
  'assets/images/group_machine_learning.png',
  'assets/images/group_cybersecurity.png',
  'assets/images/group_devops_cloud.png',
  'assets/images/group_data_analyst.png',
  'assets/images/group_game_dev.png',
  'assets/images/group_iot.png',
  'assets/images/group_open_source.png',
  'assets/images/group_gear_setup.png',
  'assets/images/group_prompt_engineering.png',
  'assets/images/group_web_performance.png',
  'assets/images/group_productivity.png',
  'assets/images/group_startup_ai.png',
  'assets/images/group_students_it.png',
];

const _postBodies = [
  'Mình vừa hoàn thiện một flow onboarding Flutter gọn hơn. Bỏ bớt ba màn giải thích nhưng tỷ lệ hoàn thành lại tăng rõ.',
  'Checklist review API hôm nay: validation, auth, pagination, log có cấu trúc và test cho các nhánh lỗi.',
  'AI agent rất hợp cho tác vụ lặp lại, nhưng những hành động quan trọng vẫn nên có bước xác nhận rõ ràng.',
  'Sau khi resize ảnh trước khi lưu, feed cuộn mượt hơn hẳn trên máy tầm trung.',
  'Có ai đang dùng bàn phím low-profile để code cả ngày không? Mình muốn nghe trải nghiệm sau vài tháng.',
  'Một project nhỏ end-to-end dạy mình nhiều hơn: auth, database, upload, feed, chat và đóng gói app.',
  'Structured logging cứu team mình một buổi debug. Tên event nhất quán thật sự đáng đầu tư.',
  'Mình đang so GPU cũ nhiều VRAM với GPU mới tiết kiệm điện cho một mini AI lab.',
  'Hôm nay đọc lại backlog và biến từng dòng thành tiêu chí kiểm thử, đỡ sót hơn rất nhiều.',
  'Dark mode tốt không chỉ là đảo màu. Contrast, elevation và ảnh minh họa đều cần được xem lại.',
];

const _commentBodies = [
  'Cảm ơn đã chia sẻ, đúng thứ mình đang tìm.',
  'Nếu có checklist ngắn thì người mới sẽ dễ áp dụng hơn.',
  'Mình cũng gặp tình huống tương tự và thấy cách này khá hiệu quả.',
  'Ý hay, nhưng nhớ đo lại chi phí vận hành lâu dài nhé.',
  'Có benchmark thực tế thì càng dễ so sánh.',
  'Đã lưu lại để thử trong project cuối tuần này.',
];

const _storyBodies = [
  'Setup sáng nay: màn phụ dọc để đọc log.',
  'Vừa test prompt mới cho workflow AI.',
  'Checklist hôm nay: backup, update package, review security.',
  'Góc làm việc gọn hơn sau khi đổi dock USB-C.',
  'Flutter hot reload vẫn là niềm vui nhỏ mỗi ngày.',
  'Resize ảnh trước khi đưa lên feed nhé.',
  'Đọc tin GPU mới, VRAM vẫn đáng cân nhắc nhất.',
  'Đang gom tài liệu clean architecture cho nhóm.',
  'Team thử dùng AI để tạo test case edge.',
  'Có ai dùng NPU trên laptop mới chưa?',
  'Một buổi tối debug SQLite và index.',
  'Story từ demo account, chào mọi người!',
  'Bàn phím low-profile giúp cổ tay đỡ mỏi.',
  'Đọc paper RAG: chunking quan trọng thật.',
  'Tối nay học thêm về accessibility.',
  'Mini lab Docker đã chạy ổn.',
];

const _chatBodies = [
  'Bạn gửi mình cấu hình PC hôm qua được không?',
  'Chiều nay mình test prompt tóm tắt rồi gửi kết quả nhé.',
  'Nhớ bật seed data để bản demo nhìn có sức sống hơn.',
  'Bài viết nên có comment và reaction sẵn.',
  'Mai mình thử local model với bộ tài liệu nhỏ.',
  'Mình vừa đẩy bản sửa UI, bạn xem giúp contrast nhé.',
];

const _portfolioTitles = [
  'Flutter Developer',
  '.NET Backend Engineer',
  'AI Product Builder',
  'Data Analyst',
  'Cloud DevOps Learner',
];
const _portfolioBios = [
  'Xây ứng dụng mobile nhanh, gọn và có trải nghiệm tốt.',
  'Tập trung API, auth, database và hệ thống dễ mở rộng.',
  'Thử nghiệm AI workflow và trợ lý cho sản phẩm thực tế.',
  'Biến dữ liệu thành insight rõ ràng, có thể hành động.',
  'Học Docker, CI/CD, cloud cost và quan sát hệ thống.',
];
const _portfolioSkills = [
  'Flutter, Dart, Provider, SQLite',
  'ASP.NET Core, EF Core, SQL, JWT',
  'Python, LLM, RAG, Prompt Engineering',
  'SQL, Power BI, Excel, Data Modeling',
  'Docker, GitHub Actions, Azure, Linux',
];
const _portfolioProjects = [
  'TechNet mobile social feed',
  'Realtime group chat',
  'AI document assistant',
  'Laptop price dashboard',
  'DevOps deployment template',
];

const _marketplaceTitles = [
  'Laptop ThinkPad T14 Gen 3',
  'Màn hình Dell 27 inch 2K',
  'Bàn phím cơ Keychron K3',
  'Chuột Logitech MX Master',
  'SSD NVMe Samsung 1TB',
  'RAM DDR4 32GB kit',
  'Dock USB-C đa cổng',
  'Tai nghe Sony WH-1000XM',
  'GPU RTX 3060 12GB',
  'Mini PC Intel NUC',
  'Webcam Logitech C920',
  'Router Wi-Fi 6 Asus',
];
const _marketplacePrices = [
  12500000,
  4200000,
  1850000,
  1650000,
  2100000,
  1900000,
  950000,
  3900000,
  5200000,
  6800000,
  1200000,
  2400000,
];
const _marketplaceCategories = [
  'Laptop',
  'Màn hình',
  'Gear',
  'Gear',
  'Linh kiện',
  'Linh kiện',
  'Phụ kiện',
  'Audio',
  'Linh kiện',
  'PC',
  'Phụ kiện',
  'Network',
];

const _jobSeeds = [
  (
    'Pixel Harbor',
    'Flutter Intern',
    'Cùng xây design system và trải nghiệm mobile cho sản phẩm giáo dục.',
    'TP. Hồ Chí Minh',
    'Hybrid',
    'Intern',
    'Flutter, Dart, Git',
    '5–8 triệu',
  ),
  (
    'Northstar Labs',
    'Junior .NET Developer',
    'Phát triển module nghiệp vụ, viết test và tối ưu truy vấn SQLite/SQL.',
    'Hà Nội',
    'On-site',
    'Junior',
    '.NET, C#, SQL',
    '12–18 triệu',
  ),
  (
    'Lumen AI',
    'AI Product Engineer',
    'Đưa prototype LLM vào workflow có eval, logging và lớp kiểm soát.',
    'Remote',
    'Remote',
    'Middle',
    'Python, LLM, RAG',
    '25–38 triệu',
  ),
  (
    'Cloudweave',
    'DevOps Trainee',
    'Hỗ trợ pipeline CI/CD, container và dashboard quan sát hệ thống.',
    'Đà Nẵng',
    'Hybrid',
    'Trainee',
    'Docker, Linux, CI/CD',
    '7–10 triệu',
  ),
  (
    'Metric Garden',
    'Data Analyst Intern',
    'Làm sạch dữ liệu, xây dashboard và trình bày insight cho product team.',
    'TP. Hồ Chí Minh',
    'On-site',
    'Intern',
    'SQL, Power BI, Excel',
    '6–9 triệu',
  ),
  (
    'Open Canvas',
    'Frontend Developer',
    'Xây giao diện web hiệu năng tốt, accessibility và component library.',
    'Remote',
    'Remote',
    'Junior',
    'TypeScript, React, CSS',
    '15–23 triệu',
  ),
  (
    'Tinker Works',
    'IoT Mobile Engineer',
    'Kết nối BLE device với ứng dụng Flutter và thiết kế luồng setup.',
    'Hà Nội',
    'Hybrid',
    'Middle',
    'Flutter, BLE, IoT',
    '22–32 triệu',
  ),
  (
    'Shieldbox',
    'Cybersecurity Intern',
    'Hỗ trợ kiểm thử bảo mật ứng dụng và viết hướng dẫn khắc phục.',
    'TP. Hồ Chí Minh',
    'Hybrid',
    'Intern',
    'OWASP, Linux, Networking',
    '7–11 triệu',
  ),
];
