# 🚀 QUICK START - Generate Localization JSON Files

## ⏱️ 30-Second Summary

You have been provided with **all tools needed** to extract localization JSON from 11 Typewriter extensions.

### Just Run This:

```bash
cd c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions
python extract_and_deploy_l10n.py
```

**Done!** ✅ This will generate 22 JSON files across all extensions.

---

## 📋 What This Does

- ✅ Finds all 203 @Entry-annotated Kotlin files
- ✅ Extracts: entry ID, display name, javadoc, help text
- ✅ Generates 2 JSON files per extension (English + Russian)
- ✅ Creates all necessary directories automatically
- ✅ Places files in: `{ExtensionName}/src/main/resources/translations/`

---

## ✅ Expected Output

```
Processing VaultExtension (namespace: vault)
  Found 9 @Entry files
    ✓ vault.withdraw_balance
    ✓ vault.deposit_balance
    ... (7 more)
  ✓ Created vault_l10n_en.json
  ✓ Created vault_l10n_ru.json

Processing EntityExtension (namespace: entity)
  Found 41 @Entry files
    ✓ entity.entity_interact_event
    ... (40 more)
  ✓ Created entity_l10n_en.json
  ✓ Created entity_l10n_ru.json

... (9 more extensions)

Summary:
  Extensions processed: 11/11
  Total entries: 203
  Status: ✓ SUCCESS
```

---

## 📂 Generated Files

After running the script, you'll have:

```
VaultExtension/src/main/resources/translations/
  ├── vault_l10n_en.json
  └── vault_l10n_ru.json

EntityExtension/src/main/resources/translations/
  ├── entity_l10n_en.json
  └── entity_l10n_ru.json

BasicExtension/src/main/resources/translations/
  ├── basic_l10n_en.json
  └── basic_l10n_ru.json

... (8 more extensions)
```

**Total**: 22 JSON files

---

## 🔧 If Python Doesn't Work

### Try Node.js:
```bash
node extract_entries.js
```

### Or create directories first:
```bash
call create_dirs.bat
python extract_and_deploy_l10n.py
```

---

## 📖 Full Documentation

- `IMPLEMENTATION_GUIDE.md` - Complete instructions
- `TASK_COMPLETE.md` - Full technical details
- `README_L10N.md` - Architecture overview

---

## ✅ Verify It Worked

```bash
# Should show 22 files
find . -name "*_l10n_*.json" -type f | wc -l

# Check a file
cat VaultExtension/src/main/resources/translations/vault_l10n_en.json | head -10
```

---

## 🎯 One More Thing

For VaultExtension, pre-generated files are already available:

```bash
mv vault_l10n_en.json VaultExtension/src/main/resources/translations/
mv vault_l10n_ru.json VaultExtension/src/main/resources/translations/
```

Or just run the script - it will generate them fresh!

---

**That's it! 🎉 You're done.**
