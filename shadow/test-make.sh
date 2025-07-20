#!/usr/bin/env bash
set -euo pipefail

echo "Current directory: $(pwd)"
echo "Shadow package directory contents:"
ls -la

echo -e "\nTesting make command:"
make help

echo -e "\nTesting if bats is installed:"
which bats || echo "bats not found"

echo -e "\nDone."