#!/usr/bin/env bash
set -euo pipefail

echo "Verifying shadow package tests..."
echo "================================"

# Check if bats is installed
if ! command -v bats &> /dev/null; then
    echo "ERROR: bats not found. Please install bats-core first."
    echo "  macOS: brew install bats-core"
    echo "  Ubuntu: sudo apt-get install bats"
    exit 1
fi

echo "✓ bats is installed"

# Check if shadow command exists
if [ ! -x "bin/shadow" ]; then
    echo "ERROR: bin/shadow not found or not executable"
    exit 1
fi

echo "✓ shadow command exists"

# Run a simple unit test
echo ""
echo "Running a sample test..."
bats tests/unit/test-shadow-add.bats -f "fails when not in git repo"

echo ""
echo "Test infrastructure is set up correctly!"
echo ""
echo "To run all tests:"
echo "  make test"
echo ""
echo "To run specific test suites:"
echo "  make test-unit"
echo "  make test-integration"