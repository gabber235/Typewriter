@echo off
setlocal enabledelayedexpansion

set "basePath=c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions"

for %%E in (VaultExtension EntityExtension BasicExtension CitizensExtension QuestExtension WorldGuardExtension SuperiorSkyblockExtension RoadNetworkExtension RPGRegionsExtension MythicMobsExtension _DocsExtension) do (
    set "dir=!basePath!\%%E\src\main\resources\translations"
    if not exist "!dir!" (
        mkdir "!dir!"
        echo Created: !dir!
    )
)

echo.
echo All directories created successfully.
