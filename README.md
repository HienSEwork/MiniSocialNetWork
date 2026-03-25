# MiniSocialNetWork
Mini Social NetWork 

## SMTP mail sender

Project now supports real SMTP sending for confirm-email and forgot-password without depending on `appsettings.json`.

Configure one of these:

1. Environment variables

```powershell
$env:SOCIALNETWORK_SMTP_HOST = "smtp.gmail.com"
$env:SOCIALNETWORK_SMTP_PORT = "587"
$env:SOCIALNETWORK_SMTP_USERNAME = "your-account@gmail.com"
$env:SOCIALNETWORK_SMTP_PASSWORD = "your-app-password"
$env:SOCIALNETWORK_SMTP_FROM_EMAIL = "your-account@gmail.com"
$env:SOCIALNETWORK_SMTP_FROM_NAME = "Mini Social"
$env:SOCIALNETWORK_SMTP_ENABLE_SSL = "true"
```

2. User secrets

```powershell
dotnet user-secrets set "Mail:Smtp:Host" "smtp.gmail.com" --project src/SocialNetwork.Web
dotnet user-secrets set "Mail:Smtp:Port" "587" --project src/SocialNetwork.Web
dotnet user-secrets set "Mail:Smtp:Username" "your-account@gmail.com" --project src/SocialNetwork.Web
dotnet user-secrets set "Mail:Smtp:Password" "your-app-password" --project src/SocialNetwork.Web
dotnet user-secrets set "Mail:Smtp:FromEmail" "your-account@gmail.com" --project src/SocialNetwork.Web
dotnet user-secrets set "Mail:Smtp:FromName" "Mini Social" --project src/SocialNetwork.Web
dotnet user-secrets set "Mail:Smtp:EnableSsl" "true" --project src/SocialNetwork.Web
```

Optional local pickup directory:

```powershell
dotnet user-secrets set "Mail:Smtp:PickupDirectory" "D:\\Temp\\MiniSocialMail" --project src/SocialNetwork.Web
```
