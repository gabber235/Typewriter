# Localization JSON Generation Instructions

## Overview
This document provides instructions for generating localization JSON files for all 11 Typewriter extensions.

## Automated Approach (Recommended)

Run the provided Python script:

```bash
python "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\extract_l10n.py"
```

This script will:
1. Find all Kotlin files with @Entry annotations in each extension
2. Extract @Entry parameters (id, display_name, color, icon)
3. Extract class javadoc (first paragraph)
4. Extract @Help annotations on fields
5. Generate two JSON files per extension:
   - {namespace}_l10n_en.json (English)
   - {namespace}_l10n_ru.json (Russian translation)
6. Create the required directories: src/main/resources/translations/

## File Structure

After running the script, each extension will have:

```
{ExtensionName}/
└── src/
    └── main/
        └── resources/
            └── translations/
                ├── {namespace}_l10n_en.json
                └── {namespace}_l10n_ru.json
```

## JSON Format

Each JSON file follows this structure:

```json
{
  "{namespace}.{entry_id}.title": "{display_name}",
  "{namespace}.{entry_id}.description": "{class_javadoc}",
  "{namespace}.{entry_id}.fields.{field_name}.label": "{humanized_field_name}",
  "{namespace}.{entry_id}.fields.{field_name}.help": "{help_text}"
}
```

Example:
```json
{
  "vault.withdraw_balance.title": "Withdraw Balance",
  "vault.withdraw_balance.description": "The `Withdraw Balance Action` is used to withdraw money from a user's balance.",
  "vault.withdraw_balance.fields.amount.label": "Amount",
  "vault.withdraw_balance.fields.amount.help": "The amount of money to withdraw."
}
```

## Extensions and Namespaces

| Extension | Namespace | Entry Count |
|-----------|-----------|------------|
| VaultExtension | vault | 9 |
| EntityExtension | entity | 41 |
| BasicExtension | basic | 43 |
| CitizensExtension | citizens | 2 |
| QuestExtension | quest | 24 |
| WorldGuardExtension | worldguard | 5 |
| SuperiorSkyblockExtension | superiorskyblock | 15 |
| RoadNetworkExtension | roadnetwork | 11 |
| RPGRegionsExtension | rpgregions | 5 |
| MythicMobsExtension | mythicmobs | 9 |
| _DocsExtension | docs | 39 |
| **TOTAL** | | **203** |

## Pre-Generated Files

For VaultExtension, pre-generated JSON files are available:
- c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\vault_l10n_en.json
- c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\vault_l10n_ru.json

These should be moved to:
- VaultExtension/src/main/resources/translations/vault_l10n_en.json
- VaultExtension/src/main/resources/translations/vault_l10n_ru.json

## Manual Approach (If automation fails)

If the Python script cannot be executed:

1. Create the translations directory in each extension:
   ```bash
   mkdir -p {ExtensionName}/src/main/resources/translations
   ```

2. For each @Entry file found, extract:
   - @Entry annotation: id, display_name, color, icon
   - Javadoc: first paragraph before ## or empty line
   - @Help annotations: field names and help text

3. Build JSON objects as shown above

4. Write both English and Russian JSON files

## Script Files

- `extract_l10n.py` - Python script (recommended, uses only standard library)
- `extract_entries.js` - Node.js alternative (if Python unavailable)
- `extract_entries.bat` - Batch script to create directories

## Notes

- Russian translations are provided in the Python script's TRANSLATIONS dictionary
- Field names are humanized: camelCase → Title Case
- Javadoc extraction takes the first paragraph (stops at ## or empty lines)
- The script handles both single-line and multi-line @Entry annotations
