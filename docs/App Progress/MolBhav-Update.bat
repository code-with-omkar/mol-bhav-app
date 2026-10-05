@echo off
REM MolBhav Progress Artifact Updater - Windows Desktop Shortcut
REM This batch file reads molbhav_progress.md and updates the artifact

setlocal enabledelayedexpansion

REM Check if API key is set via Windows Environment Variables
if not defined CLAUDE_API_KEY (
    echo.
    echo ====== ERROR: API Key Not Found ======
    echo.
    echo Set CLAUDE_API_KEY via Windows Environment Variables:
    echo   1. Press Windows + X, select "System"
    echo   2. Click "Advanced system settings"
    echo   3. Click "Environment Variables"
    echo   4. Click "New" under User variables
    echo   5. Variable name: CLAUDE_API_KEY
    echo   6. Variable value: sk-ant-your-actual-key
    echo   7. Click OK and restart Command Prompt
    echo.
    pause
    exit /b 1
)

REM Get script directory
cd /d "%~dp0"

REM Check if Node.js is installed
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo ====== ERROR: Node.js Not Found ======
    echo.
    echo Install Node.js from: https://nodejs.org/
    echo Then run this batch file again
    echo.
    pause
    exit /b 1
)

REM Check if molbhav_progress.md exists
set progressFile=%USERPROFILE%\molbhav_progress.md
if not exist "!progressFile!" (
    echo ====== ERROR: Progress File Not Found ======
    echo.
    echo Expected: %USERPROFILE%\molbhav_progress.md
    echo.
    echo Create the file with progress metrics, then run again
    echo.
    pause
    exit /b 1
)

REM Run the Node.js script
echo.
echo ╔════════════════════════════════════════════════╗
echo ║    MolBhav Progress Artifact Updater            ║
echo ╚════════════════════════════════════════════════╝
echo.

node molbhav-update-artifact.js

echo.
pause