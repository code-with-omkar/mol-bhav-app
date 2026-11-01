<#
.SYNOPSIS
  Starts the MolBhav API the right way for the phone app, and tells you the address to use.

.DESCRIPTION
  The app shows "No internet connection" when it cannot reach the API. The usual causes, all checked here:
    1. The API is not running, or listens only on this PC (it must use the "lan" launch profile: http://0.0.0.0:5189).
    2. This PC's Wi-Fi address changed (another network) and the phone app still has the old one.
    3. The database (PostgreSQL, port 5432) is not running.
    4. The phone is not on the same Wi-Fi as this PC.

  Run from anywhere:   ./source/api/scripts/start-dev.ps1
  Check only:          ./source/api/scripts/start-dev.ps1 -CheckOnly
  Restart the API:     ./source/api/scripts/start-dev.ps1 -Restart

  Live Agmarknet data is on by default in Development (appsettings.Development.json); nothing is pulled until you
  press "Run now" in the app or the 06:00 IST schedule fires.
#>
[CmdletBinding()]
param(
    [switch] $CheckOnly,
    [switch] $Restart,
    [int] $Port = 5189
)

$ErrorActionPreference = 'Stop'
$apiRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$ok = $true

function Write-Step($text) { Write-Host "`n== $text" -ForegroundColor Cyan }
function Write-Ok($text) { Write-Host "  OK   $text" -ForegroundColor Green }
function Write-Bad($text) { Write-Host "  FAIL $text" -ForegroundColor Red; $script:ok = $false }
function Write-Note($text) { Write-Host "       $text" -ForegroundColor Yellow }

# --- 1. This PC's address on the network the phone would use -------------------------------------------------------
Write-Step "This PC's network address"
$route = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue |
    Where-Object { $_.NextHop -ne '0.0.0.0' } | Sort-Object RouteMetric | Select-Object -First 1
$lanIp = $null
if ($route) {
    $lanIp = (Get-NetIPAddress -InterfaceIndex $route.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.PrefixOrigin -ne 'WellKnown' } | Select-Object -First 1).IPAddress
    $profile = Get-NetConnectionProfile -InterfaceIndex $route.InterfaceIndex -ErrorAction SilentlyContinue
}
if ($lanIp) {
    Write-Ok "$lanIp  ($($profile.Name), $($profile.NetworkCategory))"
}
else {
    Write-Bad 'No network connection found. Connect this PC to Wi-Fi first.'
}

# --- 2. Database ----------------------------------------------------------------------------------------------------
Write-Step 'Database (PostgreSQL, port 5432)'
if (Get-NetTCPConnection -State Listen -LocalPort 5432 -ErrorAction SilentlyContinue) {
    Write-Ok 'Listening on 5432'
}
else {
    Write-Bad 'Nothing listens on 5432. Start PostgreSQL (the Windows service postgresql-x64-18, or: docker compose up -d in source/api).'
}

# --- 3. The API -----------------------------------------------------------------------------------------------------
function Get-ApiListeners { Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue }

function Stop-Api {
    Get-CimInstance Win32_Process -Filter "Name='dotnet.exe' or Name='MolBhav.Api.exe'" |
        Where-Object { $_.CommandLine -match 'MolBhav.Api' -or $_.Name -eq 'MolBhav.Api.exe' } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    Start-Sleep -Seconds 2
}

Write-Step "The API (port $Port)"
$listeners = @(Get-ApiListeners)
$onNetwork = $listeners | Where-Object { $_.LocalAddress -in '0.0.0.0', '::' }

if ($listeners -and -not $onNetwork) {
    Write-Bad "The API is running but listens only on this PC ($($listeners.LocalAddress -join ', ')). The phone cannot reach it."
    Write-Note 'It was started with the "http" profile. It needs the "lan" profile; restarting it.'
    if (-not $CheckOnly) { Stop-Api; $listeners = @() }
}
elseif ($listeners -and $Restart -and -not $CheckOnly) {
    Write-Note 'Restarting the API as asked.'
    Stop-Api
    $listeners = @()
}

if (-not $listeners) {
    if ($CheckOnly) {
        Write-Bad 'The API is not running.'
    }
    else {
        Write-Note 'Starting the API in a new window (close that window to stop it)...'
        $env:ASPNETCORE_ENVIRONMENT = 'Development'
        Start-Process powershell -WorkingDirectory $apiRoot -ArgumentList @(
            '-NoExit', '-Command',
            "dotnet run --project src/MolBhav.Api --launch-profile lan")
        $deadline = (Get-Date).AddSeconds(120)
        while ((Get-Date) -lt $deadline) {
            Start-Sleep -Seconds 3
            try {
                if ((Invoke-WebRequest "http://localhost:$Port/api/v1/auth/methods" -UseBasicParsing -TimeoutSec 4).StatusCode -eq 200) { break }
            }
            catch { }
        }
    }
}

try {
    $r = Invoke-WebRequest "http://localhost:$Port/api/v1/auth/methods" -UseBasicParsing -TimeoutSec 5
    Write-Ok "Answers on http://localhost:$Port (HTTP $($r.StatusCode))"
}
catch { Write-Bad "No answer on http://localhost:$Port. If it was just started, wait a minute and run this again." }

if ($lanIp) {
    try {
        $r = Invoke-WebRequest "http://${lanIp}:$Port/api/v1/auth/methods" -UseBasicParsing -TimeoutSec 5
        Write-Ok "Answers on the network address http://${lanIp}:$Port (HTTP $($r.StatusCode))"
    }
    catch { Write-Bad "No answer on http://${lanIp}:$Port. The API must use the 'lan' profile (this script starts it that way)." }
}

# --- 4. The phone ---------------------------------------------------------------------------------------------------
$adb = (Get-Command adb -ErrorAction SilentlyContinue).Source
if (-not $adb) { $adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe' }
if ((Test-Path $adb) -and $lanIp) {
    Write-Step 'The phone'
    # adb prints "daemon not running; starting now" on stderr, which would stop this script.
    $ErrorActionPreference = 'Continue'
    & $adb start-server 2>&1 | Out-Null
    $device =(& $adb devices | Select-Object -Skip 1 | Where-Object { $_ -match "`tdevice$" } | Select-Object -First 1)
    if ($device) {
        $serial = ($device -split "`t")[0]
        $phoneIp = ((& $adb -s $serial shell 'ip -4 addr show wlan0' 2>$null) -join ' ') -replace '(?s).*inet (\d+\.\d+\.\d+\.\d+).*', '$1'
        if ($phoneIp -match '^\d+\.\d+\.\d+\.\d+$') {
            $samePrefix = ($phoneIp.Split('.')[0..2] -join '.') -eq ($lanIp.Split('.')[0..2] -join '.')
            if ($samePrefix) { Write-Ok "Phone Wi-Fi address $phoneIp is on the same network as this PC." }
            else { Write-Bad "Phone Wi-Fi address $phoneIp is NOT on this PC's network ($lanIp). Connect the phone to the same Wi-Fi." }
        }
        else { Write-Bad 'The phone has no Wi-Fi address. Turn Wi-Fi on and connect it to the same network as this PC.' }
    }
    else { Write-Note 'No phone connected over USB (skipping the phone check).' }
}

# --- What to put in the app -----------------------------------------------------------------------------------------
Write-Step 'What to use in the app'
if ($lanIp) {
    Write-Host "  API address for the app:  http://${lanIp}:$Port/api/v1" -ForegroundColor White
    Write-Host '  Already installed on the phone? On the Login screen tap "Server: ... change", enter'
    Write-Host "    ${lanIp}:$Port   press Test (it should say Connected), then Save. No rebuild needed."
    Write-Host '  Need to (re)install the app? Run this from source/app (about 4 minutes):'
    Write-Host "    flutter build apk --debug --dart-define=API_BASE_URL=http://${lanIp}:$Port/api/v1" -ForegroundColor White
    Write-Host '    adb install -r build/app/outputs/flutter-apk/app-debug.apk' -ForegroundColor White
}

if ($ok) { Write-Host "`nAll good." -ForegroundColor Green; exit 0 }
Write-Host "`nSomething needs fixing (see FAIL above)." -ForegroundColor Red
exit 1
