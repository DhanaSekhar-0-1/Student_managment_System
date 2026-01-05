@echo off
title Attendance System Launcher

echo =====================================
echo   Starting Attendance System Servers
echo =====================================
echo.

REM ---- Main API Server ----
echo Starting Main API Server (Port 3000)...
start cmd /k "cd /d %~dp0 && echo Main API Server && node src\server.js"


timeout /t 2 /nobreak >nul

REM ---- NFC Bridge Server ----
echo Starting NFC Bridge Server (Port 3001)...
start cmd /k "cd /d %~dp0 && echo NFC Bridge Server && node nfc_bridge_server.js"

timeout /t 2 /nobreak >nul

REM ---- Static HTTP Server ----
echo Starting HTTP Server with CORS (Port 8080)...
start cmd /k "cd /d %~dp0 && echo HTTP Server && npx http-server -p 8080 --cors"

echo.
echo =====================================
echo   All servers started successfully!
echo =====================================
echo.
echo Press any key to close this launcher...
pause >nul
