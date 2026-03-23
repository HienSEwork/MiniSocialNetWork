$ErrorActionPreference = "Stop"

$projectPath = "src/SocialNetwork.Web/SocialNetwork.Web.csproj"
$watchArgs = @(
    "watch",
    "--project", $projectPath,
    "run",
    "--launch-profile", "https"
)

Get-Process |
    Where-Object { $_.ProcessName -eq "SocialNetwork.Web" } |
    Stop-Process -Force -ErrorAction SilentlyContinue

Write-Host "Starting hot reload for SocialNetwork.Web..."
Write-Host "Changes in .razor, .css, .cs will auto refresh when supported."

dotnet @watchArgs
