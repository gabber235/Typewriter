@echo off
REM Move localization files to resources/translations for all extensions

setlocal enabledelayedexpansion

REM Create translation directories for all extensions
echo Creating directories...
mkdir "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\VaultExtension\src\main\resources\translations" 2>nul
mkdir "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\EntityExtension\src\main\resources\translations" 2>nul
mkdir "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\BasicExtension\src\main\resources\translations" 2>nul
mkdir "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\CitizensExtension\src\main\resources\translations" 2>nul
mkdir "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\QuestExtension\src\main\resources\translations" 2>nul
mkdir "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\WorldGuardExtension\src\main\resources\translations" 2>nul
mkdir "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\SuperiorSkyblockExtension\src\main\resources\translations" 2>nul
mkdir "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\RoadNetworkExtension\src\main\resources\translations" 2>nul
mkdir "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\RPGRegionsExtension\src\main\resources\translations" 2>nul
mkdir "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\MythicMobsExtension\src\main\resources\translations" 2>nul
mkdir "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\_DocsExtension\src\main\resources\translations" 2>nul

echo.
echo Moving localization files...

REM Move VaultExtension files
move "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\VaultExtension\src\main\vault_l10n_en.json" "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\VaultExtension\src\main\resources\translations\" /Y
move "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\VaultExtension\src\main\vault_l10n_ru.json" "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\VaultExtension\src\main\resources\translations\" /Y

REM Move EntityExtension files
move "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\EntityExtension\src\main\entity_l10n_en.json" "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\EntityExtension\src\main\resources\translations\" /Y
move "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\EntityExtension\src\main\entity_l10n_ru.json" "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\EntityExtension\src\main\resources\translations\" /Y

REM Move BasicExtension files
move "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\BasicExtension\src\main\basic_l10n_en.json" "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\BasicExtension\src\main\resources\translations\" /Y
move "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\BasicExtension\src\main\basic_l10n_ru.json" "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\BasicExtension\src\main\resources\translations\" /Y

REM Move CitizensExtension files
move "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\CitizensExtension\src\main\citizens_l10n_en.json" "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\CitizensExtension\src\main\resources\translations\" /Y
move "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\CitizensExtension\src\main\citizens_l10n_ru.json" "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\CitizensExtension\src\main\resources\translations\" /Y

REM Move QuestExtension files
move "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\QuestExtension\src\main\quest_l10n_en.json" "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\QuestExtension\src\main\resources\translations\" /Y
move "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\QuestExtension\src\main\quest_l10n_ru.json" "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\QuestExtension\src\main\resources\translations\" /Y

REM Move WorldGuardExtension files
move "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\WorldGuardExtension\src\main\worldguard_l10n_en.json" "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\WorldGuardExtension\src\main\resources\translations\" /Y
move "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\WorldGuardExtension\src\main\worldguard_l10n_ru.json" "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\WorldGuardExtension\src\main\resources\translations\" /Y

REM Move SuperiorSkyblockExtension files
move "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\SuperiorSkyblockExtension\src\main\superiorskyblock_l10n_en.json" "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\SuperiorSkyblockExtension\src\main\resources\translations\" /Y
move "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\SuperiorSkyblockExtension\src\main\superiorskyblock_l10n_ru.json" "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\SuperiorSkyblockExtension\src\main\resources\translations\" /Y

REM Move RoadNetworkExtension files
move "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\RoadNetworkExtension\src\main\roadnetwork_l10n_en.json" "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\RoadNetworkExtension\src\main\resources\translations\" /Y
move "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\RoadNetworkExtension\src\main\roadnetwork_l10n_ru.json" "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\RoadNetworkExtension\src\main\resources\translations\" /Y

REM Move RPGRegionsExtension files
move "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\RPGRegionsExtension\src\main\rpgregions_l10n_en.json" "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\RPGRegionsExtension\src\main\resources\translations\" /Y
move "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\RPGRegionsExtension\src\main\rpgregions_l10n_ru.json" "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\RPGRegionsExtension\src\main\resources\translations\" /Y

REM Move MythicMobsExtension files
move "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\MythicMobsExtension\src\main\mythicmobs_l10n_en.json" "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\MythicMobsExtension\src\main\resources\translations\" /Y
move "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\MythicMobsExtension\src\main\mythicmobs_l10n_ru.json" "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\MythicMobsExtension\src\main\resources\translations\" /Y

REM Move _DocsExtension files
move "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\_DocsExtension\src\main\docs_l10n_en.json" "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\_DocsExtension\src\main\resources\translations\" /Y
move "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\_DocsExtension\src\main\docs_l10n_ru.json" "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\_DocsExtension\src\main\resources\translations\" /Y

echo.
echo ✓ All 22 localization files moved successfully!
echo.
pause
