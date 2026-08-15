#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Register UniMarket API to start automatically when Windows boots.

.PARAMETER ProjectDir
  Path to backend/UniMarket.Api (contains .csproj and .env).

.PARAMETER PublishDir
  Optional. If set, publishes Release build here and runs the DLL instead of dotnet run.

.EXAMPLE
  .\install-windows-service.ps1 -ProjectDir "E:\Pro\UniMarket\unimarket\backend\UniMarket.Api"

.EXAMPLE
  .\install-windows-service.ps1 -ProjectDir "E:\Pro\UniMarket\unimarket\backend\UniMarket.Api" -PublishDir "C:\UniMarket\api"
#>
param(
  [Parameter(Mandatory = $true)]
  [string] $ProjectDir,

  [string] $PublishDir = ""
)

$TaskName = "UniMarket API"
$Dotnet = (Get-Command dotnet -ErrorAction Stop).Source

if ($PublishDir) {
  Write-Host "Publishing Release to $PublishDir ..."
  New-Item -ItemType Directory -Force -Path $PublishDir | Out-Null
  & $Dotnet publish $ProjectDir -c Release -o $PublishDir
  if ($LASTEXITCODE -ne 0) { throw "dotnet publish failed" }

  $WorkDir = $PublishDir
  $Arguments = "`"$PublishDir\UniMarket.Api.dll`""
} else {
  $WorkDir = $ProjectDir
  $Arguments = "run --project `"$ProjectDir\UniMarket.Api.csproj`" --no-launch-profile"
}

$Action = New-ScheduledTaskAction `
  -Execute $Dotnet `
  -Argument $Arguments `
  -WorkingDirectory $WorkDir

$Trigger = New-ScheduledTaskTrigger -AtStartup

$Settings = New-ScheduledTaskSettingsSet `
  -AllowStartIfOnBatteries `
  -DontStopIfGoingOnBatteries `
  -StartWhenAvailable `
  -RestartCount 999 `
  -RestartInterval (New-TimeSpan -Minutes 1)

Register-ScheduledTask `
  -TaskName $TaskName `
  -Action $Action `
  -Trigger $Trigger `
  -Settings $Settings `
  -RunLevel Highest `
  -Force | Out-Null

Write-Host ""
Write-Host "Registered scheduled task: $TaskName"
Write-Host "Start now:  Start-ScheduledTask -TaskName '$TaskName'"
Write-Host "Check:      curl http://127.0.0.1:5080/health"
Write-Host ""
Write-Host "Also ensure cloudflared starts at boot (Cloudflare dashboard or Windows Service)."
