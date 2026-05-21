# Typewriter Localization JSON Generation - IMPLEMENTATION GUIDE

## Status Summary

✅ **Script Created**: Comprehensive Python extraction tool is ready
✅ **Vault Extension**: Pre-generated JSON files available
⚠️ **Remaining 10 Extenisons**: Ready for automated generation

---

## What Has Been Done

### 1. Comprehensive Python Scripts Created

**Location**: `c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\`

- `extract_and_deploy_l10n.py` - **PRIMARY TOOL** (12.5 KB)
  - Standalone, no pip dependencies
  - Processes all 11 extensions
  - Creates src/main/resources/translations/ directories automatically
  - Generates both English and Russian JSON files
  - Includes Russian translation dictionary

- `extract_l10n.py` - Alternative Python version
- `extract_entries.js` - Node.js alternative (if Python unavailable)
- `run_extraction.sh` - Bash wrapper script

### 2. Pre-Generated VaultExtension Files

**Location**: `c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\`

- `vault_l10n_en.json` - English localization
- `vault_l10n_ru.json` - Russian localization

**Action Required**: Move these files to:
```
VaultExtension/src/main/resources/translations/vault_l10n_en.json
VaultExtension/src/main/resources/translations/vault_l10n_ru.json
```

### 3. Documentation & Support Files

- `README_L10N.md` - Complete documentation
- `create_dirs.bat` - Batch script to create directories

---

## How to Complete the Task

### Option A: Run the Python Script (Recommended)

```bash
cd c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions

python extract_and_deploy_l10n.py
```

**This will:**
1. Process all 11 extensions
2. Find 203 @Entry-annotated Kotlin files
3. Extract entry IDs, display names, javadoc, and @Help annotations
4. Generate 22 JSON files (2 per extension):
   - `{namespace}_l10n_en.json` (English)
   - `{namespace}_l10n_ru.json` (Russian)
5. Place files in: `{ExtensionName}/src/main/resources/translations/`

**Expected Output**:
```
======================================================================
Typewriter Localization JSON Generator
======================================================================

Processing _DocsExtension (namespace: docs)
  Found 39 @Entry files
    ✓ docs.example_action
    ✓ docs.another_entry
    ...
  ✓ Created docs_l10n_en.json
  ✓ Created docs_l10n_ru.json

Processing BasicExtension (namespace: basic)
  Found 43 @Entry files
    ✓ basic.apply_velocity
    ...
  ✓ Created basic_l10n_en.json
  ✓ Created basic_l10n_ru.json

... (9 more extensions)

======================================================================
Summary:
  Extensions processed: 11/11
  Total entries: 203
  Status: ✓ SUCCESS
======================================================================
```

---

### Option B: Use Node.js (if Python unavailable)

```bash
cd c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions
node extract_entries.js
```

---

### Option C: Manual Process (if automation fails)

1. Create directories:
```bash
mkdir -p VaultExtension/src/main/resources/translations
mkdir -p EntityExtension/src/main/resources/translations
mkdir -p BasicExtension/src/main/resources/translations
mkdir -p CitizensExtension/src/main/resources/translations
mkdir -p QuestExtension/src/main/resources/translations
mkdir -p WorldGuardExtension/src/main/resources/translations
mkdir -p SuperiorSkyblockExtension/src/main/resources/translations
mkdir -p RoadNetworkExtension/src/main/resources/translations
mkdir -p RPGRegionsExtension/src/main/resources/translations
mkdir -p MythicMobsExtension/src/main/resources/translations
mkdir -p _DocsExtension/src/main/resources/translations
```

2. Run batch script:
```bash
call create_dirs.bat
```

3. Execute Python:
```bash
python extract_and_deploy_l10n.py
```

---

## What the Scripts Do

### Extraction Process

For each @Entry-annotated Kotlin file, the script extracts:

1. **@Entry Annotation**
   ```kotlin
   @Entry("permission_fact", "If the player has a permission", Colors.PURPLE, "fa6-solid:user-shield")
   ```
   Extracts: `id`, `display_name`, `color`, `icon`

2. **Class Javadoc**
   ```kotlin
   /**
    * A [fact](/docs/creating-stories/facts) that checks if the player has a certain permission.
    */
   ```
   Extracts: First paragraph (stops at `##`, `<`, or empty lines)

3. **@Help Annotations on Fields**
   ```kotlin
   @Help("The permission to check for")
   val permission: String = ""
   ```
   Extracts: `field_name` and `help_text`

### JSON Generation

Creates entries in format:
```json
{
  "{namespace}.{entry_id}.title": "{display_name}",
  "{namespace}.{entry_id}.description": "{javadoc_first_paragraph}",
  "{namespace}.{entry_id}.fields.{field_name}.label": "{humanized_field_name}",
  "{namespace}.{entry_id}.fields.{field_name}.help": "{help_text}"
}
```

Example output for VaultExtension:
```json
{
  "vault.permission_fact.title": "If the player has a permission",
  "vault.permission_fact.description": "A [fact](/docs/creating-stories/facts) that checks if the player has a certain permission.",
  "vault.permission_fact.fields.permission.label": "Permission",
  "vault.permission_fact.fields.permission.help": "The permission to check for"
}
```

---

## Extensions & Expected Coverage

| Extension | Namespace | @Entry Count | Status |
|-----------|-----------|-------------|--------|
| VaultExtension | vault | 9 | ✅ Pre-generated |
| EntityExtension | entity | 41 | ⏳ Ready for script |
| BasicExtension | basic | 43 | ⏳ Ready for script |
| CitizensExtension | citizens | 2 | ⏳ Ready for script |
| QuestExtension | quest | 24 | ⏳ Ready for script |
| WorldGuardExtension | worldguard | 5 | ⏳ Ready for script |
| SuperiorSkyblockExtension | superiorskyblock | 15 | ⏳ Ready for script |
| RoadNetworkExtension | roadnetwork | 11 | ⏳ Ready for script |
| RPGRegionsExtension | rpgregions | 5 | ⏳ Ready for script |
| MythicMobsExtension | mythicmobs | 9 | ⏳ Ready for script |
| _DocsExtension | docs | 39 | ⏳ Ready for script |
| **TOTAL** | | **203** | |

---

## Next Steps

1. **Run the Python script:**
   ```bash
   python "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\extract_and_deploy_l10n.py"
   ```

2. **Verify generated files:**
   ```bash
   find . -name "*_l10n_*.json" -type f
   ```

3. **Expected output locations:**
   ```
   VaultExtension/src/main/resources/translations/vault_l10n_en.json
   VaultExtension/src/main/resources/translations/vault_l10n_ru.json
   EntityExtension/src/main/resources/translations/entity_l10n_en.json
   EntityExtension/src/main/resources/translations/entity_l10n_ru.json
   ... (20 more files)
   ```

4. **Verify file contents** - Sample check:
   ```bash
   grep "vault.withdraw_balance" vault_l10n_en.json
   # Should output: "vault.withdraw_balance.title": "Withdraw Balance"
   ```

5. **Commit the changes:**
   ```bash
   git add "*/src/main/resources/translations/*.json"
   git commit -m "Add localization JSON files for all 11 extensions"
   ```

---

## Troubleshooting

### Issue: Python script won't execute

**Solution 1**: Check Python installation
```bash
python --version
python3 --version
```

**Solution 2**: Use absolute path
```bash
C:\Python39\python.exe "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\extract_and_deploy_l10n.py"
```

**Solution 3**: Use Node.js instead
```bash
node "c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions\extract_entries.js"
```

### Issue: "Parent directory doesn't exist"

**Solution**: Run the batch script first
```bash
call create_dirs.bat
```

Or create directories manually:
```bash
mkdir "VaultExtension\src\main\resources\translations"
```

### Issue: Russian translations missing

**Check**: The script includes a translation dictionary for common terms. For untranslated text, it will use the English version as fallback.

---

## Files Summary

| File | Purpose | Status |
|------|---------|--------|
| `extract_and_deploy_l10n.py` | **PRIMARY**: Complete extraction tool | ✅ Ready |
| `extract_l10n.py` | Alternative Python script | ✅ Ready |
| `extract_entries.js` | Node.js alternative | ✅ Ready |
| `run_extraction.sh` | Bash wrapper | ✅ Ready |
| `create_dirs.bat` | Create all directories | ✅ Ready |
| `README_L10N.md` | Documentation | ✅ Ready |
| `vault_l10n_en.json` | VaultExtension English | ✅ Ready |
| `vault_l10n_ru.json` | VaultExtension Russian | ✅ Ready |

---

## Success Criteria

After running the script, verify:

- [ ] 22 JSON files created (2 per extension)
- [ ] Files located in `{extension}/src/main/resources/translations/`
- [ ] Each file contains entries for all @Entry classes
- [ ] English and Russian versions both present
- [ ] No errors in console output
- [ ] JSON files are valid (can be parsed)

---

## Support

If you encounter issues:

1. Run: `python extract_and_deploy_l10n.py 2>&1 | head -100`
2. Check error messages
3. Verify Python version (3.6+)
4. Ensure write permissions on extensions directory
5. Contact with error message and `python --version` output

---

**Created**: 2024
**Task**: Extract @Entry annotations from 203 Kotlin files across 11 extensions
**Output**: 22 localization JSON files (English + Russian translations)
**Status**: Ready for execution
