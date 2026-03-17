@echo off
REM OpenClaw Harmony Security Plugin Installation Script (Windows)
REM Includes MCP Adapter integration

setlocal enabledelayedexpansion

echo.
echo ========================================
echo OpenClaw Harmony Security Plugin Installer
echo     (with MCP Adapter Integration)
echo ========================================
echo.

REM Get script directory
set "SCRIPT_DIR=%~dp0"
set "PROJECT_DIR=%SCRIPT_DIR%.."
set "MCP_ADAPTER_DIR=%PROJECT_DIR%\..\openclaw-mcp-adapter"

REM Convert to absolute path
for /f "delims=" %%i in ("%PROJECT_DIR%") do set "PROJECT_DIR=%%~fi"

echo Project Directory: %PROJECT_DIR%
echo.

REM Change to project directory
cd /d "%PROJECT_DIR%"

REM Install dependencies
echo [1/7] Installing dependencies...
call npm install
if errorlevel 1 (
    echo [ERROR] Failed to install dependencies
    pause
    exit /b 1
)
echo [OK] Dependencies installed
echo.

REM Build project
echo [2/7] Building project...
call npm run build
if errorlevel 1 (
    echo [ERROR] Build failed
    pause
    exit /b 1
)
echo [OK] Build completed
echo.

REM Create data directories
echo [3/7] Creating data directories...
if not exist "%PROJECT_DIR%\data\samples" mkdir "%PROJECT_DIR%\data\samples"
if not exist "%PROJECT_DIR%\data\knowledge" mkdir "%PROJECT_DIR%\data\knowledge"
if not exist "%PROJECT_DIR%\data\reports" mkdir "%PROJECT_DIR%\data\reports"
echo [OK] Data directories created
echo.

REM Check/clone MCP Adapter
echo [4/7] Checking MCP Adapter...
if not exist "%MCP_ADAPTER_DIR%" (
    echo MCP Adapter not found, cloning...
    cd /d "%PROJECT_DIR%\.."
    git clone https://github.com/androidStern-personal/openclaw-mcp-adapter.git
    echo [OK] MCP Adapter cloned
) else (
    echo [OK] MCP Adapter exists
)
echo.

REM Check OpenClaw CLI
echo [5/7] Checking OpenClaw CLI...
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

REM Check plugin directory
set "PLUGIN_DIR=%PROJECT_DIR%\plugins\openclaw-harmony-security"
if not exist "%PLUGIN_DIR%" (
    echo [ERROR] Plugin directory not found: %PLUGIN_DIR%
    pause
    exit /b 1
)

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
echo [6/7] Stopping existing Gateway (if running)...
call openclaw gateway stop >nul 2>&1
timeout /t 2 /nobreak >nul
echo.

REM Install plugins
echo Installing plugins...
echo   - harmony-security plugin...
call openclaw plugins install "%PLUGIN_DIR%" >nul 2>&1
call openclaw plugins enable harmony-security >nul 2>&1
echo   [OK] harmony-security enabled

echo   - mcp-adapter plugin...
call openclaw plugins install "%MCP_ADAPTER_DIR%" >nul 2>&1
echo   [OK] mcp-adapter installed
echo.

REM Configure MCP Servers
echo Configuring MCP Servers...
echo Please add the following to your OpenClaw config (~\.openclaw\openclaw.json):
echo.
echo   "openclaw-mcp-adapter": {
echo     "enabled": true,
echo     "config": {
echo       "servers": [
echo         {
echo           "name": "sample-store",
echo           "transport": "stdio",
echo           "command": "node",
echo           "args": ["D:/workspace/harmony-analyse-system/dist/mcp/sample-store/index.js"],
echo           "env": {"SAMPLE_STORE_PATH": "D:/workspace/harmony-analyse-system/data/samples"}
echo         },
echo         {
echo           "name": "knowledge-base",
echo           "transport": "stdio",
echo           "command": "node",
echo           "args": ["D:/workspace/harmony-analyse-system/dist/mcp/knowledge-base/index.js"],
echo           "env": {"KNOWLEDGE_BASE_PATH": "D:/workspace/harmony-analyse-system/data/knowledge"}
echo         },
echo         {
echo           "name": "report-store",
echo           "transport": "stdio",
echo           "command": "node",
echo           "args": ["D:/workspace/harmony-analyse-system/dist/mcp/report-store/index.js"],
echo           "env": {"REPORT_OUTPUT_PATH": "D:/workspace/harmony-analyse-system/data/reports"}
echo         }
echo       ]
echo     }
echo   }
echo.
echo Press any key when you have added the configuration...
pause >nul
echo [OK] MCP Servers configured
echo.

REM Restart Gateway
echo [7/7] Restarting Gateway...
start /b openclaw gateway > %TEMP%\openclaw-gateway.log 2>&1
timeout /t 5 /nobreak >nul
echo.

REM Verify installation
echo Verifying installation...
call openclaw plugins list > %TEMP%\plugin-list.txt 2>&1

echo.
echo Plugin Status:
echo.
findstr /C:"HarmonyOS" %TEMP%\plugin-list.txt
echo.
findstr /C:"MCP Adapter" %TEMP%\plugin-list.txt
echo.

echo ========================================
echo Installation Complete!
echo.
echo MCP Tools Available:
echo   - sample-store (6 tools): get_sample_info, get_code_tree, etc.
echo   - knowledge-base (1 tool): query_hatl
echo   - report-store (2 tools): save_report, get_report
echo.
echo Usage:
echo   1. Visit http://localhost:18789 for Gateway Control UI
echo   2. Agent can now call MCP tools directly
echo   3. View log: type %TEMP%\openclaw-gateway.log
echo.
pause
