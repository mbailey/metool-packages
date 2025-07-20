# Shadow Package Tests

This directory contains the test suite for the shadow package, using the bats (Bash Automated Testing System) framework.

## Prerequisites

Install bats-core:

```bash
# macOS
brew install bats-core

# Ubuntu/Debian
sudo apt-get install bats

# Using npm
npm install -g bats

# From source
git clone https://github.com/bats-core/bats-core.git
cd bats-core
./install.sh /usr/local
```

## Running Tests

Use the provided test runner:

```bash
# Run all tests
./run-tests.sh

# Run with verbose output
./run-tests.sh -v

# Run only unit tests
./run-tests.sh --unit

# Run only integration tests
./run-tests.sh --integration

# Run tests matching a pattern
./run-tests.sh -f "status"
```

Or use bats directly:

```bash
# Run all tests
bats unit/*.bats integration/*.bats

# Run specific test file
bats unit/test-shadow-status.bats

# Run with verbose output
bats -v unit/*.bats

# Run specific test by name
bats unit/test-shadow-add.bats -f "creates .shadowfile"
```

## Test Structure

```
tests/
├── README.md           # This file
├── run-tests.sh        # Test runner script
├── test-helper.bash    # Common test functions
├── unit/               # Unit tests for individual commands
│   ├── test-shadow-status.bats
│   ├── test-shadow-add.bats
│   └── ... (more to be added)
├── integration/        # Integration tests for workflows
│   ├── test-full-workflow.bats
│   └── ... (more to be added)
└── fixtures/           # Test data and templates
    └── ... (to be added)
```

## Writing Tests

### Basic Test Structure

```bash
#!/usr/bin/env bats

# Load test helper
load ../test-helper

setup() {
    setup_test_dir
}

teardown() {
    teardown_test_dir
}

@test "description of what is being tested" {
    # Arrange
    create_git_repo "test-repo"
    cd test-repo
    
    # Act
    run "${SHADOW_CMD}" status
    
    # Assert
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "expected text" ]]
}
```

### Available Helper Functions

From `test-helper.bash`:

- `setup_test_dir` - Creates temporary test directory
- `teardown_test_dir` - Cleans up test directory
- `create_git_repo "name"` - Creates a mock git repository
- `create_shadow_repo "name"` - Creates a shadow repository with sample content
- `create_shadowfile "content"` - Creates .shadowfile with given content
- `assert_symlink "link" "target"` - Verifies symlink points to target
- `assert_file_contains "file" "content"` - Checks file contains text
- `count_symlinks` - Counts symlinks in current directory
- `count_shadow_symlinks "path"` - Counts symlinks to specific shadow
- `run_shadow_no_color` - Runs shadow with NO_COLOR set
- `has_color_codes "text"` - Checks if text contains ANSI colors
- `create_file "path" "content"` - Creates a file with content
- `create_dir_structure "base" "path1" "path2" ...` - Creates directories

### Test Guidelines

1. **Test Independence**: Each test should be independent and not rely on others
2. **Clear Names**: Use descriptive test names that explain what is being tested
3. **Arrange-Act-Assert**: Structure tests with clear setup, execution, and verification
4. **Edge Cases**: Test error conditions and edge cases, not just happy paths
5. **Clean Up**: Always clean up temporary files/directories in teardown

### Common Patterns

Testing command output:
```bash
run "${SHADOW_CMD}" status
[ "$status" -eq 0 ]
[[ "${output}" =~ "expected text" ]]
```

Testing file creation:
```bash
run "${SHADOW_CMD}" add ../shadow
[ -f ".shadowfile" ]
assert_file_contains ".shadowfile" "../shadow"
```

Testing error conditions:
```bash
run "${SHADOW_CMD}" import non-existent
[ "$status" -eq 1 ]
[[ "${output}" =~ "Error" ]]
```

## Coverage Goals

- [ ] All commands have basic functionality tests
- [ ] Error conditions are tested
- [ ] Edge cases (spaces in names, missing files, etc.)
- [ ] Integration between commands
- [ ] NO_COLOR environment variable support
- [ ] Git integration (commits, excludes)
- [ ] Multi-shadow repository scenarios

## Continuous Integration

Tests should be run on:
- Push to main branch
- Pull requests
- Multiple platforms (Linux, macOS, WSL)

## Debugging Tests

When a test fails:

1. Run with verbose mode: `./run-tests.sh -v`
2. Add debugging output in tests: `echo "Debug: $variable" >&3`
3. Run single test: `bats -f "test name" unit/test-file.bats`
4. Check test artifacts in temp directories (if test fails before cleanup)