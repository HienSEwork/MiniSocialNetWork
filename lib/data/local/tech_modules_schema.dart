import 'dart:convert';

import 'package:sqflite/sqflite.dart';

class TechModulesSchema {
  TechModulesSchema._();

  static Future<void> create(Database db) async {
    try {
      final batch = db.batch();
      for (final statement in ddl) {
        batch.execute(statement);
      }
      await batch.commit(noResult: true);
    } on DatabaseException {
      rethrow;
    }
  }

  static const ddl = <String>[
    '''
      CREATE TABLE IF NOT EXISTS trivia_questions (
        id TEXT PRIMARY KEY,
        question TEXT NOT NULL,
        options_json TEXT NOT NULL,
        correct_index INTEGER NOT NULL CHECK(correct_index BETWEEN 0 AND 3),
        explanation TEXT NOT NULL,
        category TEXT NOT NULL,
        xp_reward INTEGER NOT NULL DEFAULT 10 CHECK(xp_reward >= 0),
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''',
    '''
      CREATE TABLE IF NOT EXISTS trivia_daily_sessions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        quest_date TEXT NOT NULL,
        score INTEGER NOT NULL DEFAULT 0,
        xp_earned INTEGER NOT NULL DEFAULT 0,
        answered_count INTEGER NOT NULL DEFAULT 0,
        is_completed INTEGER NOT NULL DEFAULT 0,
        completed_at TEXT,
        UNIQUE(user_id, quest_date)
      )
    ''',
    '''
      CREATE TABLE IF NOT EXISTS trivia_daily_questions (
        session_id TEXT NOT NULL REFERENCES trivia_daily_sessions(id) ON DELETE CASCADE,
        question_id TEXT NOT NULL REFERENCES trivia_questions(id),
        position INTEGER NOT NULL CHECK(position BETWEEN 0 AND 2),
        PRIMARY KEY(session_id, question_id),
        UNIQUE(session_id, position)
      )
    ''',
    '''
      CREATE TABLE IF NOT EXISTS trivia_answers (
        session_id TEXT NOT NULL REFERENCES trivia_daily_sessions(id) ON DELETE CASCADE,
        question_id TEXT NOT NULL REFERENCES trivia_questions(id),
        selected_index INTEGER NOT NULL,
        is_correct INTEGER NOT NULL,
        answered_at TEXT NOT NULL,
        PRIMARY KEY(session_id, question_id)
      )
    ''',
    '''
      CREATE TABLE IF NOT EXISTS quest_profiles (
        user_id TEXT PRIMARY KEY,
        xp INTEGER NOT NULL DEFAULT 0,
        current_streak INTEGER NOT NULL DEFAULT 0,
        longest_streak INTEGER NOT NULL DEFAULT 0,
        last_completed_date TEXT
      )
    ''',
    '''
      CREATE TABLE IF NOT EXISTS quest_badges (
        code TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        icon_code INTEGER NOT NULL,
        requirement_type TEXT NOT NULL,
        requirement_value INTEGER NOT NULL
      )
    ''',
    '''
      CREATE TABLE IF NOT EXISTS user_quest_badges (
        user_id TEXT NOT NULL,
        badge_code TEXT NOT NULL REFERENCES quest_badges(code),
        unlocked_at TEXT NOT NULL,
        PRIMARY KEY(user_id, badge_code)
      )
    ''',
    '''
      CREATE TABLE IF NOT EXISTS hardware_components (
        id TEXT PRIMARY KEY,
        component_type TEXT NOT NULL,
        name TEXT NOT NULL,
        brand TEXT NOT NULL,
        socket TEXT,
        power_watt INTEGER NOT NULL DEFAULT 0,
        psu_watt INTEGER NOT NULL DEFAULT 0,
        price REAL NOT NULL CHECK(price >= 0),
        specs_json TEXT NOT NULL DEFAULT '{}',
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''',
    '''
      CREATE TABLE IF NOT EXISTS pc_builds (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        total_cost REAL NOT NULL,
        total_watt INTEGER NOT NULL,
        is_compatible INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''',
    '''
      CREATE TABLE IF NOT EXISTS pc_build_items (
        build_id TEXT NOT NULL REFERENCES pc_builds(id) ON DELETE CASCADE,
        slot TEXT NOT NULL,
        component_id TEXT NOT NULL REFERENCES hardware_components(id),
        PRIMARY KEY(build_id, slot)
      )
    ''',
    '''
      CREATE TABLE IF NOT EXISTS ai_prompt_templates (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        platform TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT NOT NULL,
        template TEXT NOT NULL,
        before_image TEXT,
        after_image TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''',
    '''
      CREATE TABLE IF NOT EXISTS prompt_bookmarks (
        user_id TEXT NOT NULL,
        prompt_id TEXT NOT NULL REFERENCES ai_prompt_templates(id) ON DELETE CASCADE,
        created_at TEXT NOT NULL,
        PRIMARY KEY(user_id, prompt_id)
      )
    ''',
    '''
      CREATE TABLE IF NOT EXISTS gear_products (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        brand TEXT NOT NULL,
        model TEXT NOT NULL,
        msrp REAL NOT NULL CHECK(msrp >= 0),
        annual_depreciation REAL NOT NULL CHECK(annual_depreciation BETWEEN 0 AND 1),
        specs_json TEXT NOT NULL DEFAULT '{}',
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''',
    '''
      CREATE TABLE IF NOT EXISTS gear_closet (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        product_id TEXT NOT NULL REFERENCES gear_products(id),
        purchase_price REAL NOT NULL CHECK(purchase_price >= 0),
        purchase_date TEXT NOT NULL,
        condition_percent REAL NOT NULL CHECK(condition_percent BETWEEN 0 AND 100),
        notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''',
    'CREATE INDEX IF NOT EXISTS idx_trivia_active ON trivia_questions(is_active, category)',
    'CREATE INDEX IF NOT EXISTS idx_hardware_type ON hardware_components(component_type, is_active)',
    'CREATE INDEX IF NOT EXISTS idx_prompts_platform ON ai_prompt_templates(platform, is_active)',
    'CREATE INDEX IF NOT EXISTS idx_gear_search ON gear_products(category, brand, model)',
    'CREATE INDEX IF NOT EXISTS idx_gear_closet_user ON gear_closet(user_id, updated_at DESC)',
  ];

  static Future<void> seed(Database db) async {
    try {
      final batch = db.batch();
      const stamp = '2026-01-01T00:00:00.000Z';
      final questions = <Map<String, Object>>[
        _question(
          'trivia-01',
          'CPU viết tắt của cụm từ nào?',
          [
            'Central Processing Unit',
            'Computer Personal Unit',
            'Core Process Utility',
            'Central Program User',
          ],
          0,
          'CPU là bộ xử lý trung tâm của máy tính.',
          'Phần cứng',
        ),
        _question(
          'trivia-02',
          'Chuẩn Wi-Fi nào hoạt động trên cả băng tần 2.4 GHz và 5 GHz?',
          ['802.11a', '802.11b', '802.11ac', '802.11n'],
          3,
          '802.11n hỗ trợ cả 2.4 GHz và 5 GHz.',
          'Mạng',
        ),
        _question(
          'trivia-03',
          'Mô hình ngôn ngữ lớn thường được viết tắt là gì?',
          ['GPU', 'LLM', 'SSD', 'API'],
          1,
          'LLM là viết tắt của Large Language Model.',
          'AI',
        ),
        _question(
          'trivia-04',
          'Loại bộ nhớ nào mất dữ liệu khi tắt nguồn?',
          ['SSD', 'ROM', 'RAM', 'Flash'],
          2,
          'RAM là bộ nhớ khả biến và cần nguồn điện để giữ dữ liệu.',
          'Phần cứng',
        ),
        _question(
          'trivia-05',
          'HTTPS bảo vệ kết nối web chủ yếu bằng giao thức nào?',
          ['TLS', 'FTP', 'SMTP', 'DHCP'],
          0,
          'HTTPS sử dụng TLS để mã hóa và xác thực kết nối.',
          'Bảo mật',
        ),
        _question(
          'trivia-06',
          'Socket AM5 thuộc hệ sinh thái CPU của hãng nào?',
          ['Intel', 'AMD', 'Apple', 'Qualcomm'],
          1,
          'AM5 là socket desktop hiện đại của AMD.',
          'PC Builder',
        ),
        _question(
          'trivia-07',
          'Trong Git, lệnh nào tạo một bản ghi thay đổi mới?',
          ['git pull', 'git commit', 'git clone', 'git stash'],
          1,
          'git commit ghi lại snapshot thay đổi đã stage.',
          'Lập trình',
        ),
        _question(
          'trivia-08',
          'Đơn vị phổ biến để đo công suất nguồn máy tính là gì?',
          ['Volt', 'Watt', 'Ampere giờ', 'Hertz'],
          1,
          'Công suất PSU được công bố bằng Watt.',
          'PC Builder',
        ),
        _question(
          'trivia-09',
          'Prompt negative trong Stable Diffusion dùng để làm gì?',
          [
            'Tăng độ phân giải',
            'Mô tả yếu tố cần tránh',
            'Chọn GPU',
            'Lưu checkpoint',
          ],
          1,
          'Negative prompt mô tả các đặc điểm không mong muốn trong ảnh.',
          'AI',
        ),
      ];
      for (final row in questions) {
        batch.insert('trivia_questions', {
          ...row,
          'created_at': stamp,
          'updated_at': stamp,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      const badges = [
        (
          'quest-first',
          'Khởi động mạch',
          'Hoàn thành Daily Quest đầu tiên.',
          0xe1d0,
          'completion',
          1,
        ),
        (
          'quest-streak-3',
          'Ba ngày bền bỉ',
          'Duy trì chuỗi Daily Quest 3 ngày.',
          0xe5d5,
          'streak',
          3,
        ),
        (
          'quest-xp-100',
          'Nạp đủ 100 XP',
          'Tích lũy ít nhất 100 XP từ trivia.',
          0xf06c7,
          'xp',
          100,
        ),
        (
          'quest-perfect',
          'Mạch hoàn hảo',
          'Trả lời đúng cả 3 câu trong một ngày.',
          0xe838,
          'perfect',
          3,
        ),
      ];
      for (final badge in badges) {
        batch.insert('quest_badges', {
          'code': badge.$1,
          'name': badge.$2,
          'description': badge.$3,
          'icon_code': badge.$4,
          'requirement_type': badge.$5,
          'requirement_value': badge.$6,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      final components = <Map<String, Object?>>[
        _component(
          'cpu-ryzen-7600',
          'CPU',
          'Ryzen 5 7600',
          'AMD',
          'AM5',
          65,
          0,
          5290000,
          {'cores': '6C/12T', 'boost': '5.1 GHz'},
        ),
        _component(
          'cpu-ryzen-7800x3d',
          'CPU',
          'Ryzen 7 7800X3D',
          'AMD',
          'AM5',
          120,
          0,
          9990000,
          {'cores': '8C/16T', 'cache': '96 MB L3'},
        ),
        _component(
          'cpu-i5-14600k',
          'CPU',
          'Core i5-14600K',
          'Intel',
          'LGA1700',
          181,
          0,
          7890000,
          {'cores': '14C/20T', 'boost': '5.3 GHz'},
        ),
        _component(
          'mb-b650-tomahawk',
          'MAINBOARD',
          'MAG B650 Tomahawk WiFi',
          'MSI',
          'AM5',
          35,
          0,
          5290000,
          {'ram': 'DDR5', 'form': 'ATX'},
        ),
        _component(
          'mb-b650m-aorus',
          'MAINBOARD',
          'B650M Aorus Elite AX',
          'Gigabyte',
          'AM5',
          32,
          0,
          4690000,
          {'ram': 'DDR5', 'form': 'mATX'},
        ),
        _component(
          'mb-z790-p',
          'MAINBOARD',
          'Prime Z790-P WiFi',
          'ASUS',
          'LGA1700',
          40,
          0,
          6190000,
          {'ram': 'DDR5', 'form': 'ATX'},
        ),
        _component(
          'ram-fury-32',
          'RAM',
          'Fury Beast 32GB DDR5-6000',
          'Kingston',
          null,
          8,
          0,
          2990000,
          {'capacity': '32 GB', 'speed': '6000 MT/s'},
        ),
        _component(
          'ram-vengeance-64',
          'RAM',
          'Vengeance 64GB DDR5-6000',
          'Corsair',
          null,
          12,
          0,
          5290000,
          {'capacity': '64 GB', 'speed': '6000 MT/s'},
        ),
        _component(
          'gpu-rtx-4060',
          'GPU',
          'GeForce RTX 4060 Ventus 2X',
          'MSI',
          null,
          115,
          0,
          8290000,
          {'vram': '8 GB GDDR6', 'length': '199 mm'},
        ),
        _component(
          'gpu-rtx-4070s',
          'GPU',
          'GeForce RTX 4070 SUPER Dual',
          'ASUS',
          null,
          220,
          0,
          16990000,
          {'vram': '12 GB GDDR6X', 'length': '267 mm'},
        ),
        _component(
          'gpu-rx-7800xt',
          'GPU',
          'Radeon RX 7800 XT Pulse',
          'Sapphire',
          null,
          263,
          0,
          13990000,
          {'vram': '16 GB GDDR6', 'length': '280 mm'},
        ),
        _component(
          'psu-focus-650',
          'PSU',
          'Focus GX-650 Gold',
          'Seasonic',
          null,
          0,
          650,
          2490000,
          {'rating': '80 Plus Gold', 'modular': 'Full'},
        ),
        _component(
          'psu-rm750e',
          'PSU',
          'RM750e ATX 3.0',
          'Corsair',
          null,
          0,
          750,
          3190000,
          {'rating': '80 Plus Gold', 'modular': 'Full'},
        ),
        _component(
          'psu-mwe-850',
          'PSU',
          'MWE Gold 850 V2',
          'Cooler Master',
          null,
          0,
          850,
          3490000,
          {'rating': '80 Plus Gold', 'modular': 'Full'},
        ),
        _component(
          'case-ap201',
          'CASE',
          'Prime AP201',
          'ASUS',
          null,
          5,
          0,
          1890000,
          {'form': 'mATX', 'gpuMax': '338 mm'},
        ),
        _component(
          'case-h5-flow',
          'CASE',
          'H5 Flow',
          'NZXT',
          null,
          6,
          0,
          2390000,
          {'form': 'ATX', 'gpuMax': '365 mm'},
        ),
        _component(
          'case-lancool-216',
          'CASE',
          'Lancool 216',
          'Lian Li',
          null,
          8,
          0,
          2590000,
          {'form': 'ATX', 'gpuMax': '392 mm'},
        ),
      ];
      for (final row in components) {
        batch.insert('hardware_components', {
          ...row,
          'created_at': stamp,
          'updated_at': stamp,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      final prompts = <Map<String, Object?>>[
        _prompt(
          'prompt-chat-brief',
          'Biến ý tưởng thành product brief',
          'ChatGPT',
          'Sản phẩm',
          'Chuyển một ý tưởng rời rạc thành brief có mục tiêu và tiêu chí nghiệm thu.',
          'Bạn là product strategist. Hãy viết product brief cho {keyword}, hướng đến {audience}, với giọng điệu {tone}. Bao gồm vấn đề, phạm vi, ngoài phạm vi, user stories và 5 tiêu chí nghiệm thu.',
          'assets/images/technet-ai-workflow.png',
          'assets/images/technet-ai-workflow.png',
        ),
        _prompt(
          'prompt-chat-code-review',
          'Code review có hành động',
          'ChatGPT',
          'Lập trình',
          'Tạo checklist review tập trung vào rủi ro thực tế.',
          'Review đoạn mã về {keyword}. Ưu tiên bảo mật, hiệu năng và khả năng bảo trì. Trình bày theo phong cách {style}, giọng {tone}, kèm bản sửa hoàn chỉnh.',
          null,
          null,
        ),
        _prompt(
          'prompt-claude-research',
          'Tổng hợp tài liệu kỹ thuật',
          'Claude',
          'Nghiên cứu',
          'Biến nhiều ghi chú thành bản tổng hợp có lập luận.',
          'Tổng hợp các ghi chú về {keyword} cho {audience}. Phân biệt dữ kiện, giả định và câu hỏi mở; viết theo cấu trúc {style} với giọng {tone}.',
          null,
          null,
        ),
        _prompt(
          'prompt-claude-architecture',
          'Architecture decision record',
          'Claude',
          'Lập trình',
          'Soạn ADR cân bằng trade-off.',
          'Soạn ADR cho quyết định {keyword}. Bối cảnh: {context}. So sánh ít nhất 3 lựa chọn, trade-off, rủi ro và kế hoạch rollback. Giọng điệu {tone}.',
          null,
          null,
        ),
        _prompt(
          'prompt-mj-product',
          'Ảnh sản phẩm cyber studio',
          'Midjourney',
          'Hình ảnh',
          'Prompt ảnh sản phẩm công nghệ có ánh sáng kiểm soát.',
          '{keyword}, premium consumer tech product photography, {style}, controlled rim light, graphite studio, subtle violet reflections, {camera}, no text, no watermark --ar 4:3 --stylize 180',
          'assets/images/technet-pc-gear.png',
          'assets/images/technet-ai-workflow.png',
        ),
        _prompt(
          'prompt-mj-workspace',
          'Góc làm việc tương lai gần',
          'Midjourney',
          'Hình ảnh',
          'Tạo workstation có vật liệu và bố cục cụ thể.',
          'A practical near-future workspace for {audience}, featuring {keyword}, {style}, tactile materials, realistic cable management, morning light, editorial photography --ar 16:9',
          'assets/images/technet-pc-gear.png',
          'assets/images/technet-ai-workflow.png',
        ),
        _prompt(
          'prompt-sd-character',
          'Nhân vật công nghệ nhất quán',
          'Stable Diffusion',
          'Hình ảnh',
          'Prompt nhân vật có kiểm soát phong cách.',
          'portrait of {keyword}, {style}, {lighting}, precise facial details, cohesive color script, high quality; negative: text, watermark, extra fingers, low contrast',
          null,
          null,
        ),
        _prompt(
          'prompt-sd-ui',
          'Concept UI trên thiết bị',
          'Stable Diffusion',
          'Thiết kế',
          'Tạo concept giao diện trong bối cảnh thiết bị thật.',
          'device mockup showing {keyword}, interface style {style}, primary color {color}, clean information hierarchy, realistic screen reflections, product design presentation',
          null,
          null,
        ),
      ];
      for (final row in prompts) {
        batch.insert('ai_prompt_templates', {
          ...row,
          'created_at': stamp,
          'updated_at': stamp,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      final gear = <Map<String, Object>>[
        _gear(
          'gear-mbp-m2',
          'Laptop',
          'Apple',
          'MacBook Pro 14 M2 Pro',
          52990000,
          .16,
          {'cpu': 'M2 Pro', 'ram': '16 GB', 'storage': '512 GB SSD'},
        ),
        _gear(
          'gear-xps-13',
          'Laptop',
          'Dell',
          'XPS 13 Plus 9320',
          45990000,
          .22,
          {'cpu': 'Core i7-1360P', 'ram': '16 GB', 'display': '13.4 inch OLED'},
        ),
        _gear(
          'gear-legion-5',
          'Laptop',
          'Lenovo',
          'Legion 5 Pro 16ARX8',
          41990000,
          .24,
          {
            'cpu': 'Ryzen 7 7745HX',
            'gpu': 'RTX 4060',
            'display': '16 inch 165 Hz',
          },
        ),
        _gear(
          'gear-iphone-15',
          'iPhone',
          'Apple',
          'iPhone 15 128GB',
          22990000,
          .18,
          {
            'display': '6.1 inch OLED',
            'chip': 'A16 Bionic',
            'storage': '128 GB',
          },
        ),
        _gear(
          'gear-iphone-14-pro',
          'iPhone',
          'Apple',
          'iPhone 14 Pro 256GB',
          30990000,
          .19,
          {
            'display': '6.1 inch ProMotion',
            'chip': 'A16 Bionic',
            'storage': '256 GB',
          },
        ),
        _gear(
          'gear-keychron-q1',
          'Keyboard',
          'Keychron',
          'Q1 Pro',
          5290000,
          .14,
          {
            'layout': '75%',
            'case': 'CNC aluminum',
            'connection': 'Bluetooth / USB-C',
          },
        ),
        _gear(
          'gear-lofree-flow',
          'Keyboard',
          'Lofree',
          'Flow 84',
          4490000,
          .16,
          {'layout': '75%', 'switch': 'Kailh POM', 'profile': 'Low profile'},
        ),
        _gear(
          'gear-rtx-4060',
          'GPU',
          'NVIDIA',
          'GeForce RTX 4060 8GB',
          8290000,
          .21,
          {'vram': '8 GB GDDR6', 'tdp': '115 W'},
        ),
        _gear(
          'gear-rtx-4070s',
          'GPU',
          'NVIDIA',
          'GeForce RTX 4070 SUPER 12GB',
          16990000,
          .20,
          {'vram': '12 GB GDDR6X', 'tdp': '220 W'},
        ),
        _gear(
          'gear-rx-7800xt',
          'GPU',
          'AMD',
          'Radeon RX 7800 XT 16GB',
          13990000,
          .23,
          {'vram': '16 GB GDDR6', 'tdp': '263 W'},
        ),
        _gear(
          'gear-mx-master-3s',
          'Mouse',
          'Logitech',
          'MX Master 3S',
          2490000,
          .20,
          {'sensor': '8000 DPI', 'connection': 'Bolt / Bluetooth'},
        ),
        _gear(
          'gear-wh1000xm5',
          'Headphone',
          'Sony',
          'WH-1000XM5',
          8490000,
          .24,
          {'type': 'Over-ear', 'battery': '30 giờ', 'anc': 'Adaptive'},
        ),
      ];
      for (final row in gear) {
        batch.insert('gear_products', {
          ...row,
          'created_at': stamp,
          'updated_at': stamp,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      await batch.commit(noResult: true);
    } on DatabaseException {
      rethrow;
    }
  }

  static Map<String, Object> _question(
    String id,
    String question,
    List<String> options,
    int correct,
    String explanation,
    String category,
  ) => {
    'id': id,
    'question': question,
    'options_json': jsonEncode(options),
    'correct_index': correct,
    'explanation': explanation,
    'category': category,
    'xp_reward': 15,
    'is_active': 1,
  };

  static Map<String, Object?> _component(
    String id,
    String type,
    String name,
    String brand,
    String? socket,
    int power,
    int psu,
    double price,
    Map<String, String> specs,
  ) => {
    'id': id,
    'component_type': type,
    'name': name,
    'brand': brand,
    'socket': socket,
    'power_watt': power,
    'psu_watt': psu,
    'price': price,
    'specs_json': jsonEncode(specs),
    'is_active': 1,
  };

  static Map<String, Object?> _prompt(
    String id,
    String title,
    String platform,
    String category,
    String description,
    String template,
    String? before,
    String? after,
  ) => {
    'id': id,
    'title': title,
    'platform': platform,
    'category': category,
    'description': description,
    'template': template,
    'before_image': before,
    'after_image': after,
    'is_active': 1,
  };

  static Map<String, Object> _gear(
    String id,
    String category,
    String brand,
    String model,
    double msrp,
    double depreciation,
    Map<String, String> specs,
  ) => {
    'id': id,
    'category': category,
    'brand': brand,
    'model': model,
    'msrp': msrp,
    'annual_depreciation': depreciation,
    'specs_json': jsonEncode(specs),
    'is_active': 1,
  };
}
