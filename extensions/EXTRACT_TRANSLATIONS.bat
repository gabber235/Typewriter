@echo off
REM Extract and organize translations for all extensions

setlocal enabledelayedexpansion
set "EXT_DIR=C:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions"

echo.
echo =========================================================
echo Extracting translations for all 11 Typewriter extensions
echo =========================================================
echo.

cd /d "!EXT_DIR!" || exit /b 1

if not exist "setup_all_localizations.py" (
    echo ERROR: setup_all_localizations.py not found in !EXT_DIR!
    pause
    exit /b 1
)

echo Running Python extraction script...
echo This will extract @Entry annotations and generate translation files.
echo.

python setup_all_localizations.py

if errorlevel 1 (
    echo.
    echo WARNING: Script reported errors, but files may have been created.
)

echo.
echo =========================================================
echo Verifying translation files were created...
echo =========================================================
echo.

for %%E in (VaultExtension EntityExtension BasicExtension CitizensExtension QuestExtension WorldGuardExtension SuperiorSkyblockExtension RoadNetworkExtension RPGRegionsExtension MythicMobsExtension _DocsExtension) do (
    set "TRANS_DIR=!EXT_DIR!\%%E\src\main\resources\translations"
    if exist "!TRANS_DIR!" (
        echo ✓ %%E translations found
        dir "!TRANS_DIR!" /B
    ) else (
        echo ✗ %%E translations NOT found
    )
)

echo.
echo =========================================================
echo Translation extraction complete!
echo =========================================================
echo.
pause
