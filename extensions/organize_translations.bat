@echo off
REM Create translation directories and copy files for all extensions
REM This script organizes localization files into proper resource directories

setlocal enabledelayedexpansion

set "BASE_DIR=C:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions"

echo Creating translation directories...

REM Create directories for all extensions
for %%E in (VaultExtension EntityExtension BasicExtension CitizensExtension QuestExtension WorldGuardExtension SuperiorSkyblockExtension RoadNetworkExtension RPGRegionsExtension MythicMobsExtension _DocsExtension) do (
    set "TRANS_DIR=!BASE_DIR!\%%E\src\main\resources\translations"
    if not exist "!TRANS_DIR!" (
        echo Creating: !TRANS_DIR!
        md "!TRANS_DIR!"
    )
)

echo.
echo Moving localization files...

REM Move VaultExtension
echo Moving VaultExtension files...
move "!BASE_DIR!\VaultExtension\src\main\vault_l10n_en.json" "!BASE_DIR!\VaultExtension\src\main\resources\translations\vault_l10n_en.json" >nul 2>&1
move "!BASE_DIR!\VaultExtension\src\main\vault_l10n_ru.json" "!BASE_DIR!\VaultExtension\src\main\resources\translations\vault_l10n_ru.json" >nul 2>&1

REM Move EntityExtension  
echo Moving EntityExtension files...
move "!BASE_DIR!\EntityExtension\src\main\entity_l10n_en.json" "!BASE_DIR!\EntityExtension\src\main\resources\translations\entity_l10n_en.json" >nul 2>&1
move "!BASE_DIR!\EntityExtension\src\main\entity_l10n_ru.json" "!BASE_DIR!\EntityExtension\src\main\resources\translations\entity_l10n_ru.json" >nul 2>&1

REM Move BasicExtension
echo Moving BasicExtension files...
move "!BASE_DIR!\BasicExtension\src\main\basic_l10n_en.json" "!BASE_DIR!\BasicExtension\src\main\resources\translations\basic_l10n_en.json" >nul 2>&1
move "!BASE_DIR!\BasicExtension\src\main\basic_l10n_ru.json" "!BASE_DIR!\BasicExtension\src\main\resources\translations\basic_l10n_ru.json" >nul 2>&1

REM Move CitizensExtension
echo Moving CitizensExtension files...
move "!BASE_DIR!\CitizensExtension\src\main\citizens_l10n_en.json" "!BASE_DIR!\CitizensExtension\src\main\resources\translations\citizens_l10n_en.json" >nul 2>&1
move "!BASE_DIR!\CitizensExtension\src\main\citizens_l10n_ru.json" "!BASE_DIR!\CitizensExtension\src\main\resources\translations\citizens_l10n_ru.json" >nul 2>&1

REM Move QuestExtension
echo Moving QuestExtension files...
move "!BASE_DIR!\QuestExtension\src\main\quest_l10n_en.json" "!BASE_DIR!\QuestExtension\src\main\resources\translations\quest_l10n_en.json" >nul 2>&1
move "!BASE_DIR!\QuestExtension\src\main\quest_l10n_ru.json" "!BASE_DIR!\QuestExtension\src\main\resources\translations\quest_l10n_ru.json" >nul 2>&1

REM Move WorldGuardExtension
echo Moving WorldGuardExtension files...
move "!BASE_DIR!\WorldGuardExtension\src\main\worldguard_l10n_en.json" "!BASE_DIR!\WorldGuardExtension\src\main\resources\translations\worldguard_l10n_en.json" >nul 2>&1
move "!BASE_DIR!\WorldGuardExtension\src\main\worldguard_l10n_ru.json" "!BASE_DIR!\WorldGuardExtension\src\main\resources\translations\worldguard_l10n_ru.json" >nul 2>&1

REM Move SuperiorSkyblockExtension
echo Moving SuperiorSkyblockExtension files...
move "!BASE_DIR!\SuperiorSkyblockExtension\src\main\superiorskyblock_l10n_en.json" "!BASE_DIR!\SuperiorSkyblockExtension\src\main\resources\translations\superiorskyblock_l10n_en.json" >nul 2>&1
move "!BASE_DIR!\SuperiorSkyblockExtension\src\main\superiorskyblock_l10n_ru.json" "!BASE_DIR!\SuperiorSkyblockExtension\src\main\resources\translations\superiorskyblock_l10n_ru.json" >nul 2>&1

REM Move RoadNetworkExtension
echo Moving RoadNetworkExtension files...
move "!BASE_DIR!\RoadNetworkExtension\src\main\roadnetwork_l10n_en.json" "!BASE_DIR!\RoadNetworkExtension\src\main\resources\translations\roadnetwork_l10n_en.json" >nul 2>&1
move "!BASE_DIR!\RoadNetworkExtension\src\main\roadnetwork_l10n_ru.json" "!BASE_DIR!\RoadNetworkExtension\src\main\resources\translations\roadnetwork_l10n_ru.json" >nul 2>&1

REM Move RPGRegionsExtension
echo Moving RPGRegionsExtension files...
move "!BASE_DIR!\RPGRegionsExtension\src\main\rpgregions_l10n_en.json" "!BASE_DIR!\RPGRegionsExtension\src\main\resources\translations\rpgregions_l10n_en.json" >nul 2>&1
move "!BASE_DIR!\RPGRegionsExtension\src\main\rpgregions_l10n_ru.json" "!BASE_DIR!\RPGRegionsExtension\src\main\resources\translations\rpgregions_l10n_ru.json" >nul 2>&1

REM Move MythicMobsExtension
echo Moving MythicMobsExtension files...
move "!BASE_DIR!\MythicMobsExtension\src\main\mythicmobs_l10n_en.json" "!BASE_DIR!\MythicMobsExtension\src\main\resources\translations\mythicmobs_l10n_en.json" >nul 2>&1
move "!BASE_DIR!\MythicMobsExtension\src\main\mythicmobs_l10n_ru.json" "!BASE_DIR!\MythicMobsExtension\src\main\resources\translations\mythicmobs_l10n_ru.json" >nul 2>&1

REM Move _DocsExtension
echo Moving _DocsExtension files...
move "!BASE_DIR!\_DocsExtension\src\main\docs_l10n_en.json" "!BASE_DIR!\_DocsExtension\src\main\resources\translations\docs_l10n_en.json" >nul 2>&1
move "!BASE_DIR!\_DocsExtension\src\main\docs_l10n_ru.json" "!BASE_DIR!\_DocsExtension\src\main\resources\translations\docs_l10n_ru.json" >nul 2>&1

echo.
echo ✓ All localization files organized!
echo.
echo Verifying files in correct locations...

REM Verify files
set "FOUND=0"
for /r "!BASE_DIR!" %%F in (*_l10n_*.json) do (
    if "%%~dpF" == "!BASE_DIR!\resources\translations\" (
        set /a FOUND+=1
    )
)

echo Localization files found in correct locations: !FOUND!
echo.
echo Done!
pause
