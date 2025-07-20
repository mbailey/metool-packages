# Shadow Sync Algorithm Specification

## Overview

The `shadow sync` command creates symlinks from the main repository to content in shadow repositories. This document specifies the algorithm for intelligently traversing shadow repositories and creating the minimal set of symlinks needed.

## Current Issues

1. **Absolute vs Relative Symlinks**: Currently creates absolute symlinks, which breaks portability
2. **Over-traversal**: Attempts to create symlinks for files within already-symlinked directories
3. **Inefficient Linking**: Creates many small symlinks instead of linking at the highest possible directory level

## Proposed Algorithm

### Core Principles

1. **Use relative symlinks** for portability across different machines and paths
2. **Link at the highest possible level** to minimize the number of symlinks
3. **Never traverse into already-symlinked directories**
4. **Respect existing directory structure** in the main repository

### Algorithm Steps

```
function sync_shadow_repo(shadow_path, main_repo_path):
    for each top_level_item in shadow_path:
        sync_item(top_level_item, main_repo_path, shadow_path, "")

function sync_item(item_path, main_repo_path, shadow_path, relative_path):
    full_shadow_path = shadow_path + "/" + relative_path + "/" + item_path
    full_main_path = main_repo_path + "/" + relative_path + "/" + item_path
    
    # Check if already correctly symlinked
    if is_symlink(full_main_path):
        target = readlink(full_main_path)
        expected_target = calculate_relative_path(full_main_path, full_shadow_path)
        if target == expected_target:
            return  # Already correctly linked, skip this tree
        else:
            # Wrong target, will need to fix
            remove_symlink(full_main_path)
    
    # If item is a directory in shadow
    if is_directory(full_shadow_path):
        # Check if corresponding path exists in main repo
        if exists(full_main_path):
            if is_directory(full_main_path):
                # Directory exists in main, recurse into it
                for child in list_directory(full_shadow_path):
                    sync_item(child, main_repo_path, shadow_path, 
                             relative_path + "/" + item_path)
            else:
                # Conflict: file exists where we want directory symlink
                report_conflict(full_main_path)
        else:
            # Path doesn't exist, create symlink to entire directory
            create_relative_symlink(full_shadow_path, full_main_path)
    
    # If item is a file in shadow
    else:
        if exists(full_main_path) and !is_symlink(full_main_path):
            # Conflict: file exists where we want symlink
            report_conflict(full_main_path)
        else:
            # Create symlink to file
            parent_dir = dirname(full_main_path)
            ensure_directory_exists(parent_dir)
            create_relative_symlink(full_shadow_path, full_main_path)
```

### Key Functions

#### `create_relative_symlink(target, link_location)`
Creates a relative symlink from `link_location` to `target`.

Example:
- Target: `/home/user/project-shadow/docs/tasks`
- Link: `/home/user/project/docs/tasks`
- Relative symlink: `../../project-shadow/docs/tasks`

#### `calculate_relative_path(from_path, to_path)`
Calculates the relative path from one location to another.

### Example Scenarios

#### Scenario 1: Fresh Repository
Shadow repository structure:
```
shadow-repo/
├── docs/
│   ├── tasks/
│   │   ├── task1.md
│   │   └── task2.md
│   └── private-notes.md
└── scripts/
    └── deploy.sh
```

Main repository (empty):
```
main-repo/
└── README.md
```

Result after sync:
```
main-repo/
├── README.md
├── docs -> ../shadow-repo/docs
└── scripts -> ../shadow-repo/scripts
```

#### Scenario 2: Existing Directory Structure
Shadow repository:
```
shadow-repo/
├── docs/
│   ├── tasks/
│   │   └── private-task.md
│   └── api/
│       └── internal.md
```

Main repository (before sync):
```
main-repo/
├── docs/
│   ├── public.md
│   └── api/
│       └── public.md
```

Result after sync:
```
main-repo/
├── docs/
│   ├── public.md
│   ├── tasks -> ../../shadow-repo/docs/tasks
│   └── api/
│       ├── public.md
│       └── internal.md -> ../../../shadow-repo/docs/api/internal.md
```

#### Scenario 3: Already Symlinked Directory
Shadow repository:
```
shadow-repo/
├── docs/
│   └── tasks/
│       ├── subtask1/
│       │   └── details.md
│       └── subtask2/
│           └── info.md
```

Main repository (with existing symlink):
```
main-repo/
├── docs/
│   └── tasks -> ../../shadow-repo/docs/tasks
```

Result: No changes needed. The algorithm detects that `docs/tasks` is already correctly symlinked and skips traversing into it.

## Implementation Notes

1. **Symlink Creation**: Always use relative paths for portability
2. **Conflict Handling**: Report conflicts clearly but don't automatically overwrite
3. **Performance**: Check symlink targets before attempting to recreate
4. **Safety**: Never delete user files, only remove/update symlinks
5. **Logging**: Provide clear output about what is being linked and why

## Testing Considerations

1. Test with nested directory structures
2. Test with existing symlinks (both correct and incorrect targets)
3. Test with conflicts (files existing where symlinks are needed)
4. Test portability of relative symlinks across different paths
5. Test with multiple shadow repositories