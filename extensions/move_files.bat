@echo off
setlocal enabledelayedexpansion
cd /d "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions"

echo Creating directories...

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
echo Moving files...

if exist "VaultExtension\src\main\vault_l10n_en.json" move "VaultExtension\src\main\vault_l10n_en.json" "VaultExtension\src\main\resources\translations\"
if exist "VaultExtension\src\main\vault_l10n_ru.json" move "VaultExtension\src\main\vault_l10n_ru.json" "VaultExtension\src\main\resources\translations\"

if exist "EntityExtension\src\main\entity_l10n_en.json" move "EntityExtension\src\main\entity_l10n_en.json" "EntityExtension\src\main\resources\translations\"
if exist "EntityExtension\src\main\entity_l10n_ru.json" move "EntityExtension\src\main\entity_l10n_ru.json" "EntityExtension\src\main\resources\translations\"

if exist "BasicExtension\src\main\basic_l10n_en.json" move "BasicExtension\src\main\basic_l10n_en.json" "BasicExtension\src\main\resources\translations\"
if exist "BasicExtension\src\main\basic_l10n_ru.json" move "BasicExtension\src\main\basic_l10n_ru.json" "BasicExtension\src\main\resources\translations\"

if exist "CitizensExtension\src\main\citizens_l10n_en.json" move "CitizensExtension\src\main\citizens_l10n_en.json" "CitizensExtension\src\main\resources\translations\"
if exist "CitizensExtension\src\main\citizens_l10n_ru.json" move "CitizensExtension\src\main\citizens_l10n_ru.json" "CitizensExtension\src\main\resources\translations\"

if exist "QuestExtension\src\main\quest_l10n_en.json" move "QuestExtension\src\main\quest_l10n_en.json" "QuestExtension\src\main\resources\translations\"
if exist "QuestExtension\src\main\quest_l10n_ru.json" move "QuestExtension\src\main\quest_l10n_ru.json" "QuestExtension\src\main\resources\translations\"

if exist "WorldGuardExtension\src\main\worldguard_l10n_en.json" move "WorldGuardExtension\src\main\worldguard_l10n_en.json" "WorldGuardExtension\src\main\resources\translations\"
if exist "WorldGuardExtension\src\main\worldguard_l10n_ru.json" move "WorldGuardExtension\src\main\worldguard_l10n_ru.json" "WorldGuardExtension\src\main\resources\translations\"

if exist "SuperiorSkyblockExtension\src\main\superiorskyblock_l10n_en.json" move "SuperiorSkyblockExtension\src\main\superiorskyblock_l10n_en.json" "SuperiorSkyblockExtension\src\main\resources\translations\"
if exist "SuperiorSkyblockExtension\src\main\superiorskyblock_l10n_ru.json" move "SuperiorSkyblockExtension\src\main\superiorskyblock_l10n_ru.json" "SuperiorSkyblockExtension\src\main\resources\translations\"

if exist "RoadNetworkExtension\src\main\roadnetwork_l10n_en.json" move "RoadNetworkExtension\src\main\roadnetwork_l10n_en.json" "RoadNetworkExtension\src\main\resources\translations\"
if exist "RoadNetworkExtension\src\main\roadnetwork_l10n_ru.json" move "RoadNetworkExtension\src\main\roadnetwork_l10n_ru.json" "RoadNetworkExtension\src\main\resources\translations\"

if exist "RPGRegionsExtension\src\main\rpgregions_l10n_en.json" move "RPGRegionsExtension\src\main\rpgregions_l10n_en.json" "RPGRegionsExtension\src\main\resources\translations\"
if exist "RPGRegionsExtension\src\main\rpgregions_l10n_ru.json" move "RPGRegionsExtension\src\main\rpgregions_l10n_ru.json" "RPGRegionsExtension\src\main\resources\translations\"

if exist "MythicMobsExtension\src\main\mythicmobs_l10n_en.json" move "MythicMobsExtension\src\main\mythicmobs_l10n_en.json" "MythicMobsExtension\src\main\resources\translations\"
if exist "MythicMobsExtension\src\main\mythicmobs_l10n_ru.json" move "MythicMobsExtension\src\main\mythicmobs_l10n_ru.json" "MythicMobsExtension\src\main\resources\translations\"

if exist "_DocsExtension\src\main\docs_l10n_en.json" move "_DocsExtension\src\main\docs_l10n_en.json" "_DocsExtension\src\main\resources\translations\"
if exist "_DocsExtension\src\main\docs_l10n_ru.json" move "_DocsExtension\src\main\docs_l10n_ru.json" "_DocsExtension\src\main\resources\translations\"

echo.
echo All files moved successfully!
pause
