@echo off
REM OpenClaw Harmony Security Plugin Installation Script (Windows)

setlocal enabledelayedexpansion

echo.
echo ========================================
echo OpenClaw Harmony Security Plugin Installer
echo ========================================
echo.

REM Get script directory
set "SCRIPT_DIR=%~dp0"
set "PROJECT_DIR=%SCRIPT_DIR%.."

REM Convert to absolute path
for /f "delims=" %%i in ("%PROJECT_DIR%") do set "PROJECT_DIR=%%~fi"

echo Project Directory: %PROJECT_DIR%
echo.

REM Change to project directory
cd /d "%PROJECT_DIR%"

REM Install dependencies first
echo Installing dependencies...
call npm install
if errorlevel 1 (
    echo [ERROR] Failed to install dependencies
    pause
    exit /b 1
)
echo [OK] Dependencies installed
echo.

REM Check OpenClaw CLI
echo Checking OpenClaw CLI...
where openclaw >nul 2>&1
if errorlevel 1 (
    echo [ERROR] OpenClaw CLI not installed
    echo Please install: npm install -g @openclaw/cli
    pause
    exit /b 1
)
echo [OK] OpenClaw CLI installed
for /f "delims=" %%i in ('openclaw --version 2^>^&1') do set "OPENCLAW_VERSION=%%i"
echo    Version: %OPENCLAW_VERSION%
echo.

REM Build project
echo Building project...
call npm run build
if errorlevel 1 (
    echo [ERROR] Build failed
    pause
    exit /b 1
)
echo [OK] Build completed
echo.

REM Check plugin directory
set "PLUGIN_DIR=%PROJECT_DIR%\plugins\openclaw-harmony-security"
if not exist "%PLUGIN_DIR%" (
    echo [ERROR] Plugin directory not found: %PLUGIN_DIR%
    pause
    exit /b 1
)
echo Plugin Directory: %PLUGIN_DIR%

REM Check required files
if not exist "%PLUGIN_DIR%\index.js" (
    echo [ERROR] Plugin entry file missing: index.js
    pause
    exit /b 1
)
if not exist "%PLUGIN_DIR%\openclaw.plugin.json" (
    echo [ERROR] Plugin manifest missing: openclaw.plugin.json
    pause
    exit /b 1
)
echo [OK] Plugin files verified
echo.

REM Stop existing Gateway
echo Stopping existing Gateway (if running)...
call openclaw gateway stop >nul 2>&1
timeout /t 2 /nobreak >nul
echo.

REM Install plugin
echo Installing plugin...
call openclaw plugins install "%PLUGIN_DIR%"
echo.

REM Enable plugin
echo Enabling plugin...
call openclaw plugins enable harmony-security
echo.

REM Remove old plugin directory (if exists)
set "OLD_PLUGIN_DIR=%USERPROFILE%\.openclaw\extensions\openclaw-harmony-security"
if exist "%OLD_PLUGIN_DIR%" (
    echo Cleaning old plugin directory...
    rmdir /s /q "%OLD_PLUGIN_DIR%"
    echo [OK] Cleaned
)
echo.

REM Restart Gateway
echo Restarting Gateway...
start /b openclaw gateway > %TEMP%\openclaw-gateway.log 2>&1
timeout /t 5 /nobreak >nul
echo.

REM Verify installation
echo Verifying plugin installation...
call openclaw plugins list > %TEMP%\plugin-list.txt 2>&1
findstr /C:"harmony-security" %TEMP%\plugin-list.txt | findstr /C:"loaded" >nul
if errorlevel 1 (
    echo [WARNING] Plugin may not be loaded correctly
    echo Check log: type %TEMP%\openclaw-gateway.log
    echo.
    echo Manual verification:
    echo   openclaw plugins list
) else (
    echo [SUCCESS] Plugin installed successfully!
    echo.
    echo Plugin Status:
    findstr /C:"harmony-security" %TEMP%\plugin-list.txt | head -3
    echo.
    echo Usage:
    echo   1. Visit http://localhost:18789 for Gateway Control UI
    echo   2. Mention 'Task ID: XXXX' in conversation to trigger context injection
    echo   3. View log: type %TEMP%\openclaw-gateway.log
)
echo.

echo ========================================
echo Installation Complete!
echo.
pause
