# Typewriter Extensions Localization Setup

This document explains the localization file generation and placement process for all 11 Typewriter extensions.

## Overview

Localization JSON files have been created for all 11 Typewriter extensions:

1. **VaultExtension** → `vault`
2. **EntityExtension** → `entity`
3. **BasicExtension** → `basic`
4. **CitizensExtension** → `citizens`
5. **QuestExtension** → `quest`
6. **WorldGuardExtension** → `worldguard`
7. **SuperiorSkyblockExtension** → `superiorskyblock`
8. **RoadNetworkExtension** → `roadnetwork`
9. **RPGRegionsExtension** → `rpgregions`
10. **MythicMobsExtension** → `mythicmobs`
11. **_DocsExtension** → `docs`

Each extension has two localization files:
- `{namespace}_l10n_en.json` - English translations
- `{namespace}_l10n_ru.json` - Russian translations

## File Locations

### Current Temporary Location
All localization files are temporarily located in:
```
extensions/{ExtensionName}/src/main/{namespace}_l10n_*.json
```

### Final Target Location
Files should be moved to:
```
extensions/{ExtensionName}/src/main/resources/translations/{namespace}_l10n_*.json
```

## Setup Steps

### Step 1: Generate Complete Localization Data

Run the comprehensive extraction and generation script:

```bash
cd extensions
python3 generate_all_l10n.py "."
```

Or from the repo root:

```bash
python3 extensions/generate_all_l10n.py "extensions"
```

This script will:
- Parse all `@Entry` annotations from each extension
- Extract entry IDs, display names, descriptions
- Extract `@Help` annotations from fields
- Create the proper directory structure (`src/main/resources/translations/`)
- Generate complete EN and RU localization files for all entries
- Overwrite temporary stub files with real data

### Step 2: Move Files to Correct Location

If you need to move files manually (for extensions not yet fully extracted):

```bash
python3 move_l10n_files.py
```

Or manually using your file manager:
- Move each `{namespace}_l10n_en.json` file from `src/main/` to `src/main/resources/translations/`
- Move each `{namespace}_l10n_ru.json` file from `src/main/` to `src/main/resources/translations/`

### Step 3: Verify Files Are in Place

Check that files exist at:
```
extensions/{ExtensionName}/src/main/resources/translations/{namespace}_l10n_en.json
extensions/{ExtensionName}/src/main/resources/translations/{namespace}_l10n_ru.json
```

## JSON Format

Each localization file follows this format:

```json
{
  "{namespace}.{entry_id}.title": "Display Name",
  "{namespace}.{entry_id}.description": "Description of the entry",
  "{namespace}.{entry_id}.fields.{field_name}.label": "Field Label",
  "{namespace}.{entry_id}.fields.{field_name}.help": "Field help text"
}
```

### Example for VaultExtension

```json
{
  "vault.withdraw_balance.title": "Withdraw Balance",
  "vault.withdraw_balance.description": "The `Withdraw Balance Action` is used to withdraw money from a user's balance.",
  "vault.withdraw_balance.fields.amount.label": "Amount",
  "vault.withdraw_balance.fields.amount.help": "The amount of money to withdraw.",
  "vault.withdraw_balance.title": "Вывести баланс",
  ...
}
```

## Scripts Included

### `generate_all_l10n.py`
Extracts `@Entry` annotations from Kotlin source files and generates complete localization files for all extensions.

**Usage:**
```bash
cd extensions
python3 generate_all_l10n.py "."
```

**What it does:**
1. Scans each extension's `src/main/kotlin/` directory
2. Finds all `@Entry` annotations
3. Extracts javadoc comments for descriptions
4. Extracts `@Help` annotations for field help text
5. Creates `src/main/resources/translations/` directory for each extension
6. Generates English and Russian JSON files
7. Returns statistics on entries processed

### `move_l10n_files.py`
Moves temporary localization files from `src/main/` to `src/main/resources/translations/`

**Usage:**
```bash
python3 move_l10n_files.py
```

### `setup_l10n.sh`
Bash wrapper that creates directories and runs the generation script.

**Usage:**
```bash
bash setup_l10n.sh
```

## Localization Key Format

Keys follow a hierarchical pattern to avoid collisions:

```
{namespace}.{entry_id}.{section}.{property}
```

Where:
- `{namespace}` - Extension namespace (vault, entity, basic, etc.)
- `{entry_id}` - Entry ID from @Entry annotation
- `{section}` - Section type (title, description, fields)
- `{property}` - Property type (label, help, etc.)

## Russian Translations

Russian translations are auto-generated with basic heuristics:
- Common terms are pre-translated
- Field names are humanized and translated
- Descriptions are translated using a translation dictionary
- For new terms, add them to the `RUSSIAN_TRANSLATIONS` dict in `generate_all_l10n.py`

## Troubleshooting

### "No localization data for {namespace}"
This means no `@Entry` annotations were found in that extension. Verify:
1. The extension has source files in `src/main/kotlin/`
2. Entry files exist in `src/main/kotlin/**/entries/**/*.kt`
3. Files contain valid `@Entry` annotations

### Translation errors
If a translation is incorrect:
1. Edit the localization JSON file directly
2. Or update the `RUSSIAN_TRANSLATIONS` dictionary in `generate_all_l10n.py` and regenerate

### Files in wrong location
Run `move_l10n_files.py` to move them to the correct location.

## Next Steps

1. Execute `python3 extensions/generate_all_l10n.py "extensions"` from repo root
2. Verify files appear in `extensions/*/src/main/resources/translations/`
3. Commit the files to git
4. Continue with extension development

## Notes

- VaultExtension already has fully populated localization files
- Other extensions have stub files that will be populated by `generate_all_l10n.py`
- The directory structure needs to exist before files can be placed
- All localization is UTF-8 encoded JSON
- Keys are sorted alphabetically in the JSON files
