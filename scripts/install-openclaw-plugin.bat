@echo off
REM OpenClaw Harmony Security Plugin Installation Script (Windows)
REM Calls Python script for cross-platform logic

setlocal enabledelayedexpansion

echo.
echo ========================================
echo OpenClaw Harmony Security Plugin Installer
echo     (Python Installation Script)
echo ========================================
echo.

REM Check if Python is available
where python >nul 2>&1
if errorlevel 1 (
    where python3 >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] Python not found
        echo Please install Python 3.6+ from https://python.org
        pause
        exit /b 1
    )
    set "PYTHON_CMD=python3"
) else (
    set "PYTHON_CMD=python"
)

echo [INFO] Using Python: %PYTHON_CMD%
%PYTHON_CMD% --version
echo.

REM Run Python installation script
%PYTHON_CMD% "%~dp0install.py"

REM Pause to show output
if errorlevel 1 (
    echo.
    echo [ERROR] Installation failed
    pause
    exit /b 1
)

echo.
pause
