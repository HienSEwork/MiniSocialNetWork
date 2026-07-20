# TechNet Web (ASP.NET Core MVC)

Server-rendered web frontend for MiniSocialNetwork. It calls the existing
backend Web API (`BE/MiniSocialNetwork.API`) over HTTP and stores the backend
JWT inside an ASP.NET Core auth cookie.

## Run

1. Start the backend API (default `http://localhost:5046`).
2. Point the web app at it via `FE/Web/appsettings.json`:

   ```json
   "Api": { "BaseUrl": "http://localhost:5046" }
   ```

3. Run the web app:

   ```bash
   cd FE/Web
   dotnet run
   ```

Open the printed URL. Demo account (from the backend seeder):

```
demo01@minisocial.local / Password123!
```

## Features

- Auth: register, login, logout, forgot/reset password
- Feed: view, create, edit, delete posts with image/video upload
- Reactions (👍 ❤️ 😄) and comments via AJAX
- Groups: list, search, create/edit/delete, join/leave, members (kick / change role), group feed
- Profiles: view + edit (display name, bio, avatar upload)
- Search: unified users / groups / posts
- Chat: 1-1 and group messaging with SignalR realtime (REST fallback)
- Admin dashboard: stats, posts-per-day chart, user management (role required)
- Vietnamese / English switch, light / dark theme

## Notes

- Admin pages require the `Admin` role on the signed-in user.
- Media is uploaded through the backend `POST /api/media/upload`.
