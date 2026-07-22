# TechNet Mobile — 4 Tech Lab Modules

Tài liệu này mô tả phần triển khai thực tế của bốn module độc lập chạy hoàn toàn trên Flutter + SQLite. Không module nào gọi API backend.

## Phase 1 — Kiến trúc và luồng trạng thái

Kiến trúc của mỗi module đi theo một chiều:

```text
Screen / Widget
      ↓ thao tác người dùng
ChangeNotifier Provider
      ↓ nghiệp vụ + trạng thái
SQLite Repository
      ↓ truy vấn có try/catch
LocalDatabase (sqflite, schema v2)
```

`AuthProvider` cung cấp `UserSession` cho bốn `ChangeNotifierProxyProvider`. Khi tài khoản thay đổi, provider tự xóa dữ liệu của phiên cũ và tải dữ liệu thuộc đúng `user_id`. Trạng thái dùng chung gồm `initial`, `loading`, `success`, `error`; màn hình ánh xạ lần lượt sang nội dung ban đầu, `LoadingIndicator`, dữ liệu, hoặc `ErrorStateWidget` có nút **Thử lại**.

### Danh sách file

File tạo mới:

- `lib/data/local/tech_modules_schema.dart`
- `lib/data/models/trivia_models.dart`
- `lib/data/models/hardware_models.dart`
- `lib/data/models/ai_prompt_models.dart`
- `lib/data/models/gear_price_models.dart`
- `lib/data/providers/module_state.dart`
- `lib/data/providers/trivia_provider.dart`
- `lib/data/providers/pc_builder_provider.dart`
- `lib/data/providers/ai_library_provider.dart`
- `lib/data/providers/gear_price_provider.dart`
- `lib/data/repositories/trivia_repository.dart`
- `lib/data/repositories/hardware_repository.dart`
- `lib/data/repositories/ai_prompt_repository.dart`
- `lib/data/repositories/gear_price_repository.dart`
- `lib/ui/widgets/module_states.dart`
- `lib/ui/widgets/tech_lab_widgets.dart`
- `lib/ui/screens/daily_quest_screen.dart`
- `lib/ui/screens/pc_builder_screen.dart`
- `lib/ui/screens/ai_library_screen.dart`
- `lib/ui/screens/gear_price_screen.dart`
- `lib/ui/screens/tech_modules_admin_screen.dart`
- `test/tech_modules_logic_test.dart`
- `test/tech_modules_widget_test.dart`

File tích hợp được sửa:

- `lib/data/local/local_database.dart`: schema v2, migration và seed.
- `lib/main.dart`: đăng ký bốn Provider theo phiên đăng nhập.
- `lib/core/router.dart`: năm route người dùng/quản trị.
- `lib/ui/screens/home_screen.dart`: Daily Quest banner và Tech Lab launcher.
- `lib/ui/screens/admin_screen.dart`: lối vào quản trị bốn module.

## Phase 2 — SQLite schema, migration và seed

Đây là DDL chính xác đang được thực thi bởi `TechModulesSchema.ddl`:

```sql
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
);

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
);

CREATE TABLE IF NOT EXISTS trivia_daily_questions (
  session_id TEXT NOT NULL REFERENCES trivia_daily_sessions(id) ON DELETE CASCADE,
  question_id TEXT NOT NULL REFERENCES trivia_questions(id),
  position INTEGER NOT NULL CHECK(position BETWEEN 0 AND 2),
  PRIMARY KEY(session_id, question_id),
  UNIQUE(session_id, position)
);

CREATE TABLE IF NOT EXISTS trivia_answers (
  session_id TEXT NOT NULL REFERENCES trivia_daily_sessions(id) ON DELETE CASCADE,
  question_id TEXT NOT NULL REFERENCES trivia_questions(id),
  selected_index INTEGER NOT NULL,
  is_correct INTEGER NOT NULL,
  answered_at TEXT NOT NULL,
  PRIMARY KEY(session_id, question_id)
);

CREATE TABLE IF NOT EXISTS quest_profiles (
  user_id TEXT PRIMARY KEY,
  xp INTEGER NOT NULL DEFAULT 0,
  current_streak INTEGER NOT NULL DEFAULT 0,
  longest_streak INTEGER NOT NULL DEFAULT 0,
  last_completed_date TEXT
);

CREATE TABLE IF NOT EXISTS quest_badges (
  code TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  icon_code INTEGER NOT NULL,
  requirement_type TEXT NOT NULL,
  requirement_value INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS user_quest_badges (
  user_id TEXT NOT NULL,
  badge_code TEXT NOT NULL REFERENCES quest_badges(code),
  unlocked_at TEXT NOT NULL,
  PRIMARY KEY(user_id, badge_code)
);

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
);

CREATE TABLE IF NOT EXISTS pc_builds (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  name TEXT NOT NULL,
  total_cost REAL NOT NULL,
  total_watt INTEGER NOT NULL,
  is_compatible INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS pc_build_items (
  build_id TEXT NOT NULL REFERENCES pc_builds(id) ON DELETE CASCADE,
  slot TEXT NOT NULL,
  component_id TEXT NOT NULL REFERENCES hardware_components(id),
  PRIMARY KEY(build_id, slot)
);

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
);

CREATE TABLE IF NOT EXISTS prompt_bookmarks (
  user_id TEXT NOT NULL,
  prompt_id TEXT NOT NULL REFERENCES ai_prompt_templates(id) ON DELETE CASCADE,
  created_at TEXT NOT NULL,
  PRIMARY KEY(user_id, prompt_id)
);

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
);

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
);

CREATE INDEX IF NOT EXISTS idx_trivia_active
  ON trivia_questions(is_active, category);
CREATE INDEX IF NOT EXISTS idx_hardware_type
  ON hardware_components(component_type, is_active);
CREATE INDEX IF NOT EXISTS idx_prompts_platform
  ON ai_prompt_templates(platform, is_active);
CREATE INDEX IF NOT EXISTS idx_gear_search
  ON gear_products(category, brand, model);
CREATE INDEX IF NOT EXISTS idx_gear_closet_user
  ON gear_closet(user_id, updated_at DESC);
```

Database hiện ở version `2`. `onCreate` tạo schema/seed cũ trước rồi mới tạo/seed Tech Lab. `onUpgrade` chạy `TechModulesSchema.create` và `TechModulesSchema.seed` khi `oldVersion < 2`. `onOpen` gọi lại seed an toàn để tự phục hồi các bản ghi seed bị thiếu.

Mọi seed đều dùng khóa cố định và `ConflictAlgorithm.ignore`, tương đương `INSERT OR IGNORE`: 9 câu trivia, 4 huy hiệu, 17 linh kiện, 8 prompt và 12 sản phẩm. Vì khóa chính không đổi nên đóng/mở hay nâng cấp app không nhân đôi dữ liệu. Dữ liệu seed của hệ thống cũ vẫn được giữ nguyên.

## Phase 3 — Chức năng hoàn chỉnh

### Daily Quest & Tech Trivia

- Chọn ổn định ba câu mỗi ngày theo ngày và người dùng.
- Mỗi câu chỉ trả lời một lần; tính điểm, XP và tiến độ ngay trong transaction.
- Hoàn thành ngày cập nhật streak, longest streak và huy hiệu.
- Huy hiệu hỗ trợ điều kiện lần đầu, streak, tổng XP và perfect score.
- Admin tạo, đọc, sửa, xóa/ngưng kích hoạt câu hỏi.

### PC Builder

- Sáu slot bắt buộc: CPU, Mainboard, RAM, GPU, PSU, Case.
- Socket hợp lệ khi `CPU.socket == Mainboard.socket`.
- Nguồn hợp lệ khi `totalComponentWatt * 1.25 <= PSU.psuWatt`.
- Tổng giá và công suất cập nhật tức thời.
- Lưu, mở lại, xóa build; xuất card PNG qua `RepaintBoundary`.
- Admin CRUD thông số, socket, watt, công suất PSU, giá và specs.

### AI Prompts & Tools Library

- Lọc theo ChatGPT, Midjourney, Claude, Stable Diffusion và tìm kiếm.
- Tách biến dạng `{variable}` trực tiếp từ template và sinh form tương ứng.
- Preview prompt hoàn chỉnh, ảnh trước/sau, bookmark theo tài khoản.
- Sao chép clipboard có xử lý lỗi và phản hồi Snackbar.
- Admin CRUD nội dung, nền tảng, category, template và đường dẫn ảnh.

### Second-hand Gear Price Checker

- Tìm theo category, brand, model; xem quick specs.
- Giá trị cơ sở giảm theo tuổi và `annual_depreciation`, sau đó nhân hệ số tình trạng.
- Khoảng bán đề xuất là 92%–105%; khoảng mua là 85%–96% của giá trị ước tính.
- Slider 45%–99%, ngày mua, giá mua, ghi chú và My Gear Closet theo tài khoản.
- Admin CRUD MSRP, tỷ lệ khấu hao và thông số sản phẩm.

Tất cả model có `fromMap`, `toMap`, `copyWith`. Các thao tác CRUD nằm trong repository riêng; provider chỉ giữ UI state, filter, lựa chọn và gọi nghiệp vụ.

## Phase 4 — UI và theme

Các module dùng ngôn ngữ hình ảnh **Tech Lab**: card bo góc có nhịp điệu, màu tín hiệu riêng cho từng công cụ, typography và surface lấy từ `ThemeData`. Không hard-code nền sáng cho nội dung chính nên Light/Dark Mode dùng cùng cấu trúc. `LayoutBuilder`, `Wrap`, `Expanded`, `SliverGridDelegateWithMaxCrossAxisExtent` và giới hạn chiều rộng được dùng để tránh overflow trên điện thoại nhỏ và mở rộng hợp lý trên tablet.

Route đã đăng ký:

- `/daily-quest`
- `/pc-builder`
- `/ai-library`
- `/gear-price`
- `/admin/tech-modules`

Mọi màn hình độc lập có nút back rõ ràng; modal có nút đóng hoặc hành động hủy.

## Phase 5 — Chống lỗi và phục hồi

- Query, transaction, migration và seed đều có `try/catch` và chuyển lỗi kỹ thuật thành thông báo tiếng Việt.
- Provider luôn phát trạng thái `loading`, `success` hoặc `error` và không để exception thoát lên widget tree.
- Danh sách có đủ loading, empty và error state; error state luôn có nút **Thử lại**.
- Clipboard, xuất PNG, date picker và xử lý form đều được bao lỗi.
- Sau async UI chỉ sử dụng context khi `context.mounted` còn đúng.
- Xóa linh kiện/sản phẩm đang được tham chiếu sẽ chuyển sang inactive thay vì làm vỡ khóa ngoại.
- Repository quản trị xác thực role admin từ SQLite trước mọi thao tác ghi.

## Phase 6 — Tests và checklist QA

Test tự động nằm tại `test/tech_modules_logic_test.dart` và `test/tech_modules_widget_test.dart`, bao phủ:

- Socket khớp/không khớp và ngưỡng PSU 1.25.
- Streak liên tục và reset khi bỏ ngày.
- Công thức khấu hao và khoảng mua/bán.
- Trích biến và dựng prompt.
- Responsive `ModuleHero` ở độ rộng 320 px.
- Error state gọi đúng hành động retry.

Checklist kiểm tra thủ công 6 bước:

1. Đăng nhập tài khoản demo, mở Bảng tin, xác nhận Daily Quest có đúng 3 câu và Tech Lab hiển thị không overflow ở light/dark mode.
2. Trả lời đủ ba câu, kiểm tra điểm/XP thay đổi tức thời, hoàn thành ngày cập nhật streak và popup huy hiệu chỉ xuất hiện một lần.
3. Mở PC Builder, chọn đủ sáu slot; kiểm tra ca socket sai, PSU thiếu watt, ca hợp lệ, tổng giá, lưu/mở/xóa build và xuất PNG.
4. Mở AI Library, thử bốn bộ lọc, điền mọi biến, đối chiếu preview, sao chép clipboard, bookmark rồi bỏ bookmark.
5. Mở Gear Price, tìm ít nhất một laptop/iPhone/keyboard/GPU, kéo condition, đổi ngày mua, đối chiếu khoảng giá/specs và thêm/xóa khỏi Closet.
6. Với tài khoản admin, vào `/admin/tech-modules`, tạo/sửa/xóa một bản ghi ở cả bốn tab; khởi động lại app hai lần và xác nhận seed không bị nhân đôi.
