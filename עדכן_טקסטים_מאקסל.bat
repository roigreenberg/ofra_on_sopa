@echo off
chcp 65001 > nul
echo ======================================================
echo   מעדכן את האתר מתוך קובץ האקסל (טקסטים_עפרה_על_הספה.csv)
echo ======================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0sync_texts.ps1" -FromCsv
echo.
pause
