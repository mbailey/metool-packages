#!/usr/bin/env bash
# test-helper.bash - Common test functions for shadow package tests

# Get the absolute path to the shadow command
# BATS_TEST_DIRNAME is the directory of the current test file
# We need to go up one level from tests/ to get to the package root
SHADOW_PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export SHADOW_CMD="${SHADOW_PKG_DIR}/bin/shadow"

# Create a temporary test directory
setup_test_dir() {
    export TEST_DIR="$(mktemp -d)"
    export ORIG_DIR="$(pwd)"
    cd "${TEST_DIR}"
}

# Clean up test directory
teardown_test_dir() {
    cd "${ORIG_DIR}"
    rm -rf "${TEST_DIR}"
}

# Create a mock git repository
create_git_repo() {
    local repo_name="${1:-main-repo}"
    mkdir -p "${repo_name}"
    cd "${repo_name}"
    git init --quiet
    git config user.email "test@example.com"
    git config user.name "Test User"
    echo "# ${repo_name}" > README.md
    git add README.md
    git commit -m "Initial commit" --quiet
    cd ..
}

# Create a shadow repository with basic structure
create_shadow_repo() {
    local shadow_name="${1:-myshadow}"
    local main_repo="${2:-main-repo}"
    
    mkdir -p "${shadow_name}"
    cd "${shadow_name}"
    git init --quiet
    git config user.email "test@example.com"
    git config user.name "Test User"
    
    # Create a basic README to make it a valid repo
    echo "# Shadow Repository" > README.md
    
    git add .
    git commit -m "Initial shadow commit" --quiet
    cd ..
}

# Create a .shadowfile with given content
create_shadowfile() {
    local content="$1"
    echo "$content" > .shadowfile
}

# Assert that a symlink exists and points to the correct target
assert_symlink() {
    local link="$1"
    local expected_target="$2"
    
    [[ -L "$link" ]] || fail "Expected '$link' to be a symlink"
    
    local actual_target="$(readlink "$link")"
    [[ "$actual_target" == "$expected_target" ]] || \
        fail "Expected '$link' to point to '$expected_target', but it points to '$actual_target'"
}

# Assert that a file contains specific content
assert_file_contains() {
    local file="$1"
    local content="$2"
    
    [[ -f "$file" ]] || fail "Expected file '$file' to exist"
    grep -q "$content" "$file" || fail "Expected '$file' to contain '$content'"
}

# Count symlinks in current directory
count_symlinks() {
    find . -type l | wc -l
}

# Count symlinks pointing to a specific shadow repo
count_shadow_symlinks() {
    local shadow_path="$1"
    local count=0
    
    while IFS= read -r -d '' symlink; do
        local target=$(readlink "$symlink" 2>/dev/null)
        if [[ "$target" =~ ^"$shadow_path" ]] || [[ "$target" =~ ^\.\./.*"$shadow_path" ]]; then
            ((count++))
        fi
    done < <(find . -type l -print0 2>/dev/null)
    
    echo "$count"
}

# Run shadow command with NO_COLOR set
run_shadow_no_color() {
    NO_COLOR=1 run "${SHADOW_CMD}" "$@"
}

# Check if output contains ANSI color codes
has_color_codes() {
    local output="$1"
    [[ "$output" =~ $'\033\[' ]]
}

# Create a file with specific content
create_file() {
    local path="$1"
    local content="${2:-Test content}"
    mkdir -p "$(dirname "$path")"
    echo "$content" > "$path"
}

# Create a directory structure
create_dir_structure() {
    local base="$1"
    shift
    for path in "$@"; do
        mkdir -p "${base}/${path}"
    done
}