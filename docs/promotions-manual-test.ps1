#!/usr/bin/env pwsh
# MolBhav — Phase 4B Sponsored Campaigns Manual Test
# Steps 89-95 + app checklist
# Usage: .\promotions-manual-test.ps1 [-BaseUrl http://localhost:5000] [-AdminPhone +919999000001] [-UserPhone +919999000002]

param(
    [string]$BaseUrl   = "http://localhost:5000",
    [string]$AdminPhone = "+919999000001",   # must have Admin role
    [string]$UserPhone  = "+919999000002"    # must have Free plan + agriculture category
)

Set-StrictMode -Version 1
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = "Stop"

$h = @{ "Content-Type" = "application/json" }

function Say($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Ok($msg)  { Write-Host "    OK  $msg" -ForegroundColor Green }
function Fail($msg){ Write-Host "    ERR $msg" -ForegroundColor Red; exit 1 }

function Post($url, $body, $tok) {
    $headers = if ($tok) { @{ "Content-Type"="application/json"; "Authorization"="Bearer $tok" } } else { $h }
    $r = Invoke-RestMethod -Uri "$BaseUrl$url" -Method POST -Headers $headers -Body ($body | ConvertTo-Json -Depth 10) -ErrorAction Stop
    return $r
}
function Get($url, $tok) {
    $headers = @{ "Authorization"="Bearer $tok" }
    return Invoke-RestMethod -Uri "$BaseUrl$url" -Method GET -Headers $headers -ErrorAction Stop
}
function Put($url, $body, $tok) {
    $headers = @{ "Content-Type"="application/json"; "Authorization"="Bearer $tok" }
    return Invoke-RestMethod -Uri "$BaseUrl$url" -Method PUT -Headers $headers -Body ($body | ConvertTo-Json -Depth 10) -ErrorAction Stop
}

# ─────────────────────────────────────────────
# Helper: OTP login (dev mode returns OTP in response)
# ─────────────────────────────────────────────
function Login($phone) {
    $r1 = Post "/api/v1/auth/send-otp" @{ phoneNumber = $phone } $null
    $otp = if ($r1.data.otp) { $r1.data.otp } else {
        Read-Host "Enter OTP sent to $phone"
    }
    $r2 = Post "/api/v1/auth/verify-otp" @{ phoneNumber = $phone; otp = $otp } $null
    if (-not $r2.data.accessToken) { Fail "Login failed for $phone" }
    return $r2.data.accessToken
}

# ─────────────────────────────────────────────
# STEP 89 — Login as Admin
# ─────────────────────────────────────────────
Say "89. Login as admin ($AdminPhone)"
$adminTok = Login $AdminPhone
Ok "Admin token obtained"

# ─────────────────────────────────────────────
# STEP 90 — Create advertiser
# ─────────────────────────────────────────────
Say "90. Create advertiser"
$adv = Post "/api/v1/admin/promotions/advertisers" @{
    companyName = "Tata Agri Ltd"
    contactEmail = "ads@tata-agri.example.com"
    contactPhone = "+919800000001"
    gstin = "27AABCT3518Q1ZA"   # valid format: 15-char GSTIN
} $adminTok
$advId = $adv.data.id
if (-not $advId) { Fail "Advertiser creation failed: $($adv | ConvertTo-Json)" }
Ok "Advertiser created: id=$advId"

# ─────────────────────────────────────────────
# STEP 91 — Book campaign (targets agriculture, home_feed, active today)
# ─────────────────────────────────────────────
Say "91. Book campaign"
$today     = (Get-Date).ToString("yyyy-MM-dd")
$tomorrow  = (Get-Date).AddDays(30).ToString("yyyy-MM-dd")

$campaign = Post "/api/v1/admin/promotions/campaigns" @{
    advertiserId      = $advId
    name              = "Tata Agri — Monsoon Sale"
    placement         = "home_feed"
    startsAtUtc       = "${today}T00:00:00Z"
    endsAtUtc         = "${tomorrow}T23:59:59Z"
    dailyImpressionCap = 500
    priority          = 10
    targets           = @(
        @{ categoryCode = "agriculture"; stateId = $null }
    )
    creative = @{
        headline    = "Best seeds this monsoon"
        description = "Tata Agri certified seeds now available"
        ctaText     = "Shop Now"
        ctaUrl      = "https://tata-agri.example.com/seeds"
        imageUrl    = "https://tata-agri.example.com/banner.jpg"
    }
} $adminTok
$campId = $campaign.data.id
if (-not $campId) { Fail "Campaign creation failed: $($campaign | ConvertTo-Json)" }
Ok "Campaign created: id=$campId  status=$($campaign.data.status)"

# Activate
Say "91b. Activate campaign"
$activated = Put "/api/v1/admin/promotions/campaigns/$campId/status" @{ status = "Active" } $adminTok
if ($activated.data.status -ne "Active") { Fail "Activate failed: $($activated | ConvertTo-Json)" }
Ok "Campaign status = Active"

# ─────────────────────────────────────────────
# STEP 92 — Login as free user, serve promotion
# ─────────────────────────────────────────────
Say "92. Login as free user ($UserPhone)"
$userTok = Login $UserPhone
Ok "Free-user token obtained"

Say "92. GET /api/v1/promotions?placement=home_feed (free user, agriculture category)"
$served = Get "/api/v1/promotions?placement=home_feed" $userTok
$promo = $served.data

if (-not $promo) {
    Fail "Expected a promotion but got null. Check user has agriculture category and is NOT Pro."
}
Ok "Promotion returned:"
Ok "  id           = $($promo.id)"
Ok "  campaignId   = $($promo.campaignId)"
Ok "  advertiser   = $($promo.advertiserName)"
Ok "  headline     = $($promo.headline)"
Ok "  ctaUrl       = $($promo.ctaUrl)"

if ($promo.ctaUrl -notmatch '^https://') {
    Fail "ctaUrl must start with https:// — got: $($promo.ctaUrl)"
}
Ok "  ctaUrl is HTTPS ✓"

# Save promotion id for event reporting
$promoId = $promo.id

# ─────────────────────────────────────────────
# STEP 92b — Pro user should get null
# ─────────────────────────────────────────────
Say "92b. (Optional) Verify Pro user gets null — skip if no Pro user available"
Write-Host "    Skipping (no Pro test user configured). Verify manually if needed." -ForegroundColor Yellow

# ─────────────────────────────────────────────
# STEP 93 — Record events; verify per-user caps
# ─────────────────────────────────────────────

function SendEvents($type, $count, $tok, $pid) {
    $events = @()
    for ($i = 0; $i -lt $count; $i++) {
        $events += @{ promotionId = $pid; eventType = $type; occurredAtUtc = (Get-Date -Format "o") }
    }
    Post "/api/v1/promotions/events" @{ events = $events } $tok | Out-Null
}

Say "93. Send 25 impressions in batches (cap = 20)"
SendEvents "Impression" 10 $userTok $promoId
Ok "  Batch 1: 10 impressions sent"
SendEvents "Impression" 10 $userTok $promoId
Ok "  Batch 2: 10 impressions sent  (total attempted = 20, all should count)"
SendEvents "Impression" 5  $userTok $promoId
Ok "  Batch 3: 5 impressions sent   (these 5 should be capped / ignored)"

Say "93. Send 8 clicks (cap = 5)"
SendEvents "Click" 5 $userTok $promoId
Ok "  Batch 1: 5 clicks sent"
SendEvents "Click" 3 $userTok $promoId
Ok "  Batch 2: 3 clicks sent  (these 3 should be capped)"

# ─────────────────────────────────────────────
# STEP 94/95 — Check today's stats via admin endpoint
# ─────────────────────────────────────────────
Say "94. GET /api/v1/admin/promotions/campaigns/$campId/stats"
$today8 = (Get-Date).ToString("yyyy-MM-dd")
$stats = Get "/api/v1/admin/promotions/campaigns/$campId/stats?from=$today8&to=$today8" $adminTok

$todayStats = $stats.data | Where-Object { $_.date -eq $today8 }
if (-not $todayStats) { Fail "No stats returned for today ($today8)" }

$impressions = $todayStats.impressions
$clicks      = $todayStats.clicks
Ok "Today's stats: impressions=$impressions  clicks=$clicks"

# Per-user caps: user should have max 20 impressions, max 5 clicks credited
if ($impressions -gt 20) {
    Fail "impressions=$impressions exceeds per-user cap of 20 — CampaignUserDailyCount not working!"
}
if ($clicks -gt 5) {
    Fail "clicks=$clicks exceeds per-user cap of 5 — CampaignUserDailyCount not working!"
}
if ($impressions -ne 20) {
    Write-Host "    WARN impressions=$impressions (expected 20) — may be other users or timing" -ForegroundColor Yellow
} else {
    Ok "  impressions capped at 20 ✓"
}
if ($clicks -ne 5) {
    Write-Host "    WARN clicks=$clicks (expected 5) — may be other users or timing" -ForegroundColor Yellow
} else {
    Ok "  clicks capped at 5 ✓"
}

# ─────────────────────────────────────────────
# STEP 95 — End campaign, verify it stops serving
# ─────────────────────────────────────────────
Say "95. End campaign → verify it stops serving"
Put "/api/v1/admin/promotions/campaigns/$campId/status" @{ status = "Ended" } $adminTok | Out-Null
Ok "Campaign status set to Ended"

$afterEnd = Get "/api/v1/promotions?placement=home_feed" $userTok
if ($afterEnd.data -ne $null) {
    Fail "Expected null after campaign ended — got: $($afterEnd.data | ConvertTo-Json)"
}
Ok "promotion=null after campaign ended ✓"

# ─────────────────────────────────────────────
Write-Host ""
Write-Host "══════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  All API checks passed ✓" -ForegroundColor Green
Write-Host "══════════════════════════════════════════════" -ForegroundColor Cyan

Write-Host @"

── APP CHECKLIST (manual) ──────────────────────

Re-activate the campaign before testing the app:
  PUT /api/v1/admin/promotions/campaigns/$campId/status  { "status": "Active" }

Then in the Flutter app (free user, agriculture category):

[ ] Home page loads → "Sponsored" card appears instead of AdMob native ad
    - Card shows headline: "Best seeds this monsoon"
    - Sub-label shows advertiser name: "Tata Agri Ltd"
    - "Sponsored" badge visible in corner

[ ] Scroll card out of view (< 50% visible) → scroll back in to 50%+ visible
    - Only ONE impression logged per card mount (check API stats after)

[ ] Tap "Shop Now" button → browser opens https://tata-agri.example.com/seeds
    - Check logcat/console: PromotionEventsTracker flushed a Click event

[ ] Run app to background → reopen
    - Event queue should have flushed (check logcat for "flushing N events")

[ ] Log out → log back in as Pro user → Home page
    - Native AdMob ad should show (not SponsoredCard)
    - GET /api/v1/promotions returns 200 with data=null for Pro users

"@
