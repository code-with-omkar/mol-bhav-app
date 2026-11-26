<#
.SYNOPSIS
  Runs tools/history-import.cs for a date range, with the database connection and API key read from user-secrets.
  Progress and log files are kept outside the repository. Stop it by closing the window; run it again to resume.

    ./source/tools/run-history-import.ps1 -From 2023-11-25 -To 2026-11-24
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $From,
    [Parameter(Mandatory)] [string] $To,
    [string] $WorkFolder
)

# Worked out here, not as a parameter default: Windows PowerShell 5.1 leaves $PSScriptRoot empty there.
$root = Split-Path $PSScriptRoot
if (-not $WorkFolder) { $WorkFolder = Join-Path (Split-Path $root) 'history-import' }
$api = Join-Path $root 'api\src\MolBhav.Api'
New-Item -ItemType Directory -Force $WorkFolder | Out-Null

$secrets = dotnet user-secrets list --project $api
$env:MB_CS = ($secrets | Where-Object { $_ -like 'ConnectionStrings:MolBhav*' }) -replace '^ConnectionStrings:MolBhav = ', ''
$env:MB_KEY = ($secrets | Where-Object { $_ -like 'Agmarknet:ApiKey*' }) -replace '^Agmarknet:ApiKey = ', ''

$Host.UI.RawUI.WindowTitle = "MolBhav history load $From to $To"
Set-Location $root
dotnet run tools/history-import.cs -- $From $To (Join-Path $WorkFolder 'progress.txt') (Join-Path $api 'appsettings.json') |
    Tee-Object -FilePath (Join-Path $WorkFolder 'import.log') -Append
