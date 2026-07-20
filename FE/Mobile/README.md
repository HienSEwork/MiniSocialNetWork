# TechNet mobile

Ứng dụng Flutter cho MiniSocialNetwork. Mobile dùng REST API cho auth, profile,
feed, groups, comments, reactions và chat; SignalR được dùng cho chat và thông
báo thời gian thực.

## Chạy với Android emulator

Backend development mặc định chạy tại `http://localhost:5046`; mobile tự ánh xạ
sang `http://10.0.2.2:5046/api` trên Android emulator.

```powershell
flutter pub get
flutter run
```

## Chạy trên điện thoại thật

Khởi động backend lắng nghe trong mạng LAN, sau đó truyền IP máy phát triển:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5046/api
```

Thay `192.168.1.10` bằng IP của máy chạy backend. Thiết bị và máy phát triển cần
ở cùng mạng.

## Kiểm tra và build

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

APK debug nằm tại `build/app/outputs/flutter-apk/app-debug.apk`.
