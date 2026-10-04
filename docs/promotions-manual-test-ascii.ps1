param(
    [string]$BaseUrl      = "http://localhost:5189",
    [string]$AdminPhone   = "+919503119207",
    [string]$AdminPass    = "Admin@123",
    [string]$UserPhone    = "+919766909240",
    [string]$UserPass     = "User@123"
)

Set-StrictMode -Version 1
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = "Stop"

function Say($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Ok($msg)  { Write-Host "    OK  $msg" -ForegroundColor Green }
function Warn($msg){ Write-Host "    WARN $msg" -ForegroundColor Yellow }
function Fail($msg){ Write-Host "    ERR $msg" -ForegroundColor Red; exit 1 }

function CallApi($method, $url, $body, $tok) {
    $headers = @{ "Content-Type" = "application/json" }
    if ($tok) { $headers["Authorization"] = "Bearer $tok" }
    $params = @{ Uri = "$BaseUrl$url"; Method = $method; Headers = $headers }
    if ($body) { $params["Body"] = ($body | ConvertTo-Json -Depth 10 -Compress) }
    try {
        return Invoke-RestMethod @params
    } catch {
        $sr = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        Fail "$method $url => $($_.Exception.Response.StatusCode): $($sr.ReadToEnd())"
    }
}

function Login($phone, $pass) {
    $r = CallApi "POST" "/api/v1/auth/password/login" @{ phoneNumber = $phone; password = $pass } $null
    if (-not $r.data.session.accessToken) { Fail "Login failed for $phone" }
    Ok "Logged in as $phone"
    return $r.data.session.accessToken
}

# -- 89. Admin login --
Say "89. Admin login ($AdminPhone)"
$adminTok = Login $AdminPhone $AdminPass

# -- 90. Create advertiser --
Say "90. Create advertiser"
$adv = CallApi "POST" "/api/v1/admin/promotions/advertisers" @{
    name         = "Tata Agri Ltd"
    contactName  = "Ravi Tata"
    contactPhone = "+919800000001"
    gstin        = "27AABCT3518Q1ZA"
} $adminTok
$advId = $adv.data.id
if (-not $advId) { Fail "Advertiser creation failed: $($adv | ConvertTo-Json)" }
Ok "Advertiser id=$advId"

# -- 91. Book campaign --
Say "91. Book campaign"
$today  = (Get-Date).ToString("yyyy-MM-dd")
$end30  = (Get-Date).AddDays(30).ToString("yyyy-MM-dd")

$campaignBody = [ordered]@{
    advertiserId = $advId
    campaign     = [ordered]@{
        name               = "Tata Agri Monsoon Sale"
        placement          = "HomeFeed"
        title              = "Best seeds this monsoon"
        body               = "Tata Agri certified seeds now available"
        ctaLabel           = "Shop Now"
        ctaUrl             = "https://tata-agri.example.com/seeds"
        imageUrl           = "https://tata-agri.example.com/banner.jpg"
        startsAtUtc        = "${today}T00:00:00Z"
        endsAtUtc          = "${end30}T23:59:59Z"
        dailyImpressionCap = 500
        priority           = 10
        targets            = @(
            [ordered]@{ categoryCode = "agriculture"; stateId = $null }
        )
    }
}

$campaign = CallApi "POST" "/api/v1/admin/promotions/campaigns" $campaignBody $adminTok
$campId = $campaign.data.id
if (-not $campId) { Fail "Campaign creation failed: $($campaign | ConvertTo-Json)" }
Ok "Campaign id=$campId"

Say "91b. Activate campaign"
CallApi "PUT" "/api/v1/admin/promotions/campaigns/$campId/status" @{ action = "Activate" } $adminTok | Out-Null
Ok "Activated"

# -- 91c. Verify campaign stored correctly --
Say "91c. Verify campaign"
$campCheck = CallApi "GET" "/api/v1/admin/promotions/campaigns/$campId" $null $adminTok
Ok "  Status    = $($campCheck.data.status)"
Ok "  Placement = $($campCheck.data.placement)"
Ok "  Starts    = $($campCheck.data.startsAtUtc)"
Ok "  Ends      = $($campCheck.data.endsAtUtc)"
if ($campCheck.data.status -ne "Active") { Fail "Campaign is not Active: $($campCheck.data.status)" }

# -- 92. Free user serve --
Say "92. Free user login ($UserPhone)"
$userTok = Login $UserPhone $UserPass

Say "92a. Diagnostic: serve with placement=0 (integer fallback)"
try {
    $s0 = Invoke-RestMethod -Uri "$BaseUrl/api/v1/promotions?placement=0" `
          -Headers @{ Authorization = "Bearer $userTok" }
    if ($s0.data.promotion) {
        Warn "placement=0 returned a promotion -- HomeFeed enum name is WRONG in Domain"
        Warn "  Check PromotionPlacement.cs for the correct member name"
        Warn "  Returned placement=$($campCheck.data.placement) -- use that value in the script"
    } else {
        Ok "placement=0 also null -- enum name is NOT the issue"
    }
} catch { Warn "placement=0 call failed: $_" }

Say "92b. Diagnostic: serve with no placement filter"
try {
    $sAll = Invoke-RestMethod -Uri "$BaseUrl/api/v1/promotions" `
            -Headers @{ Authorization = "Bearer $userTok" }
    if ($sAll.data.promotion) {
        Warn "No-placement returned a promotion -- HomeFeed placement mismatch only"
    } else {
        Ok "No-placement also null -- issue is user profile (category or Pro tier)"
    }
} catch { Warn "No-placement call failed: $_" }

Say "92c. Diagnostic: check user profile / categories"
try {
    # Try common admin user-lookup endpoints
    $userInfo = $null
    try { $userInfo = CallApi "GET" "/api/v1/admin/users?phoneNumber=$([System.Uri]::EscapeDataString($UserPhone))" $null $adminTok } catch {}
    if (-not $userInfo) {
        try { $userInfo = CallApi "GET" "/api/v1/admin/users?phone=$([System.Uri]::EscapeDataString($UserPhone))" $null $adminTok } catch {}
    }
    if ($userInfo) {
        $u = if ($userInfo.data -is [array]) { $userInfo.data[0] } else { $userInfo.data }
        Ok "  UserId       = $($u.id)"
        $tier = if ($u.tier -ne $null) { $u.tier } elseif ($u.subscriptionTier -ne $null) { $u.subscriptionTier } elseif ($u.subscription -ne $null) { $u.subscription } else { "(field unknown)" }
        $cats = if ($u.categories -ne $null) { $u.categories } elseif ($u.categoryCodes -ne $null) { $u.categoryCodes } elseif ($u.selectedCategories -ne $null) { $u.selectedCategories } else { "(field unknown)" }
        Ok "  Tier         = $tier"
        Ok "  Categories   = $($cats | ConvertTo-Json -Compress)"
        $userId = $u.id
    } else {
        Warn "Could not fetch user info -- check admin user endpoint path manually"
    }
} catch { Warn "User info call failed: $_" }

Say "92. GET /api/v1/promotions?placement=HomeFeed"
$served = CallApi "GET" "/api/v1/promotions?placement=HomeFeed" $null $userTok
$promo  = $served.data.promotion
if (-not $promo) {
    Write-Host ""
    Write-Host "  DIAGNOSIS SUMMARY:" -ForegroundColor Yellow
    Write-Host "  If 92a (placement=0) returned promotion  -> rename 'HomeFeed' to match Domain enum" -ForegroundColor Yellow
    Write-Host "  If 92b (no filter)   returned promotion  -> placement name issue only" -ForegroundColor Yellow
    Write-Host "  If both null                             -> user missing agriculture category OR is Pro" -ForegroundColor Yellow
    Write-Host "  Check 92c output for user tier + categories" -ForegroundColor Yellow
    Fail "Expected promotion but got null"
}
Ok "Promotion returned:"
Ok "  campaignId  = $($promo.campaignId)"
Ok "  advertiser  = $($promo.advertiserName)"
Ok "  title       = $($promo.title)"
Ok "  ctaUrl      = $($promo.ctaUrl)"
if ($promo.ctaUrl -notmatch '^https://') { Fail "ctaUrl must be https:// -- got: $($promo.ctaUrl)" }
Ok "  ctaUrl is HTTPS"

# -- 93. Record events --
function SendEvents($type, $count, $tok, $cid) {
    $events = @()
    for ($i = 0; $i -lt $count; $i++) {
        $events += [ordered]@{ campaignId = $cid; type = $type; occurredAtUtc = (Get-Date -Format "o") }
    }
    CallApi "POST" "/api/v1/promotions/events" @{ events = $events } $tok | Out-Null
}

Say "93. Send 25 impressions (cap=20) then 8 clicks (cap=5)"
SendEvents "Impression" 10 $userTok $campId; Ok "  Batch 1: 10 impressions"
SendEvents "Impression" 10 $userTok $campId; Ok "  Batch 2: 10 impressions (20 total)"
SendEvents "Impression"  5 $userTok $campId; Ok "  Batch 3: 5 impressions  (should be capped)"
SendEvents "Click"       5 $userTok $campId; Ok "  Batch 4: 5 clicks"
SendEvents "Click"       3 $userTok $campId; Ok "  Batch 5: 3 clicks       (should be capped)"

# -- 94. Check admin stats --
Say "94. Check today stats"
$stats     = CallApi "GET" "/api/v1/admin/promotions/campaigns/$campId/stats?from=$today&to=$today" $null $adminTok
$todayStat = $stats.data | Select-Object -First 1
if (-not $todayStat) { Fail "No stats for $today" }
$impressions = $todayStat.impressions
$clicks      = $todayStat.clicks
Ok "impressions=$impressions  clicks=$clicks"
if ($impressions -gt 20) { Fail "impressions=$impressions exceeds per-user cap of 20" }
if ($clicks -gt 5)       { Fail "clicks=$clicks exceeds per-user cap of 5" }
Ok "Per-user caps enforced"

# -- 95. End campaign, verify stops serving --
Say "95. End campaign"
CallApi "PUT" "/api/v1/admin/promotions/campaigns/$campId/status" @{ action = "End" } $adminTok | Out-Null
$afterEnd = CallApi "GET" "/api/v1/promotions?placement=HomeFeed" $null $userTok
if ($null -ne $afterEnd.data.promotion) { Fail "Expected null after Ended -- got: $($afterEnd.data | ConvertTo-Json)" }
Ok "promotion=null after campaign ended"

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  All API checks passed" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Campaign id: $campId"
Write-Host "Re-activate: PUT /api/v1/admin/promotions/campaigns/$campId/status  {action:Activate}"
Write-Host ""
Write-Host "APP CHECKLIST:"
Write-Host "  1. Home (free user, agriculture) -- SponsoredCard visible"
Write-Host "  2. Scroll out <50% then back in -- only ONE impression per mount"
Write-Host "  3. Tap Shop Now -- browser opens https://tata-agri.example.com/seeds"
Write-Host "  4. Background app -- logcat shows event queue flushed"
Write-Host "  5. Login as Pro user -- AdMob native ad (not SponsoredCard)"
