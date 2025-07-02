@echo off
cd /d C:\Users\spraydata
"C:\Program Files\MATLAB\R2022a\bin\matlab.exe" -noopengl -r "try; run('C:\Users\spraydata\Documents\GitHub\MBARIWireWalker\UpdateWWData.m'); catch; end; exit;"

echo Restarting WireDasher
echo Stopping any process using port 8050...

:: Find the PID using port 8050 and kill it
for /f "tokens=5" %%a in ('netstat -aon ^| find ":8050" ^| find "LISTENING"') do (
    echo Killing PID %%a
    taskkill /PID %%a /F
)

if "%PORT_FOUND%"=="false" (
    echo No process found using port 8050
)

:: Wait briefly to ensure clean shutdown
timeout /t 2 >nul

:: Start new Dash app
echo Starting WireWalker Dash app...
"C:\Users\spraydata\Documents\GitHub\PlotlyDashApps\.venv\Scripts\python.exe" "C:\Users\spraydata\Documents\GitHub\PlotlyDashApps\WireWalker.py"