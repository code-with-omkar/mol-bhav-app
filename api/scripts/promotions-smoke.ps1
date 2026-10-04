<#
.SYNOPSIS
    End-to-end smoke test for sponsored campaigns (phase 4) against a running API.

.DESCRIPTION
    1. Admin: creates an advertiser and a campaign targeting 'agriculture' (all states), activates it.
    2. Free user: fetches the HomeFeed slot (expects the campaign), reports 30 impressions + 9 clicks in 3 batches.
    3. Admin: checks today's counts were capped per user (20 impressions, 5 clicks) and prints daily stats.
    4. Ends the campaign so it stops serving.

    Prerequisites (one-off):
      - API running:   dotnet run --project src/MolBhav.Api --launch-profile https
      - Admin account: UPDATE identity.users SET role = 'Admin' WHERE phone_number = '+91<admin phone>';
      - Free user with the 'agriculture' category (Profile screen or request 4 in MolBhav.Api.http).
    Re-running is safe: each run books its own campaign and ends it.

.EXAMPLE
    ./scripts/promotions-smoke.ps1 -AdminPhone 9876543210 -AdminPassword 'Admin@123' -UserPhone 9876500000 -UserPassword 'User@123'
#>
[CmdletBinding()]
param(
    [string] $BaseUrl = 'https://localhost:7040',
    [Parameter(Mandatory)] [string] $AdminPhone,
    [Parameter(Mandatory)] [string] $AdminPassword,
    [Parameter(Mandatory)] [string] $UserPhone,
    [Parameter(Mandatory)] [string] $UserPassword
)

# Version 1 only: responses are JSON objects whose optional properties (e.g. a null promotion) must be readable.
Set-StrictMode -Version 1
$ErrorActionPreference = 'Stop'

# The local dev certificate may not be trusted: skip the check, but only for a local API.
$tls = @{}
$isLocal = ([Uri] $BaseUrl).IsLoopback
if ($PSVersionTable.PSVersion.Major -ge 7) {
    if ($isLocal) { $tls.SkipCertificateCheck = $true }
}
else {
    # Windows PowerShell 5.1: no -SkipCertificateCheck, and TLS 1.2 is off by default.
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    if ($isLocal) { [Net.ServicePointManager]::ServerCertificateValidationCallback = { $true } }
}

$script:failures = 0

function Invoke-Api {
    param(
        [Parameter(Mandatory)] [string] $Method,
        [Parameter(Mandatory)] [string] $Path,
        [string] $Token,
        $Body
    )
    $headers = @{ Accept = 'application/json' }
    if ($Token) { $headers.Authorization = "Bearer $Token" }
    $request = @{ Method = $Method; Uri = "$BaseUrl/api/v1$Path"; Headers = $headers } + $tls
    if ($null -ne $Body) {
        $request.ContentType = 'application/json'
        $request.Body = ($Body | ConvertTo-Json -Depth 10)
    }
    try {
        Invoke-RestMethod @request
    }
    catch {
        $detail = if ($_.ErrorDetails) { $_.ErrorDetails.Message } else { '' }
        throw "$Method $Path failed: $($_.Exception.Message) $detail"
    }
}

function Assert-That([bool] $Condition, [string] $Message) {
    if ($Condition) { Write-Host "  PASS  $Message" -ForegroundColor Green }
    else { Write-Host "  FAIL  $Message" -ForegroundColor Red; $script:failures++ }
}

function Get-Token([string] $Phone, [string] $Password) {
    $login = Invoke-Api POST '/auth/password/login' -Body @{ phoneNumber = $Phone; password = $Password }
    $token = $login.data.session.accessToken
    if (-not $token) {
        throw "Login for $Phone returned no access token: $($login | ConvertTo-Json -Depth 5 -Compress)"
    }
    $token
}

Write-Host "`n== Sign in" -ForegroundColor Cyan
$admin = Get-Token $AdminPhone $AdminPassword
$user = Get-Token $UserPhone $UserPassword
Write-Host '  signed in as admin and user'

Write-Host "`n== Admin: book and activate a campaign" -ForegroundColor Cyan
$stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
$advertiserId = (Invoke-Api POST '/admin/promotions/advertisers' -Token $admin -Body @{
        name = "Smoke Test Seeds $stamp"; contactName = 'QA'; contactPhone = '+919800000000'; gstin = $null
    }).data.id
Write-Host "  advertiser $advertiserId"

$now = [DateTimeOffset]::UtcNow
$campaignId = (Invoke-Api POST '/admin/promotions/campaigns' -Token $admin -Body @{
        advertiserId = $advertiserId
        campaign     = @{
            name               = "Smoke $stamp"
            placement          = 'HomeFeed'
            title              = 'Smoke test sponsor'
            body               = 'If you can read this, sponsored cards work.'
            ctaLabel           = 'Open'
            ctaUrl             = 'https://example.com/?q=a%26b'
            imageUrl           = $null
            startsAtUtc        = $now.AddMinutes(-5).ToString('o')
            endsAtUtc          = $now.AddDays(1).ToString('o')
            priority           = 100
            dailyImpressionCap = 1000
            targets            = @(@{ categoryCode = 'agriculture'; stateId = $null })
        }
    }).data.id
Write-Host "  campaign $campaignId"

Invoke-Api PUT "/admin/promotions/campaigns/$campaignId/status" -Token $admin -Body @{ action = 'Activate' } | Out-Null
Write-Host '  activated'

try {
    Write-Host "`n== User: fetch the HomeFeed slot" -ForegroundColor Cyan
    $slot = (Invoke-Api GET '/promotions?placement=HomeFeed' -Token $user).data
    Assert-That ($null -ne $slot.promotion) 'a sponsored card is served'
    if ($null -ne $slot.promotion) {
        Assert-That ($slot.promotion.campaignId -eq $campaignId) "it is this campaign (priority 100 wins) — got $($slot.promotion.campaignId)"
        Assert-That ($slot.promotion.ctaUrl -eq 'https://example.com/?q=a%26b') "link kept its escapes — $($slot.promotion.ctaUrl)"
    }
    else {
        Write-Host '        Check: user is Free (not Pro), has the agriculture category, and the API clock is right.' -ForegroundColor Yellow
    }

    Write-Host "`n== User: report 3 batches of 10 impressions + 3 clicks" -ForegroundColor Cyan
    $events = @(1..10 | ForEach-Object { @{ campaignId = $campaignId; type = 'Impression' } }) +
              @(1..3 | ForEach-Object { @{ campaignId = $campaignId; type = 'Click' } })
    1..3 | ForEach-Object {
        Invoke-Api POST '/promotions/events' -Token $user -Body @{ events = $events } | Out-Null
        Write-Host "  batch $_ sent"
    }

    Write-Host "`n== Admin: check the per-user daily cap" -ForegroundColor Cyan
    $list = (Invoke-Api GET "/admin/promotions/campaigns?advertiserId=$advertiserId" -Token $admin).data
    $row = @($list | Where-Object id -eq $campaignId)[0]
    Assert-That ($null -ne $row) 'campaign appears in the admin list'
    if ($null -ne $row) {
        Assert-That ($row.impressionsToday -eq 20) "impressions today = 20 (30 sent, capped per user) — got $($row.impressionsToday)"
        Assert-That ($row.clicksToday -eq 5) "clicks today = 5 (9 sent, capped per user) — got $($row.clicksToday)"
    }

    $stats = (Invoke-Api GET "/admin/promotions/campaigns/$campaignId/stats" -Token $admin).data
    Write-Host '  daily stats:'
    $stats | Format-Table day, impressions, clicks -AutoSize | Out-String | Write-Host
}
finally {
    Write-Host "== Admin: end the campaign" -ForegroundColor Cyan
    Invoke-Api PUT "/admin/promotions/campaigns/$campaignId/status" -Token $admin -Body @{ action = 'End' } | Out-Null
    $after = (Invoke-Api GET '/promotions?placement=HomeFeed' -Token $user).data
    Assert-That ($null -eq $after.promotion -or $after.promotion.campaignId -ne $campaignId) 'ended campaign is no longer served'
}

Write-Host ''
if ($script:failures -eq 0) { Write-Host 'All checks passed.' -ForegroundColor Green; exit 0 }
Write-Host "$script:failures check(s) failed." -ForegroundColor Red
exit 1
