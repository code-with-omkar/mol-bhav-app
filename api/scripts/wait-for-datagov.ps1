<#
.SYNOPSIS
  Polls api.data.gov.in until it accepts connections, then reports and exits.

.DESCRIPTION
  The Agmarknet live adapter calls https://api.data.gov.in. While that host is unreachable, import price CSVs through the
  drop folder instead (see README, "Drop-folder importer"). This script tells you when the host is back.

  Each attempt checks a TCP connect to port 443, then one HTTPS request for a single row of the Agmarknet resource.
  Any HTTP response (even 401/403 for a missing or invalid key) means the host is up. Exit codes: 0 = up, 1 = gave up.

  The key is read from -ApiKey or the Agmarknet__ApiKey environment variable and sent as a query parameter to
  api.data.gov.in only; it is never printed. Without a key the host check still works.

.EXAMPLE
  ./scripts/wait-for-datagov.ps1                              # check every 5 minutes, for up to 24 hours
  ./scripts/wait-for-datagov.ps1 -IntervalMinutes 1 -MaxHours 2
#>
[CmdletBinding()]
param(
    [int] $IntervalMinutes = 5,
    [double] $MaxHours = 24,
    [string] $ApiKey = $env:Agmarknet__ApiKey,

    # When the host answers HTTP 200, make the agmarknet schedule due now so the running API's scheduler pulls within
    # about a minute. Needs the API running with Agmarknet:UseMockData=false; connects with the app's own connection string.
    [switch] $TriggerPull
)

$ErrorActionPreference = 'Stop'

# Fall back to the key the API itself uses (user-secrets) so a 200 can be told apart from a rejected key.
if (-not $ApiKey) {
    $secret = dotnet user-secrets list --project (Join-Path $PSScriptRoot '..\src\MolBhav.Api') 2>$null |
        Select-String '^Agmarknet:ApiKey\s*='
    if ($secret) { $ApiKey = ($secret.Line -split '=', 2)[1].Trim() }
}

$hostName = 'api.data.gov.in'
$resource = '9ef84268-d588-465a-a308-a864a43d0070'
$deadline = (Get-Date).AddHours($MaxHours)
$attempt = 0

function Test-Port {
    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        $task = $client.ConnectAsync($hostName, 443)
        return $task.Wait(8000) -and $client.Connected
    }
    catch { return $false }
    finally { $client.Dispose() }
}

function Get-Status {
    $uri = "https://$hostName/resource/${resource}?format=json&limit=1"
    if ($ApiKey) { $uri += "&api-key=$ApiKey" }
    try {
        return [int](Invoke-WebRequest -Uri $uri -UseBasicParsing -TimeoutSec 30).StatusCode
    }
    catch {
        # A 4xx/5xx still proves the host answered.
        if ($_.Exception.Response) { return [int]$_.Exception.Response.StatusCode }
        return $null
    }
}

function Request-Pull {
    $project = Join-Path $PSScriptRoot '..\src\MolBhav.Api'
    $psql = (Get-Command psql -ErrorAction SilentlyContinue).Source
    if (-not $psql) {
        $psql = Get-ChildItem 'C:\Program Files\PostgreSQL' -Recurse -Filter psql.exe -ErrorAction SilentlyContinue |
            Select-Object -First 1 -ExpandProperty FullName
    }
    $cs = (dotnet user-secrets list --project $project | Select-String '^ConnectionStrings:MolBhav\s*=').Line
    if (-not $psql -or -not $cs) {
        Write-Host 'Cannot trigger the pull: psql or the MolBhav connection string (user-secrets) was not found.' -ForegroundColor Yellow
        return
    }

    $parts = @{}
    foreach ($pair in ($cs -split '=', 2)[1].Split(';')) {
        $kv = $pair.Split('=', 2)
        if ($kv.Count -eq 2) { $parts[$kv[0].Trim()] = $kv[1].Trim() }
    }

    $env:PGPASSWORD = $parts['Password']
    try {
        $port = if ($parts['Port']) { $parts['Port'] } else { '5432' }
        $sql = "update ingestion.ingestion_schedules set next_run_at_utc = now() " +
               "where is_enabled and price_source_id = (select id from pricing.price_sources where code = 'agmarknet')"
        $result = & $psql -h $parts['Host'] -p $port -U $parts['Username'] -d $parts['Database'] -At -c $sql 2>&1
        Write-Host "Schedule made due: $result. The API's scheduler runs it within ~1 minute (needs UseMockData=false)."
    }
    finally { $env:PGPASSWORD = $null }
}

Write-Host "Waiting for $hostName (every $IntervalMinutes min, up to $MaxHours h). Ctrl+C to stop."

while ((Get-Date) -lt $deadline) {
    $attempt++
    $stamp = Get-Date -Format 'HH:mm:ss'

    if (Test-Port) {
        $status = Get-Status
        if ($null -ne $status) {
            [Console]::Beep(880, 300)
            Write-Host "[$stamp] attempt ${attempt}: $hostName is UP (HTTP $status)." -ForegroundColor Green
            if ($status -eq 200) {
                if ($TriggerPull) { Request-Pull }
                else { Write-Host 'Live pull should work: set Agmarknet:UseMockData=false and run the source from the admin API.' }
            }
            elseif ($status -in 401, 403) {
                Write-Host 'The host answered but rejected the request: check Agmarknet:ApiKey (user-secrets).' -ForegroundColor Yellow
            }
            exit 0
        }
    }

    Write-Host "[$stamp] attempt ${attempt}: still unreachable."
    $remaining = ($deadline - (Get-Date)).TotalSeconds
    if ($remaining -le 0) { break }
    Start-Sleep -Seconds ([Math]::Ceiling([Math]::Min($IntervalMinutes * 60, $remaining)))
}

Write-Host "Gave up after $MaxHours h without a response." -ForegroundColor Red
exit 1
