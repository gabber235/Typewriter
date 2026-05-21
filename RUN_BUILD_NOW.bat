@echo off
REM Build script for Typewriter with proper Python UTF-8 handling
setlocal enabledelayedexpansion

set "PYTHONIOENCODING=utf-8"
set "ROOT=C:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter"

echo.
echo ================================================================================
echo  TYPEWRITER FULL BUILD PIPELINE
echo ================================================================================
echo.

cd /d "%ROOT%"
python BUILD.py

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ================================================================================
    echo  BUILD FAILED - Check output above for details
    echo ================================================================================
    pause
    exit /b 1
)

echo.
echo ================================================================================
echo  BUILD COMPLETED SUCCESSFULLY
echo ================================================================================
echo.
echo Generated artifacts:
echo   - Plugin JAR: %ROOT%\build\libs\
echo   - Web App:    %ROOT%\app\build\web\
echo   - Extensions: %ROOT%\extensions\*Extension\build\libs\
echo.
pause
