#!/usr/bin/env python3
r"""
Typewriter Build Script - Main Pipeline
Run: python BUILD.py
"""

import subprocess
import sys
import os
from pathlib import Path

ROOT = Path(r"C:\Users\Ося\Documents\Dev\Minecraft\plugins\Typewriter")
APP_DIR = ROOT / "app"
EXT_DIR = ROOT / "extensions"
ENGINE_DIR = ROOT / "engine"
FLUTTER_BIN = Path(r"C:\Users\Ося\flutter\bin")

def log(msg, ok=True):
    print(f"  {'✓' if ok else '✗'} {msg}")

def run_cmd(cmd, cwd, name):
    print(f"\n  {name}...")
    print(f"  cmd: {' '.join(str(c) for c in cmd)}\n")
    
    # On Windows, batch files need to be executed through cmd.exe
    if cmd[0].endswith('.bat') or cmd[0] == 'gradlew.bat':
        cmd = ['cmd', '/c'] + cmd
    
    result = subprocess.run(cmd, cwd=str(cwd))
    return result.returncode == 0

def main():
    print("\n" + "="*80)
    print("  TYPEWRITER BUILD PIPELINE")
    print("="*80 + "\n")
    
    # Check paths
    print("  Checking paths...\n")
    if not ROOT.exists():
        log("Root not found", False)
        return 1
    log(f"Root: {ROOT}")
    
    if not APP_DIR.exists():
        log("App not found", False)
        return 1
    log(f"App: {APP_DIR}")
    
    if not EXT_DIR.exists():
        log("Extensions not found", False)
        return 1
    log(f"Extensions: {EXT_DIR}")
    
    # Find Flutter
    print("\n  Finding Flutter...\n")
    flutter = FLUTTER_BIN / "flutter.bat"
    if not flutter.exists():
        flutter = FLUTTER_BIN / "flutter"
    
    if not flutter.exists():
        log("Flutter not found at expected path", False)
        print(f"    Expected: {FLUTTER_BIN}")
        return 1
    
    log(f"Flutter: {flutter}")
    
    # Step 1: Freezed
    print("\n" + "="*80)
    print("  STEP 1: Regenerate Freezed Code")
    print("="*80)
    
    # Delete old files
    freezed_files = [
        APP_DIR / "lib" / "models" / "entry_blueprint.freezed.dart",
        APP_DIR / "lib" / "models" / "extension.freezed.dart",
    ]
    
    for f in freezed_files:
        if f.exists():
            f.unlink()
            log(f"Deleted {f.name}")
    
    # Run build_runner
    if not run_cmd(
        [str(flutter), "pub", "run", "build_runner", "build", "--delete-conflicting-outputs"],
        APP_DIR,
        "Running build_runner"
    ):
        log("Freezed generation failed", False)
        return 1
    
    log("Freezed code regenerated")
    
    # Step 2: Translations
    print("\n" + "="*80)
    print("  STEP 2: Extract Translations")
    print("="*80)
    
    setup_script = EXT_DIR / "setup_all_localizations.py"
    if setup_script.exists():
        run_cmd(
            ["python", str(setup_script)],
            EXT_DIR,
            "Extracting translations"
        )
    else:
        log("Translation script not found (optional)")
    
    # Step 3: Flutter web
    print("\n" + "="*80)
    print("  STEP 3: Build Flutter Web (5-10 minutes)")
    print("="*80)
    
    if not run_cmd(
        [str(flutter), "build", "web", "--release"],
        APP_DIR,
        "Building Flutter web"
    ):
        log("Flutter web build failed", False)
        return 1
    
    log("Flutter web built")
    
    # Step 4: Gradle
    print("\n" + "="*80)
    print("  STEP 4: Build Gradle Plugins (5-15 minutes)")
    print("="*80)
    
    if not run_cmd(
        ["gradlew.bat", "build", "-x", "test"],
        ENGINE_DIR,
        "Building Gradle"
    ):
        log("Gradle build failed", False)
        return 1
    
    log("Gradle build complete")
    
    # Success!
    print("\n" + "="*80)
    print("  ✓ BUILD COMPLETE!")
    print("="*80)
    print("\n  Artifacts:")
    print(f"    • JARs: {ROOT / 'build' / 'libs'}")
    print(f"    • Web: {APP_DIR / 'build' / 'web'}")
    print("\n  Next:")
    print("    1. Copy JARs to server plugins/")
    print("    2. Restart server")
    print("    3. Test localized nodes in-game\n")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
