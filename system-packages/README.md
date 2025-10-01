# System Packages

Cross-platform system package management for workstations. Manage package lists across macOS (Homebrew), Ubuntu (apt), and Fedora (dnf).

## Installation

```bash
mt install system-packages
```

## Usage

```bash
system-packages [SUBCOMMAND] [OPTIONS]
```

### Subcommands

- `list` - List packages from package list (default)
- `diff` - Show differences between list and installed
- `install` - Install packages from package list
- `save` - Save currently installed packages to list
- `user-installed` - List user-installed packages
- `edit` - Edit package list for current OS
- `upgrade` - Upgrade all packages
- `completion` - Generate shell completion scripts

### Examples

```bash
system-packages                    # List packages
system-packages diff               # Show what's missing or extra
system-packages install            # Install all packages from list
system-packages save               # Save current packages to list
system-packages edit               # Edit package list
system-packages upgrade            # Upgrade all packages
```

### Shell Completion

Add to your `~/.bashrc`:

```bash
source <(system-packages completion bash)
```

## Package Lists

Package lists are stored in `~/.config/metool/packages/`:

- **macOS**: `homebrew-packages.txt`
- **Ubuntu**: `ubuntu-packages.txt`
- **Fedora**: `fedora-packages.txt`

## Requirements

- bash 4.0+
- `realpath` command (install `coreutils` on macOS: `brew install coreutils`)
- Platform-specific package managers: `brew` (macOS), `apt` (Ubuntu), `dnf` (Fedora)
