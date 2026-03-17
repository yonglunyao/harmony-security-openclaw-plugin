@echo off
REM OpenClaw Harmony Security Plugin 一键安装脚本 (Windows)

setlocal enabledelayedexpansion

echo.
echo ========================================
echo 🦞 OpenClaw Harmony Security Plugin 安装脚本
echo ========================================
echo.

REM 获取脚本所在目录
set "SCRIPT_DIR=%~dp0"
set "PROJECT_DIR=%SCRIPT_DIR%.."

REM 转换路径为绝对路径
for /f "delims=" %%i in ("%PROJECT_DIR%") do set "PROJECT_DIR=%%~fi"

echo 📂 项目目录: %PROJECT_DIR%
echo.

REM 检查 OpenClaw CLI 是否安装
echo 🔍 检查 OpenClaw CLI...
where openclaw >nul 2>&1
if errorlevel 1 (
    echo [❌] OpenClaw CLI 未安装
    echo 请先安装: npm install -g @openclaw/cli
    pause
    exit /b 1
)
echo [✓] OpenClaw CLI 已安装
for /f "delims=" %%i in ('openclaw --version 2^>^&1') do set "OPENCLAW_VERSION=%%i"
echo    版本: %OPENCLAW_VERSION%
echo.

REM 构建项目
echo 🔨 构建项目...
cd /d "%PROJECT_DIR%"
call npm run build
if errorlevel 1 (
    echo [❌] 项目构建失败
    pause
    exit /b 1
)
echo [✓] 项目构建完成
echo.

REM 检查插件目录
set "PLUGIN_DIR=%PROJECT_DIR%\plugins\openclaw-harmony-security"
if not exist "%PLUGIN_DIR%" (
    echo [❌] 插件目录不存在: %PLUGIN_DIR%
    pause
    exit /b 1
)
echo 📦 插件目录: %PLUGIN_DIR%

REM 检查必需文件
if not exist "%PLUGIN_DIR%\index.js" (
    echo [❌] 插件入口文件缺失: index.js
    pause
    exit /b 1
)
if not exist "%PLUGIN_DIR%\openclaw.plugin.json" (
    echo [❌] 插件清单文件缺失: openclaw.plugin.json
    pause
    exit /b 1
)
echo [✓] 插件文件检查通过
echo.

REM 停止现有 Gateway
echo 🛑 停止现有 Gateway (如果正在运行)...
call openclaw gateway stop >nul 2>&1
timeout /t 2 /nobreak >nul
echo.

REM 安装插件
echo 🔌 安装插件...
call openclaw plugins install "%PLUGIN_DIR%"
echo.

REM 启用插件
echo ⚡ 启用插件...
call openclaw plugins enable harmony-security
echo.

REM 删除旧的插件目录（如果存在）
set "OLD_PLUGIN_DIR=%USERPROFILE%\.openclaw\extensions\openclaw-harmony-security"
if exist "%OLD_PLUGIN_DIR%" (
    echo 🧹 清理旧的插件目录...
    rmdir /s /q "%OLD_PLUGIN_DIR%"
    echo [✓] 已清理
)
echo.

REM 重启 Gateway
echo 🚀 重启 Gateway...
start /b openclaw gateway > %TEMP%\openclaw-gateway.log 2>&1
timeout /t 5 /nobreak >nul
echo.

REM 验证安装
echo 🔍 验证插件安装...
call openclaw plugins list > %TEMP%\plugin-list.txt 2>&1
findstr /C:"harmony-security" %TEMP%\plugin-list.txt | findstr /C:"loaded" >nul
if errorlevel 1 (
    echo [⚠️] 插件可能未正确加载
    echo 请检查日志: type %TEMP%\openclaw-gateway.log
    echo.
    echo 手动验证命令:
    echo   openclaw plugins list
) else (
    echo [✅] 插件安装成功！
    echo.
    echo 插件状态:
    findstr /C:"harmony-security" %TEMP%\plugin-list.txt | head -3
    echo.
    echo 📖 使用说明:
    echo   1. 访问 http://localhost:18789 查看 Gateway Control UI
    echo   2. 在对话中提及 '任务ID: XXXX' 即可触发上下文注入
    echo   3. 查看日志: type %TEMP%\openclaw-gateway.log
)
echo.

echo ========================================
echo 安装完成！
echo.
pause
