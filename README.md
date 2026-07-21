# MiniSocialNetwork backend

Backend ASP.NET Core 8 gồm JWT/Identity, profile, posts/feed, upload media,
comments, reactions, groups, admin dashboard, chat và SignalR notifications.

## Chuẩn bị database

Cập nhật `BE/MiniSocialNetwork.API/appsettings.json` nếu SQL Server không dùng
instance mặc định, sau đó chạy:

```powershell
cd BE
dotnet restore
dotnet ef database update `
  --project MiniSocialNetwork.Infrastructure `
  --startup-project MiniSocialNetwork.API
```

## Chạy API

```powershell
cd BE
dotnet run --project MiniSocialNetwork.API --launch-profile http
```

Swagger: `http://localhost:5046/swagger`. Hai role `Admin` và `User` được seed
khi ứng dụng khởi động. Người dùng đăng ký mới nhận role `User`.

Để thử bằng điện thoại thật trong cùng mạng:

```powershell
dotnet run --project MiniSocialNetwork.API --urls http://0.0.0.0:5046
```

## Cấu hình production

- Ghi đè `ConnectionStrings__DefaultConnection` bằng secret của môi trường.
- Ghi đè `Jwt__Key`, `Jwt__Issuer`, `Jwt__Audience`; không dùng JWT key mẫu.
- Chỉ phục vụ HTTPS và giới hạn CORS theo domain thực tế.
- Dùng object storage/CDN thay cho thư mục `wwwroot/uploads` nếu triển khai nhiều instance.
