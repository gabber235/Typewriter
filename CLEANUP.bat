@echo off
REM Cleanup temporary build files
REM Keep only: BUILD.py, build_clean.py, RUN_BUILD_NOW.bat

setlocal enabledelayedexpansion

echo.
echo ================================================================================
echo  Cleaning up temporary build files...
echo ================================================================================
echo.

set "ROOT=C:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter"
cd /d "%ROOT%"

REM Files to DELETE
set "DELETE_FILES=_run_final_setup.py _run_build.py verify_scripts.py verify_l10n.py validate_build.py test_build.py step1_freezed.py setup_l10n.py run_build.py regen_freezed.py quick_test.py move_translations.py move_l10n_to_resources.py move_l10n_files.py check_flutter.py exec_build.py build_master_new.py build_master.py build_direct.py launch_build.py generate_l10n_files.py final_setup.py check_syntax.py cleanup.py complete_l10n_setup.py"

REM Files to DELETE in extensions folder
set "DELETE_EXT_FILES=organize_l10n.py extract_l10n.py extract_entries.py extract_and_deploy_l10n.py move_localizations.py move_files.py run_l10n.py run_extraction.py generate_localizations.py generate_all_l10n.py extract_localizations.py"

echo Deleting temporary Python scripts from root...
for %%F in (%DELETE_FILES%) do (
    if exist "%%F" (
        del /Q "%%F"
        echo   ✓ Deleted %%F
    )
)

echo.
echo Deleting temporary scripts from extensions folder...
for %%F in (%DELETE_EXT_FILES%) do (
    if exist "extensions\%%F" (
        del /Q "extensions\%%F"
        echo   ✓ Deleted extensions\%%F
    )
)

REM Delete old batch files
echo.
echo Deleting old batch files...
if exist "BUILD_ALL.bat" (
    del /Q "BUILD_ALL.bat"
    echo   ✓ Deleted BUILD_ALL.bat
)
if exist "BUILD_FIXED.bat" (
    del /Q "BUILD_FIXED.bat"
    echo   ✓ Deleted BUILD_FIXED.bat
)
if exist "QUICK_BUILD.bat" (
    del /Q "QUICK_BUILD.bat"
    echo   ✓ Deleted QUICK_BUILD.bat
)
if exist "RUN_BUILD.bat" (
    del /Q "RUN_BUILD.bat"
    echo   ✓ Deleted RUN_BUILD.bat
)

REM Delete old .sh files
echo.
echo Deleting old shell scripts...
if exist "quickstart_l10n.sh" (
    del /Q "quickstart_l10n.sh"
    echo   ✓ Deleted quickstart_l10n.sh
)
if exist "setup_all_l10n.sh" (
    del /Q "setup_all_l10n.sh"
    echo   ✓ Deleted setup_all_l10n.sh
)
if exist "setup_l10n.sh" (
    del /Q "setup_l10n.sh"
    echo   ✓ Deleted setup_l10n.sh
)

REM Delete old documentation that was just for debugging
echo.
echo Deleting temporary documentation...
if exist "START_HERE.md" (
    del /Q "START_HERE.md"
    echo   ✓ Deleted START_HERE.md
)
if exist "QUICK_GUIDE.md" (
    del /Q "QUICK_GUIDE.md"
    echo   ✓ Deleted QUICK_GUIDE.md
)
if exist "QUICK_START.md" (
    del /Q "QUICK_START.md"
    echo   ✓ Deleted QUICK_START.md
)
if exist "READY_TO_BUILD.md" (
    del /Q "READY_TO_BUILD.md"
    echo   ✓ Deleted READY_TO_BUILD.md
)
if exist "READY_TO_BUILD_NOW.md" (
    del /Q "READY_TO_BUILD_NOW.md"
    echo   ✓ Deleted READY_TO_BUILD_NOW.md
)
if exist "FIXED_README.md" (
    del /Q "FIXED_README.md"
    echo   ✓ Deleted FIXED_README.md
)
if exist "DART_FIX.md" (
    del /Q "DART_FIX.md"
    echo   ✓ Deleted DART_FIX.md
)
if exist "DART_FIXES_COMPLETE.md" (
    del /Q "DART_FIXES_COMPLETE.md"
    echo   ✓ Deleted DART_FIXES_COMPLETE.md
)
if exist "FINAL_BUILD_GUIDE.md" (
    del /Q "FINAL_BUILD_GUIDE.md"
    echo   ✓ Deleted FINAL_BUILD_GUIDE.md
)
if exist "BUILD_READY_FINAL.md" (
    del /Q "BUILD_READY_FINAL.md"
    echo   ✓ Deleted BUILD_READY_FINAL.md
)
if exist "INDEX.md" (
    del /Q "INDEX.md"
    echo   ✓ Deleted INDEX.md
)
if exist "BUILD_INSTRUCTIONS.md" (
    del /Q "BUILD_INSTRUCTIONS.md"
    echo   ✓ Deleted BUILD_INSTRUCTIONS.md
)

echo.
echo ================================================================================
echo  Cleanup Complete!
echo ================================================================================
echo.
echo Remaining files:
echo   ✓ BUILD.py                      - Main build entry point
echo   ✓ build_clean.py                - Core build script
echo   ✓ RUN_BUILD_NOW.bat             - Windows wrapper
echo   ✓ BUILD_INSTRUCTIONS_FINAL.md   - Build documentation
echo.
echo All temporary files have been removed to keep the folder clean.
echo.
pause
