@echo off
REM ==========================================
REM WidwaPa EA Installer - Batch Script
REM ==========================================

setlocal enabledelayedexpansion

REM Colors (for Windows 10+)
set "GREEN=[92m"
set "CYAN=[96m"
set "YELLOW=[93m"
set "RED=[91m"
set "RESET=[0m"

echo %CYAN%=========================================%RESET%
echo %CYAN%WidwaPa EA Installer%RESET%
echo %CYAN%=========================================%RESET%
echo.

REM Get script directory
set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%.."

REM Source paths
set "SOURCE_EXPERTS=%PROJECT_ROOT%\MQL5\Experts\EA_Helper"
set "SOURCE_INCLUDE=%PROJECT_ROOT%\MQL5\Include\EA_Helper"

echo %CYAN%Detecting MetaTrader 5 installation...%RESET%

REM Try to find MT5 data folder
set "MT5_PATH="
for /f "delims=" %%i in ('dir "%APPDATA%\MetaQuotes\Terminal" /b /ad 2^>nul') do (
    if exist "%APPDATA%\MetaQuotes\Terminal\%%i\MQL5" (
        set "MT5_PATH=%APPDATA%\MetaQuotes\Terminal\%%i\MQL5"
        goto :found
    )
)

REM Try LOCALAPPDATA
for /f "delims=" %%i in ('dir "%LOCALAPPDATA%\MetaQuotes\Terminal" /b /ad 2^>nul') do (
    if exist "%LOCALAPPDATA%\MetaQuotes\Terminal\%%i\MQL5" (
        set "MT5_PATH=%LOCALAPPDATA%\MetaQuotes\Terminal\%%i\MQL5"
        goto :found
    )
)

echo %YELLOW%Could not auto-detect MT5 folder.%RESET%
echo %YELLOW%Please enter MT5 MQL5 path manually:%RESET%
echo.
set /p "MT5_PATH=MT5 MQL5 Path: "
if not exist "%MT5_PATH%" (
    echo %RED%Error: Path does not exist: %MT5_PATH%%RESET%
    pause
    exit /b 1
)

:found
echo %GREEN%Found MT5 folder: %MT5_PATH%%RESET%

REM Destination paths
set "DEST_EXPERTS=%MT5_PATH%\Experts\EA_Helper"
set "DEST_INCLUDE=%MT5_PATH%\Include\EA_Helper"

echo.
echo %CYAN%Creating target directories...%RESET%
if not exist "%DEST_EXPERTS%" mkdir "%DEST_EXPERTS%"
if not exist "%DEST_INCLUDE%" mkdir "%DEST_INCLUDE%"

REM Copy Expert files
echo.
echo %CYAN%Copying Expert Advisor files...%RESET%
copy /Y "%SOURCE_EXPERTS%\*.mq5" "%DEST_EXPERTS%\" >nul
if %ERRORLEVEL% EQU 0 (
    echo   WidwaPa_Assistant.mq5 -^> EA_Helper\
    echo %GREEN%OK%RESET%
) else (
    echo   %RED%Failed to copy expert files%RESET%
)

REM Copy Include files
echo.
echo %CYAN%Copying Include files...%RESET%
copy /Y "%SOURCE_INCLUDE%\*.mqh" "%DEST_INCLUDE%\" >nul
if %ERRORLEVEL% EQU 0 (
    echo   Definitions.mqh -^> Include\EA_Helper\
    echo   SignalEngine.mqh -^> Include\EA_Helper\
    echo   TradeManager.mqh -^> Include\EA_Helper\
    echo   DashboardPanel.mqh -^> Include\EA_Helper\
    echo %GREEN%OK%RESET%
) else (
    echo   %RED%Failed to copy include files%RESET%
)

REM Summary
echo.
echo %GREEN%=========================================%RESET%
echo %GREEN%Installation Complete!%RESET%
echo %GREEN%=========================================%RESET%
echo.
echo %CYAN%Files copied to:%RESET%
echo   Experts:  %DEST_EXPERTS%
echo   Include:  %DEST_INCLUDE%
echo.
echo %CYAN%Next Steps:%RESET%
echo   1. Open MetaTrader 5
echo   2. Press F4 (MetaEditor)
echo   3. Navigate to Experts -^> EA_Helper -^> WidwaPa_Assistant.mq5
echo   4. Press F7 to Compile
echo   5. Press Ctrl+R to open Strategy Tester
echo   6. Select WidwaPa_Assistant, XAUUSD, H1 timeframe
echo   7. Check 'Visual Mode' and click Start
echo.

REM Ask to open MetaEditor
set /p "OPEN_ME=Open MetaEditor now? (Y/N): "
if /i "%OPEN_ME%"=="Y" (
    for %%f in ("%MT5_PATH%\..") do set "MT5_ROOT=%%~sf"
    if exist "%MT5_ROOT%\metaeditor64.exe" (
        start "" "%MT5_ROOT%\metaeditor64.exe"
        echo %GREEN%MetaEditor opened!%RESET%
    ) else if exist "%MT5_ROOT%\metaeditor.exe" (
        start "" "%MT5_ROOT%\metaeditor.exe"
        echo %GREEN%MetaEditor opened!%RESET%
    ) else (
        echo %YELLOW%Could not find MetaEditor executable%RESET%
    )
)

pause
