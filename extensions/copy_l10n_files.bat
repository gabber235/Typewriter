@echo off
setlocal enabledelayedexpansion
cd /d "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions"

echo Step 1: Creating directories...
echo.

if not exist "VaultExtension\src\main\resources\translations" mkdir "VaultExtension\src\main\resources\translations"
if not exist "EntityExtension\src\main\resources\translations" mkdir "EntityExtension\src\main\resources\translations"
if not exist "BasicExtension\src\main\resources\translations" mkdir "BasicExtension\src\main\resources\translations"
if not exist "CitizensExtension\src\main\resources\translations" mkdir "CitizensExtension\src\main\resources\translations"
if not exist "QuestExtension\src\main\resources\translations" mkdir "QuestExtension\src\main\resources\translations"
if not exist "WorldGuardExtension\src\main\resources\translations" mkdir "WorldGuardExtension\src\main\resources\translations"
if not exist "SuperiorSkyblockExtension\src\main\resources\translations" mkdir "SuperiorSkyblockExtension\src\main\resources\translations"
if not exist "RoadNetworkExtension\src\main\resources\translations" mkdir "RoadNetworkExtension\src\main\resources\translations"
if not exist "RPGRegionsExtension\src\main\resources\translations" mkdir "RPGRegionsExtension\src\main\resources\translations"
if not exist "MythicMobsExtension\src\main\resources\translations" mkdir "MythicMobsExtension\src\main\resources\translations"
if not exist "_DocsExtension\src\main\resources\translations" mkdir "_DocsExtension\src\main\resources\translations"

echo Directories created.
echo.
echo Step 2: Copying files...
echo.

if exist "VaultExtension\src\main\vault_l10n_en.json" copy "VaultExtension\src\main\vault_l10n_en.json" "VaultExtension\src\main\resources\translations\" >nul && echo [OK] VaultExtension\vault_l10n_en.json || echo [MISSING] VaultExtension\vault_l10n_en.json
if exist "VaultExtension\src\main\vault_l10n_ru.json" copy "VaultExtension\src\main\vault_l10n_ru.json" "VaultExtension\src\main\resources\translations\" >nul && echo [OK] VaultExtension\vault_l10n_ru.json || echo [MISSING] VaultExtension\vault_l10n_ru.json

if exist "EntityExtension\src\main\entity_l10n_en.json" copy "EntityExtension\src\main\entity_l10n_en.json" "EntityExtension\src\main\resources\translations\" >nul && echo [OK] EntityExtension\entity_l10n_en.json || echo [MISSING] EntityExtension\entity_l10n_en.json
if exist "EntityExtension\src\main\entity_l10n_ru.json" copy "EntityExtension\src\main\entity_l10n_ru.json" "EntityExtension\src\main\resources\translations\" >nul && echo [OK] EntityExtension\entity_l10n_ru.json || echo [MISSING] EntityExtension\entity_l10n_ru.json

if exist "BasicExtension\src\main\basic_l10n_en.json" copy "BasicExtension\src\main\basic_l10n_en.json" "BasicExtension\src\main\resources\translations\" >nul && echo [OK] BasicExtension\basic_l10n_en.json || echo [MISSING] BasicExtension\basic_l10n_en.json
if exist "BasicExtension\src\main\basic_l10n_ru.json" copy "BasicExtension\src\main\basic_l10n_ru.json" "BasicExtension\src\main\resources\translations\" >nul && echo [OK] BasicExtension\basic_l10n_ru.json || echo [MISSING] BasicExtension\basic_l10n_ru.json

if exist "CitizensExtension\src\main\citizens_l10n_en.json" copy "CitizensExtension\src\main\citizens_l10n_en.json" "CitizensExtension\src\main\resources\translations\" >nul && echo [OK] CitizensExtension\citizens_l10n_en.json || echo [MISSING] CitizensExtension\citizens_l10n_en.json
if exist "CitizensExtension\src\main\citizens_l10n_ru.json" copy "CitizensExtension\src\main\citizens_l10n_ru.json" "CitizensExtension\src\main\resources\translations\" >nul && echo [OK] CitizensExtension\citizens_l10n_ru.json || echo [MISSING] CitizensExtension\citizens_l10n_ru.json

if exist "QuestExtension\src\main\quest_l10n_en.json" copy "QuestExtension\src\main\quest_l10n_en.json" "QuestExtension\src\main\resources\translations\" >nul && echo [OK] QuestExtension\quest_l10n_en.json || echo [MISSING] QuestExtension\quest_l10n_en.json
if exist "QuestExtension\src\main\quest_l10n_ru.json" copy "QuestExtension\src\main\quest_l10n_ru.json" "QuestExtension\src\main\resources\translations\" >nul && echo [OK] QuestExtension\quest_l10n_ru.json || echo [MISSING] QuestExtension\quest_l10n_ru.json

if exist "WorldGuardExtension\src\main\worldguard_l10n_en.json" copy "WorldGuardExtension\src\main\worldguard_l10n_en.json" "WorldGuardExtension\src\main\resources\translations\" >nul && echo [OK] WorldGuardExtension\worldguard_l10n_en.json || echo [MISSING] WorldGuardExtension\worldguard_l10n_en.json
if exist "WorldGuardExtension\src\main\worldguard_l10n_ru.json" copy "WorldGuardExtension\src\main\worldguard_l10n_ru.json" "WorldGuardExtension\src\main\resources\translations\" >nul && echo [OK] WorldGuardExtension\worldguard_l10n_ru.json || echo [MISSING] WorldGuardExtension\worldguard_l10n_ru.json

if exist "SuperiorSkyblockExtension\src\main\superiorskyblock_l10n_en.json" copy "SuperiorSkyblockExtension\src\main\superiorskyblock_l10n_en.json" "SuperiorSkyblockExtension\src\main\resources\translations\" >nul && echo [OK] SuperiorSkyblockExtension\superiorskyblock_l10n_en.json || echo [MISSING] SuperiorSkyblockExtension\superiorskyblock_l10n_en.json
if exist "SuperiorSkyblockExtension\src\main\superiorskyblock_l10n_ru.json" copy "SuperiorSkyblockExtension\src\main\superiorskyblock_l10n_ru.json" "SuperiorSkyblockExtension\src\main\resources\translations\" >nul && echo [OK] SuperiorSkyblockExtension\superiorskyblock_l10n_ru.json || echo [MISSING] SuperiorSkyblockExtension\superiorskyblock_l10n_ru.json

if exist "RoadNetworkExtension\src\main\roadnetwork_l10n_en.json" copy "RoadNetworkExtension\src\main\roadnetwork_l10n_en.json" "RoadNetworkExtension\src\main\resources\translations\" >nul && echo [OK] RoadNetworkExtension\roadnetwork_l10n_en.json || echo [MISSING] RoadNetworkExtension\roadnetwork_l10n_en.json
if exist "RoadNetworkExtension\src\main\roadnetwork_l10n_ru.json" copy "RoadNetworkExtension\src\main\roadnetwork_l10n_ru.json" "RoadNetworkExtension\src\main\resources\translations\" >nul && echo [OK] RoadNetworkExtension\roadnetwork_l10n_ru.json || echo [MISSING] RoadNetworkExtension\roadnetwork_l10n_ru.json

if exist "RPGRegionsExtension\src\main\rpgregions_l10n_en.json" copy "RPGRegionsExtension\src\main\rpgregions_l10n_en.json" "RPGRegionsExtension\src\main\resources\translations\" >nul && echo [OK] RPGRegionsExtension\rpgregions_l10n_en.json || echo [MISSING] RPGRegionsExtension\rpgregions_l10n_en.json
if exist "RPGRegionsExtension\src\main\rpgregions_l10n_ru.json" copy "RPGRegionsExtension\src\main\rpgregions_l10n_ru.json" "RPGRegionsExtension\src\main\resources\translations\" >nul && echo [OK] RPGRegionsExtension\rpgregions_l10n_ru.json || echo [MISSING] RPGRegionsExtension\rpgregions_l10n_ru.json

if exist "MythicMobsExtension\src\main\mythicmobs_l10n_en.json" copy "MythicMobsExtension\src\main\mythicmobs_l10n_en.json" "MythicMobsExtension\src\main\resources\translations\" >nul && echo [OK] MythicMobsExtension\mythicmobs_l10n_en.json || echo [MISSING] MythicMobsExtension\mythicmobs_l10n_en.json
if exist "MythicMobsExtension\src\main\mythicmobs_l10n_ru.json" copy "MythicMobsExtension\src\main\mythicmobs_l10n_ru.json" "MythicMobsExtension\src\main\resources\translations\" >nul && echo [OK] MythicMobsExtension\mythicmobs_l10n_ru.json || echo [MISSING] MythicMobsExtension\mythicmobs_l10n_ru.json

if exist "_DocsExtension\src\main\docs_l10n_en.json" copy "_DocsExtension\src\main\docs_l10n_en.json" "_DocsExtension\src\main\resources\translations\" >nul && echo [OK] _DocsExtension\docs_l10n_en.json || echo [MISSING] _DocsExtension\docs_l10n_en.json
if exist "_DocsExtension\src\main\docs_l10n_ru.json" copy "_DocsExtension\src\main\docs_l10n_ru.json" "_DocsExtension\src\main\resources\translations\" >nul && echo [OK] _DocsExtension\docs_l10n_ru.json || echo [MISSING] _DocsExtension\docs_l10n_ru.json

echo.
echo Step 3: Verifying files...
echo.

setlocal enabledelayedexpansion
set count=0

if exist "VaultExtension\src\main\resources\translations\vault_l10n_en.json" (set /a count+=1) else echo [MISSING] VaultExtension\src\main\resources\translations\vault_l10n_en.json
if exist "VaultExtension\src\main\resources\translations\vault_l10n_ru.json" (set /a count+=1) else echo [MISSING] VaultExtension\src\main\resources\translations\vault_l10n_ru.json

if exist "EntityExtension\src\main\resources\translations\entity_l10n_en.json" (set /a count+=1) else echo [MISSING] EntityExtension\src\main\resources\translations\entity_l10n_en.json
if exist "EntityExtension\src\main\resources\translations\entity_l10n_ru.json" (set /a count+=1) else echo [MISSING] EntityExtension\src\main\resources\translations\entity_l10n_ru.json

if exist "BasicExtension\src\main\resources\translations\basic_l10n_en.json" (set /a count+=1) else echo [MISSING] BasicExtension\src\main\resources\translations\basic_l10n_en.json
if exist "BasicExtension\src\main\resources\translations\basic_l10n_ru.json" (set /a count+=1) else echo [MISSING] BasicExtension\src\main\resources\translations\basic_l10n_ru.json

if exist "CitizensExtension\src\main\resources\translations\citizens_l10n_en.json" (set /a count+=1) else echo [MISSING] CitizensExtension\src\main\resources\translations\citizens_l10n_en.json
if exist "CitizensExtension\src\main\resources\translations\citizens_l10n_ru.json" (set /a count+=1) else echo [MISSING] CitizensExtension\src\main\resources\translations\citizens_l10n_ru.json

if exist "QuestExtension\src\main\resources\translations\quest_l10n_en.json" (set /a count+=1) else echo [MISSING] QuestExtension\src\main\resources\translations\quest_l10n_en.json
if exist "QuestExtension\src\main\resources\translations\quest_l10n_ru.json" (set /a count+=1) else echo [MISSING] QuestExtension\src\main\resources\translations\quest_l10n_ru.json

if exist "WorldGuardExtension\src\main\resources\translations\worldguard_l10n_en.json" (set /a count+=1) else echo [MISSING] WorldGuardExtension\src\main\resources\translations\worldguard_l10n_en.json
if exist "WorldGuardExtension\src\main\resources\translations\worldguard_l10n_ru.json" (set /a count+=1) else echo [MISSING] WorldGuardExtension\src\main\resources\translations\worldguard_l10n_ru.json

if exist "SuperiorSkyblockExtension\src\main\resources\translations\superiorskyblock_l10n_en.json" (set /a count+=1) else echo [MISSING] SuperiorSkyblockExtension\src\main\resources\translations\superiorskyblock_l10n_en.json
if exist "SuperiorSkyblockExtension\src\main\resources\translations\superiorskyblock_l10n_ru.json" (set /a count+=1) else echo [MISSING] SuperiorSkyblockExtension\src\main\resources\translations\superiorskyblock_l10n_ru.json

if exist "RoadNetworkExtension\src\main\resources\translations\roadnetwork_l10n_en.json" (set /a count+=1) else echo [MISSING] RoadNetworkExtension\src\main\resources\translations\roadnetwork_l10n_en.json
if exist "RoadNetworkExtension\src\main\resources\translations\roadnetwork_l10n_ru.json" (set /a count+=1) else echo [MISSING] RoadNetworkExtension\src\main\resources\translations\roadnetwork_l10n_ru.json

if exist "RPGRegionsExtension\src\main\resources\translations\rpgregions_l10n_en.json" (set /a count+=1) else echo [MISSING] RPGRegionsExtension\src\main\resources\translations\rpgregions_l10n_en.json
if exist "RPGRegionsExtension\src\main\resources\translations\rpgregions_l10n_ru.json" (set /a count+=1) else echo [MISSING] RPGRegionsExtension\src\main\resources\translations\rpgregions_l10n_ru.json

if exist "MythicMobsExtension\src\main\resources\translations\mythicmobs_l10n_en.json" (set /a count+=1) else echo [MISSING] MythicMobsExtension\src\main\resources\translations\mythicmobs_l10n_en.json
if exist "MythicMobsExtension\src\main\resources\translations\mythicmobs_l10n_ru.json" (set /a count+=1) else echo [MISSING] MythicMobsExtension\src\main\resources\translations\mythicmobs_l10n_ru.json

if exist "_DocsExtension\src\main\resources\translations\docs_l10n_en.json" (set /a count+=1) else echo [MISSING] _DocsExtension\src\main\resources\translations\docs_l10n_en.json
if exist "_DocsExtension\src\main\resources\translations\docs_l10n_ru.json" (set /a count+=1) else echo [MISSING] _DocsExtension\src\main\resources\translations\docs_l10n_ru.json

echo.
echo ============================================================
echo SUMMARY:
echo ============================================================
echo Files verified: !count!/22
if !count! equ 22 (
    echo.
    echo SUCCESS: All 22 files successfully copied and verified!
) else (
    echo.
    echo ERROR: Not all files were copied successfully.
    echo Expected 22 files, but only found !count!
)

pause
