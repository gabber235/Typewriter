#!/usr/bin/env python3
"""Typewriter Build - Main Entry Point"""
import os
import sys

script_dir = os.path.dirname(__file__)

# Try clean script first, then fall back
for script in ["build_clean.py", "build_master_new.py", "build_master.py"]:
    script_path = os.path.join(script_dir, script)
    if os.path.exists(script_path):
        exit_code = os.system(f'{sys.executable} "{script_path}"')
        sys.exit(exit_code >> 8 if exit_code else 0)

print("Error: No build script found!")
sys.exit(1)
