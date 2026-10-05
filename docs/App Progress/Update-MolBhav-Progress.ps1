# MolBhav Progress Updater
# Windows PowerShell script to read markdown progress file and update artifact
# Usage: Right-click -> "Run with PowerShell"

param(
    [string]$ProgressFile = "$env:USERPROFILE\molbhav_progress.md"
)

# Configuration
$ArtifactUrl = "https://claude.ai/artifact/5pBWjwWkcHJ8Mj9pzgyGQ9"

# Check if progress file exists
if (-not (Test-Path $ProgressFile)) {
    Write-Error "Progress file not found: $ProgressFile"
    Write-Host "Create one at: $ProgressFile"
    Write-Host ""
    pause
    exit 1
}

# Read markdown file
$content = Get-Content $ProgressFile -Raw

# Extract progress data using regex
$apiProgress = if ($content -match "API.*?\*\*Completion:\*\*\s+(\d+)%") { $matches[1] } else { "?" }
$appProgress = if ($content -match "App.*?\*\*Completion:\*\*\s+(\d+)%") { $matches[1] } else { "?" }
$migrationsMatch = if ($content -match "Migrations Completed:\*\*\s+(\d+)/(\d+)") { @($matches[1], $matches[2]) } else { @("?", "?") }
$lastUpdated = if ($content -match "Last Updated:\*\*\s+(.+)") { $matches[1] } else { "Unknown" }

# Extract blockers
$blockers = @()
$content -split "`n" | Where-Object { $_ -match "^\d+\.\s+\*\*(.+?)\*\*" } | ForEach-Object {
    if ($_ -match "^\d+\.\s+\*\*(.+?)\*\*\s+-\s+(.+)$") {
        $blockers += @{ title = $matches[1]; desc = $matches[2] }
    }
}

# Display summary
$summary = @"
╔════════════════════════════════════════════════════════════════╗
║            MolBhav Progress Update                              ║
╚════════════════════════════════════════════════════════════════╝

📊 METRICS
  API:         $apiProgress%
  App:         $appProgress%
  Migrations:  $($migrationsMatch[0])/$($migrationsMatch[1])

📅 Updated: $lastUpdated

⚠️  OPEN BLOCKERS ($($blockers.Count))
$($blockers | ForEach-Object { "  • $($_.title)" })

🔗 Artifact: $ArtifactUrl
"@

Write-Host $summary -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ Opening artifact in browser..." -ForegroundColor Green

# Open artifact in default browser
Start-Process $ArtifactUrl

# Show progress file path for reference
Write-Host ""
Write-Host "📝 Progress file: $ProgressFile" -ForegroundColor Gray
Write-Host ""
Write-Host "💡 Next steps:" -ForegroundColor Yellow
Write-Host "   1. Review the artifact at: $ArtifactUrl"
Write-Host "   2. Update the progress metrics there manually"
Write-Host "   3. Next time, edit: $ProgressFile"
Write-Host "   4. Run this script again"
Write-Host ""

pause
