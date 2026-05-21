#!/usr/bin/env python3
"""Verification script for localization extraction"""
import json
from pathlib import Path

BASE_DIR = Path(r"c:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter\extensions")

NAMESPACES = {
    "VaultExtension": "vault",
    "EntityExtension": "entity",
    "BasicExtension": "basic",
    "CitizensExtension": "citizens",
    "QuestExtension": "quest",
    "WorldGuardExtension": "worldguard",
    "SuperiorSkyblockExtension": "superiorskyblock",
    "RoadNetworkExtension": "roadnetwork",
    "RPGRegionsExtension": "rpgregions",
    "MythicMobsExtension": "mythicmobs",
    "_DocsExtension": "docs"
}

def verify_files():
    """Verify all localization files exist and are valid JSON"""
    print("Localization Files Verification Report")
    print("=" * 70)
    print()
    
    total_files = 0
    valid_files = 0
    total_entries = 0
    
    for ext_name, namespace in NAMESPACES.items():
        ext_dir = BASE_DIR / ext_name
        if not ext_dir.exists():
            print(f"❌ {ext_name}: Directory not found")
            continue
        
        en_file = ext_dir / "src" / "main" / f"{namespace}_l10n_en.json"
        ru_file = ext_dir / "src" / "main" / f"{namespace}_l10n_ru.json"
        
        print(f"📦 {ext_name} ({namespace})")
        
        # Check English file
        if en_file.exists():
            total_files += 1
            try:
                with open(en_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    entries = len([k for k in data.keys() if '.title' in k])
                    print(f"   ✅ EN file: {en_file.name}")
                    print(f"      - Entries: {entries}")
                    print(f"      - Keys: {len(data)}")
                    valid_files += 1
                    total_entries += entries
            except json.JSONDecodeError as e:
                print(f"   ❌ EN file: Invalid JSON - {e}")
        else:
            print(f"   ⚠️  EN file: Not found at {en_file}")
        
        # Check Russian file
        if ru_file.exists():
            total_files += 1
            try:
                with open(ru_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    entries = len([k for k in data.keys() if '.title' in k])
                    print(f"   ✅ RU file: {ru_file.name}")
                    print(f"      - Entries: {entries}")
                    print(f"      - Keys: {len(data)}")
                    valid_files += 1
            except json.JSONDecodeError as e:
                print(f"   ❌ RU file: Invalid JSON - {e}")
        else:
            print(f"   ⚠️  RU file: Not found at {ru_file}")
        
        print()
    
    print("=" * 70)
    print(f"Summary:")
    print(f"  Total files found: {total_files}")
    print(f"  Valid JSON files: {valid_files}")
    print(f"  Total @Entry entries: {total_entries}")
    print(f"  Expected files: 22")
    print(f"  Status: {'✅ PASS' if total_files == 22 and valid_files == 22 else '⚠️  INCOMPLETE'}")
    print()

if __name__ == "__main__":
    verify_files()
