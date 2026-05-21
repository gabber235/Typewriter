#!/bin/bash
# Create directory structure and move localization files for all extensions

BASE_DIR="c:\\Users\\Ося\\Documents\\Dev\\Minecraft\\plugins\\Typewriter\\extensions"

for ext in VaultExtension EntityExtension BasicExtension CitizensExtension QuestExtension WorldGuardExtension SuperiorSkyblockExtension RoadNetworkExtension RPGRegionsExtension MythicMobsExtension _DocsExtension; do
  TRANS_DIR="$BASE_DIR\\$ext\\src\\main\\resources\\translations"
  echo "Creating directory: $TRANS_DIR"
  mkdir -p "$TRANS_DIR"
done

# Move VaultExtension files
echo "Moving VaultExtension localization files..."
mv "$BASE_DIR\\VaultExtension\\src\\main\\vault_l10n_en.json" "$BASE_DIR\\VaultExtension\\src\\main\\resources\\translations\\vault_l10n_en.json"
mv "$BASE_DIR\\VaultExtension\\src\\main\\vault_l10n_ru.json" "$BASE_DIR\\VaultExtension\\src\\main\\resources\\translations\\vault_l10n_ru.json"

# Move EntityExtension files
echo "Moving EntityExtension localization files..."
mv "$BASE_DIR\\EntityExtension\\src\\main\\entity_l10n_en.json" "$BASE_DIR\\EntityExtension\\src\\main\\resources\\translations\\entity_l10n_en.json"
mv "$BASE_DIR\\EntityExtension\\src\\main\\entity_l10n_ru.json" "$BASE_DIR\\EntityExtension\\src\\main\\resources\\translations\\entity_l10n_ru.json"

# Move BasicExtension files
echo "Moving BasicExtension localization files..."
mv "$BASE_DIR\\BasicExtension\\src\\main\\basic_l10n_en.json" "$BASE_DIR\\BasicExtension\\src\\main\\resources\\translations\\basic_l10n_en.json"
mv "$BASE_DIR\\BasicExtension\\src\\main\\basic_l10n_ru.json" "$BASE_DIR\\BasicExtension\\src\\main\\resources\\translations\\basic_l10n_ru.json"

# Move CitizensExtension files
echo "Moving CitizensExtension localization files..."
mv "$BASE_DIR\\CitizensExtension\\src\\main\\citizens_l10n_en.json" "$BASE_DIR\\CitizensExtension\\src\\main\\resources\\translations\\citizens_l10n_en.json"
mv "$BASE_DIR\\CitizensExtension\\src\\main\\citizens_l10n_ru.json" "$BASE_DIR\\CitizensExtension\\src\\main\\resources\\translations\\citizens_l10n_ru.json"

# Move QuestExtension files
echo "Moving QuestExtension localization files..."
mv "$BASE_DIR\\QuestExtension\\src\\main\\quest_l10n_en.json" "$BASE_DIR\\QuestExtension\\src\\main\\resources\\translations\\quest_l10n_en.json"
mv "$BASE_DIR\\QuestExtension\\src\\main\\quest_l10n_ru.json" "$BASE_DIR\\QuestExtension\\src\\main\\resources\\translations\\quest_l10n_ru.json"

# Move WorldGuardExtension files
echo "Moving WorldGuardExtension localization files..."
mv "$BASE_DIR\\WorldGuardExtension\\src\\main\\worldguard_l10n_en.json" "$BASE_DIR\\WorldGuardExtension\\src\\main\\resources\\translations\\worldguard_l10n_en.json"
mv "$BASE_DIR\\WorldGuardExtension\\src\\main\\worldguard_l10n_ru.json" "$BASE_DIR\\WorldGuardExtension\\src\\main\\resources\\translations\\worldguard_l10n_ru.json"

# Move SuperiorSkyblockExtension files
echo "Moving SuperiorSkyblockExtension localization files..."
mv "$BASE_DIR\\SuperiorSkyblockExtension\\src\\main\\superiorskyblock_l10n_en.json" "$BASE_DIR\\SuperiorSkyblockExtension\\src\\main\\resources\\translations\\superiorskyblock_l10n_en.json"
mv "$BASE_DIR\\SuperiorSkyblockExtension\\src\\main\\superiorskyblock_l10n_ru.json" "$BASE_DIR\\SuperiorSkyblockExtension\\src\\main\\resources\\translations\\superiorskyblock_l10n_ru.json"

# Move RoadNetworkExtension files
echo "Moving RoadNetworkExtension localization files..."
mv "$BASE_DIR\\RoadNetworkExtension\\src\\main\\roadnetwork_l10n_en.json" "$BASE_DIR\\RoadNetworkExtension\\src\\main\\resources\\translations\\roadnetwork_l10n_en.json"
mv "$BASE_DIR\\RoadNetworkExtension\\src\\main\\roadnetwork_l10n_ru.json" "$BASE_DIR\\RoadNetworkExtension\\src\\main\\resources\\translations\\roadnetwork_l10n_ru.json"

# Move RPGRegionsExtension files
echo "Moving RPGRegionsExtension localization files..."
mv "$BASE_DIR\\RPGRegionsExtension\\src\\main\\rpgregions_l10n_en.json" "$BASE_DIR\\RPGRegionsExtension\\src\\main\\resources\\translations\\rpgregions_l10n_en.json"
mv "$BASE_DIR\\RPGRegionsExtension\\src\\main\\rpgregions_l10n_ru.json" "$BASE_DIR\\RPGRegionsExtension\\src\\main\\resources\\translations\\rpgregions_l10n_ru.json"

# Move MythicMobsExtension files
echo "Moving MythicMobsExtension localization files..."
mv "$BASE_DIR\\MythicMobsExtension\\src\\main\\mythicmobs_l10n_en.json" "$BASE_DIR\\MythicMobsExtension\\src\\main\\resources\\translations\\mythicmobs_l10n_en.json"
mv "$BASE_DIR\\MythicMobsExtension\\src\\main\\mythicmobs_l10n_ru.json" "$BASE_DIR\\MythicMobsExtension\\src\\main\\resources\\translations\\mythicmobs_l10n_ru.json"

# Move _DocsExtension files
echo "Moving _DocsExtension localization files..."
mv "$BASE_DIR\\_DocsExtension\\src\\main\\docs_l10n_en.json" "$BASE_DIR\\_DocsExtension\\src\\main\\resources\\translations\\docs_l10n_en.json"
mv "$BASE_DIR\\_DocsExtension\\src\\main\\docs_l10n_ru.json" "$BASE_DIR\\_DocsExtension\\src\\main\\resources\\translations\\docs_l10n_ru.json"

echo "✓ All localization files moved to correct locations!"
