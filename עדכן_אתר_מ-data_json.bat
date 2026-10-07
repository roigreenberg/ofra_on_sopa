@echo off
chcp 65001 > nul
echo ======================================================
echo   מעדכן את index.html ישירות מתוך data.json...
echo ======================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0assemble_index.ps1"
echo.
echo ✓ הושלם בהצלחה! כעת ניתן לפתוח את index.html ולראות את כל השינויים.
echo.
pause
