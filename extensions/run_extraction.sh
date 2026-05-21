#!/bin/bash
# Create all translation directories
mkdir -p "c:/Users/Ося/Documents/Dev/Minecraft/plugins/Typewriter/extensions/VaultExtension/src/main/resources/translations"
mkdir -p "c:/Users/Ося/Documents/Dev/Minecraft/plugins/Typewriter/extensions/EntityExtension/src/main/resources/translations"
mkdir -p "c:/Users/Ося/Documents/Dev/Minecraft/plugins/Typewriter/extensions/BasicExtension/src/main/resources/translations"
mkdir -p "c:/Users/Ося/Documents/Dev/Minecraft/plugins/Typewriter/extensions/CitizensExtension/src/main/resources/translations"
mkdir -p "c:/Users/Ося/Documents/Dev/Minecraft/plugins/Typewriter/extensions/QuestExtension/src/main/resources/translations"
mkdir -p "c:/Users/Ося/Documents/Dev/Minecraft/plugins/Typewriter/extensions/WorldGuardExtension/src/main/resources/translations"
mkdir -p "c:/Users/Ося/Documents/Dev/Minecraft/plugins/Typewriter/extensions/SuperiorSkyblockExtension/src/main/resources/translations"
mkdir -p "c:/Users/Ося/Documents/Dev/Minecraft/plugins/Typewriter/extensions/RoadNetworkExtension/src/main/resources/translations"
mkdir -p "c:/Users/Ося/Documents/Dev/Minecraft/plugins/Typewriter/extensions/RPGRegionsExtension/src/main/resources/translations"
mkdir -p "c:/Users/Ося/Documents/Dev/Minecraft/plugins/Typewriter/extensions/MythicMobsExtension/src/main/resources/translations"
mkdir -p "c:/Users/Ося/Documents/Dev/Minecraft/plugins/Typewriter/extensions/_DocsExtension/src/main/resources/translations"

echo "All translation directories created successfully!"

# Then run the extraction script
python "c:/Users/Ося/Documents/Dev/Minecraft/plugins/Typewriter/extensions/extract_l10n.py"
