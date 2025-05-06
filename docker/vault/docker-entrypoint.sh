#!/bin/sh
set -e

# Run init scripts in /docker-entrypoint-initvault.d/
if [ -d "/docker-entrypoint-initvault.d" ]; then
  for script in /docker-entrypoint-initvault.d/*.sh; do
    if [ -f "$script" ]; then
      echo "Running $script..."
      sh "$script"
    fi
  done
fi

echo "Vault initialized"
