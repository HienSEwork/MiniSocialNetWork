# TechNet Mobile

Ứng dụng Flutter chạy độc lập trên Android/iOS. Toàn bộ tài khoản, feed, nhóm,
chat, story, marketplace, portfolio, thành tích, kết nối và Tech Job được lưu
trong SQLite trên thiết bị; ứng dụng không cần backend hay kết nối API.

## Chạy ứng dụng

```powershell
flutter pub get
flutter run
```

Database `technet.sqlite3` được tạo và seed ở lần chạy đầu tiên. Tài khoản demo:

- `demo01@minisocial.local` / `Password123!`
- `admin@minisocial.local` / `Password123!` (có màn quản trị)

Ảnh người dùng chọn được sao chép vào thư mục documents của ứng dụng, nên vẫn
hiển thị sau khi khởi động lại. Xóa dữ liệu ứng dụng để tạo lại database seed.
