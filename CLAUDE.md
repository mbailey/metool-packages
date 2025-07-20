# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is the MeTool Packages repository, a collection of tools created as part of the [MeTool](https://github.com/mbailey/metool) ecosystem. Currently contains:

- **shadow**: A tool for managing project-related files stored in separate "shadow" Git repositories and symlinked into working projects

## Development Commands

### Testing

The shadow package uses bats-core for testing:

```bash
# Run all tests
cd shadow && make test

# Run unit tests only
cd shadow && make test-unit

# Run integration tests only
cd shadow && make test-integration

# Run tests with verbose output
cd shadow && make test-verbose

# Run specific test pattern
cd shadow && ./tests/run-tests.sh -f "status"
```

### Linting

```bash
# Lint shell scripts with shellcheck
cd shadow && make lint
```

### Installing Dependencies

```bash
# Install test dependencies (bats-core)
cd shadow && make install-deps
```

## Architecture

### Shadow Package Structure

The shadow tool follows a modular architecture:

- **bin/shadow**: Main entry point that delegates to subcommands
- **libexec/shadow-***: Individual subcommand implementations
  - `shadow-status`: Shows current shadow repository linkage
  - `shadow-add`: Adds a shadow repository to current project
  - `shadow-extract`: Moves content to shadow repo and creates symlink
  - `shadow-import`: Imports content back from shadow to main repo
  - `shadow-sync`: Creates/updates all symlinks from shadow repositories
  - `shadow-sync-excludes`: Updates .git/info/exclude with shadow paths
  - `shadow-sync-repos`: Syncs git status across shadow repositories

### Shadow Repository Pattern

Shadow repositories mirror the structure of main repos but contain private/augmented content:

1. **Discovery**: Looks for `.shadowfile` or `<repo>-shadow` in parent directory
2. **Symlink Creation**: Shadow content is symlinked into main repo at matching paths
3. **Git Exclusion**: Uses `.git/info/exclude` (never `.gitignore`) to prevent shadow content from being committed
4. **Transparency**: LLMs and tools see shadow content transparently through symlinks

### Testing Strategy

- **Unit Tests**: Test individual subcommands in isolation
- **Integration Tests**: Test full workflows across multiple commands
- **Test Helper**: `tests/test-helper.bash` provides common test utilities
- **Fixtures**: Test data stored in `tests/fixtures/`

## Key Design Principles

1. **No Public Traces**: Shadow system leaves no traces in public repositories
2. **Symlink-Based**: All shadow content accessed via symlinks
3. **Git-Native**: Each shadow repo is a full git repository
4. **Platform Aware**: Handles macOS/Linux differences (e.g., realpath availability)
5. **Color Support**: Respects NO_COLOR and non-TTY environments