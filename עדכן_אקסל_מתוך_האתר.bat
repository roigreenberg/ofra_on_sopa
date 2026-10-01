@echo off
chcp 65001 > nul
echo ======================================================
echo   מרענן את קובץ האקסל (טקסטים_עפרה_על_הספה.csv) מתוך data.json
echo ======================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0sync_texts.ps1"
echo.
pause
