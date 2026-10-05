@echo off
REM MolBhav Progress Update Form
REM Opens browser form to update artifact

setlocal enabledelayedexpansion

REM Check if API key is set
if not defined CLAUDE_API_KEY (
    echo.
    echo ====== ERROR: API Key Not Set ======
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

REM Check if molbhav-form-server.js exists
if not exist "molbhav-form-server.js" (
    echo ====== ERROR: Server Script Not Found ======
    echo.
    echo molbhav-form-server.js should be in: %cd%
    echo.
    pause
    exit /b 1
)

REM Run the Node.js form server
echo.
echo ╔══════════════════════════════════════════════════════╗
echo ║     MolBhav Progress Update Form                      ║
echo ║     Form opens in browser automatically...            ║
echo ╚══════════════════════════════════════════════════════╝
echo.
echo 📝 Fill in metrics and click "Update Artifact"
echo 🔗 Your artifact will be updated automatically
echo 🛑 Press Ctrl+C in this window to stop
echo.

node molbhav-form-server.js

pause
