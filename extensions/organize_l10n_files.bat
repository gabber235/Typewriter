@echo off
REM Batch script to organize localization files
REM Move all *_l10n_*.json files from src\main\ to src\main\resources\translations\

setlocal enabledelayedexpansion

set BASE_DIR=c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions

echo Creating directory structure and organizing localization files...
echo.

REM Create directories for all extensions
for %%E in (VaultExtension,EntityExtension,BasicExtension,CitizensExtension,QuestExtension,WorldGuardExtension,SuperiorSkyblockExtension,RoadNetworkExtension,RPGRegionsExtension,MythicMobsExtension,_DocsExtension) do (
    set EXT_DIR=!BASE_DIR!\%%E
    set TRANS_DIR=!EXT_DIR!\src\main\resources\translations
    if not exist "!TRANS_DIR!" (
        mkdir "!TRANS_DIR!"
        echo Created: !TRANS_DIR!
    )
)

echo.
echo Moving localization files...
echo.

REM Move VaultExtension files
if exist "!BASE_DIR!\VaultExtension\src\main\vault_l10n_en.json" (
    move "!BASE_DIR!\VaultExtension\src\main\vault_l10n_en.json" "!BASE_DIR!\VaultExtension\src\main\resources\translations\vault_l10n_en.json"
    echo Moved: vault_l10n_en.json
)
if exist "!BASE_DIR!\VaultExtension\src\main\vault_l10n_ru.json" (
    move "!BASE_DIR!\VaultExtension\src\main\vault_l10n_ru.json" "!BASE_DIR!\VaultExtension\src\main\resources\translations\vault_l10n_ru.json"
    echo Moved: vault_l10n_ru.json
)

REM Move EntityExtension files
if exist "!BASE_DIR!\EntityExtension\src\main\entity_l10n_en.json" (
    move "!BASE_DIR!\EntityExtension\src\main\entity_l10n_en.json" "!BASE_DIR!\EntityExtension\src\main\resources\translations\entity_l10n_en.json"
    echo Moved: entity_l10n_en.json
)
if exist "!BASE_DIR!\EntityExtension\src\main\entity_l10n_ru.json" (
    move "!BASE_DIR!\EntityExtension\src\main\entity_l10n_ru.json" "!BASE_DIR!\EntityExtension\src\main\resources\translations\entity_l10n_ru.json"
    echo Moved: entity_l10n_ru.json
)

REM Move BasicExtension files
if exist "!BASE_DIR!\BasicExtension\src\main\basic_l10n_en.json" (
    move "!BASE_DIR!\BasicExtension\src\main\basic_l10n_en.json" "!BASE_DIR!\BasicExtension\src\main\resources\translations\basic_l10n_en.json"
    echo Moved: basic_l10n_en.json
)
if exist "!BASE_DIR!\BasicExtension\src\main\basic_l10n_ru.json" (
    move "!BASE_DIR!\BasicExtension\src\main\basic_l10n_ru.json" "!BASE_DIR!\BasicExtension\src\main\resources\translations\basic_l10n_ru.json"
    echo Moved: basic_l10n_ru.json
)

REM Move CitizensExtension files
if exist "!BASE_DIR!\CitizensExtension\src\main\citizens_l10n_en.json" (
    move "!BASE_DIR!\CitizensExtension\src\main\citizens_l10n_en.json" "!BASE_DIR!\CitizensExtension\src\main\resources\translations\citizens_l10n_en.json"
    echo Moved: citizens_l10n_en.json
)
if exist "!BASE_DIR!\CitizensExtension\src\main\citizens_l10n_ru.json" (
    move "!BASE_DIR!\CitizensExtension\src\main\citizens_l10n_ru.json" "!BASE_DIR!\CitizensExtension\src\main\resources\translations\citizens_l10n_ru.json"
    echo Moved: citizens_l10n_ru.json
)

REM Move QuestExtension files
if exist "!BASE_DIR!\QuestExtension\src\main\quest_l10n_en.json" (
    move "!BASE_DIR!\QuestExtension\src\main\quest_l10n_en.json" "!BASE_DIR!\QuestExtension\src\main\resources\translations\quest_l10n_en.json"
    echo Moved: quest_l10n_en.json
)
if exist "!BASE_DIR!\QuestExtension\src\main\quest_l10n_ru.json" (
    move "!BASE_DIR!\QuestExtension\src\main\quest_l10n_ru.json" "!BASE_DIR!\QuestExtension\src\main\resources\translations\quest_l10n_ru.json"
    echo Moved: quest_l10n_ru.json
)

REM Move WorldGuardExtension files
if exist "!BASE_DIR!\WorldGuardExtension\src\main\worldguard_l10n_en.json" (
    move "!BASE_DIR!\WorldGuardExtension\src\main\worldguard_l10n_en.json" "!BASE_DIR!\WorldGuardExtension\src\main\resources\translations\worldguard_l10n_en.json"
    echo Moved: worldguard_l10n_en.json
)
if exist "!BASE_DIR!\WorldGuardExtension\src\main\worldguard_l10n_ru.json" (
    move "!BASE_DIR!\WorldGuardExtension\src\main\worldguard_l10n_ru.json" "!BASE_DIR!\WorldGuardExtension\src\main\resources\translations\worldguard_l10n_ru.json"
    echo Moved: worldguard_l10n_ru.json
)

REM Move SuperiorSkyblockExtension files
if exist "!BASE_DIR!\SuperiorSkyblockExtension\src\main\superiorskyblock_l10n_en.json" (
    move "!BASE_DIR!\SuperiorSkyblockExtension\src\main\superiorskyblock_l10n_en.json" "!BASE_DIR!\SuperiorSkyblockExtension\src\main\resources\translations\superiorskyblock_l10n_en.json"
    echo Moved: superiorskyblock_l10n_en.json
)
if exist "!BASE_DIR!\SuperiorSkyblockExtension\src\main\superiorskyblock_l10n_ru.json" (
    move "!BASE_DIR!\SuperiorSkyblockExtension\src\main\superiorskyblock_l10n_ru.json" "!BASE_DIR!\SuperiorSkyblockExtension\src\main\resources\translations\superiorskyblock_l10n_ru.json"
    echo Moved: superiorskyblock_l10n_ru.json
)

REM Move RoadNetworkExtension files
if exist "!BASE_DIR!\RoadNetworkExtension\src\main\roadnetwork_l10n_en.json" (
    move "!BASE_DIR!\RoadNetworkExtension\src\main\roadnetwork_l10n_en.json" "!BASE_DIR!\RoadNetworkExtension\src\main\resources\translations\roadnetwork_l10n_en.json"
    echo Moved: roadnetwork_l10n_en.json
)
if exist "!BASE_DIR!\RoadNetworkExtension\src\main\roadnetwork_l10n_ru.json" (
    move "!BASE_DIR!\RoadNetworkExtension\src\main\roadnetwork_l10n_ru.json" "!BASE_DIR!\RoadNetworkExtension\src\main\resources\translations\roadnetwork_l10n_ru.json"
    echo Moved: roadnetwork_l10n_ru.json
)

REM Move RPGRegionsExtension files
if exist "!BASE_DIR!\RPGRegionsExtension\src\main\rpgregions_l10n_en.json" (
    move "!BASE_DIR!\RPGRegionsExtension\src\main\rpgregions_l10n_en.json" "!BASE_DIR!\RPGRegionsExtension\src\main\resources\translations\rpgregions_l10n_en.json"
    echo Moved: rpgregions_l10n_en.json
)
if exist "!BASE_DIR!\RPGRegionsExtension\src\main\rpgregions_l10n_ru.json" (
    move "!BASE_DIR!\RPGRegionsExtension\src\main\rpgregions_l10n_ru.json" "!BASE_DIR!\RPGRegionsExtension\src\main\resources\translations\rpgregions_l10n_ru.json"
    echo Moved: rpgregions_l10n_ru.json
)

REM Move MythicMobsExtension files
if exist "!BASE_DIR!\MythicMobsExtension\src\main\mythicmobs_l10n_en.json" (
    move "!BASE_DIR!\MythicMobsExtension\src\main\mythicmobs_l10n_en.json" "!BASE_DIR!\MythicMobsExtension\src\main\resources\translations\mythicmobs_l10n_en.json"
    echo Moved: mythicmobs_l10n_en.json
)
if exist "!BASE_DIR!\MythicMobsExtension\src\main\mythicmobs_l10n_ru.json" (
    move "!BASE_DIR!\MythicMobsExtension\src\main\mythicmobs_l10n_ru.json" "!BASE_DIR!\MythicMobsExtension\src\main\resources\translations\mythicmobs_l10n_ru.json"
    echo Moved: mythicmobs_l10n_ru.json
)

REM Move _DocsExtension files
if exist "!BASE_DIR!\_DocsExtension\src\main\docs_l10n_en.json" (
    move "!BASE_DIR!\_DocsExtension\src\main\docs_l10n_en.json" "!BASE_DIR!\_DocsExtension\src\main\resources\translations\docs_l10n_en.json"
    echo Moved: docs_l10n_en.json
)
if exist "!BASE_DIR!\_DocsExtension\src\main\docs_l10n_ru.json" (
    move "!BASE_DIR!\_DocsExtension\src\main\docs_l10n_ru.json" "!BASE_DIR!\_DocsExtension\src\main\resources\translations\docs_l10n_ru.json"
    echo Moved: docs_l10n_ru.json
)

REM Move root-level files if they exist
if exist "!BASE_DIR!\vault_l10n_en.json" (
    move "!BASE_DIR!\vault_l10n_en.json" "!BASE_DIR!\VaultExtension\src\main\resources\translations\vault_l10n_en.json"
    echo Moved: vault_l10n_en.json (from root)
)
if exist "!BASE_DIR!\vault_l10n_ru.json" (
    move "!BASE_DIR!\vault_l10n_ru.json" "!BASE_DIR!\VaultExtension\src\main\resources\translations\vault_l10n_ru.json"
    echo Moved: vault_l10n_ru.json (from root)
)

echo.
echo ====================================
echo ^✓ All localization files organized!
echo ====================================
echo.
echo Files have been moved to:
echo {ExtensionName}\src\main\resources\translations\
echo.
pause
