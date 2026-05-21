@echo off
REM Create translation directories for all 11 extensions

setlocal enabledelayedexpansion

set "basePath=extensions"

REM VaultExtension
mkdir "%basePath%\VaultExtension\src\main\resources\translations" 2>nul
REM EntityExtension
mkdir "%basePath%\EntityExtension\src\main\resources\translations" 2>nul
REM BasicExtension
mkdir "%basePath%\BasicExtension\src\main\resources\translations" 2>nul
REM CitizensExtension
mkdir "%basePath%\CitizensExtension\src\main\resources\translations" 2>nul
REM QuestExtension
mkdir "%basePath%\QuestExtension\src\main\resources\translations" 2>nul
REM WorldGuardExtension
mkdir "%basePath%\WorldGuardExtension\src\main\resources\translations" 2>nul
REM SuperiorSkyblockExtension
mkdir "%basePath%\SuperiorSkyblockExtension\src\main\resources\translations" 2>nul
REM RoadNetworkExtension
mkdir "%basePath%\RoadNetworkExtension\src\main\resources\translations" 2>nul
REM RPGRegionsExtension
mkdir "%basePath%\RPGRegionsExtension\src\main\resources\translations" 2>nul
REM MythicMobsExtension
mkdir "%basePath%\MythicMobsExtension\src\main\resources\translations" 2>nul
REM _DocsExtension
mkdir "%basePath%\_DocsExtension\src\main\resources\translations" 2>nul

echo All translation directories created!
