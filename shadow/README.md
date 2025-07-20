# Shadow

A command-line tool for managing project-related files that are accessible to both the developer and LLM, but are stored in separate "shadow" Git repositories and symlinked into the working project.

## Glossary

- **Shadow Repository**: A separate Git repository that contains private or augmented content for one or more projects
- **Single-repo Shadow**: A shadow repository dedicated to one project (pattern: `<project>-shadow`)
- **Multi-repo Shadow**: A shadow repository shared across multiple projects (pattern: `shadow-<category>`)
- **Shadow Content**: Files and directories stored in shadow repositories and accessed via symlinks
- **Shadowfile**: The `.shadowfile` that lists all shadow repositories used by a project

## Quick Start

```bash
# Check current shadow status
shadow status

# Add a shadow repository to your project
shadow add ../my-project-shadow

# Extract sensitive files to shadow repo
shadow extract docs/private ../my-project-shadow
shadow extract tasks/personal.md ../my-project-shadow

# Import content back from shadow to main repo
shadow import docs/private

# Sync all shadow symlinks
shadow sync

# Keep git excludes up to date (prevents shadow content from being committed)
shadow sync-excludes
```

## Problem Statement

When working on projects, there's often a need for:
- Task files and documentation visible to the LLM but not in the main repo
- Promotional/marketing strategies that shouldn't be public
- Competitive analysis and business planning
- Personal notes and private documentation
- Cross-project shared resources

## Use Cases

1. **Private Promotion Strategies**: Marketing plans for open source projects that shouldn't be public
2. **Competitive Analysis**: Research on competitors (both proprietary and open source)
3. **Personal Task Management**: Tasks specific to individual developers
4. **Sensitive Documentation**: Communications, plans, or strategies not suitable for public repos
5. **Cross-Project Resources**: Shared documentation used across multiple projects

## Proposed Solution: Shadow Repository Pattern

### Concept

A "shadow repository" mirrors the structure of the main repo but contains private/augmented content. The shadow repo itself contains the knowledge of where its files should be symlinked.

### Directory Structure

```
# Main repo
voicemode/
├── .gitignore               # Ignores symlinked content
├── docs/
│   ├── tasks/
│   │   └── private/        # Symlink -> shadow repo
│   └── promote-private/    # Symlink -> shadow repo

# Shadow repo (e.g., voicemode-shadow/)
voicemode-shadow/
├── docs/
│   ├── tasks/
│   │   └── private/        # Will be linked to main's docs/tasks/private
│   └── promote-private/    # Will be linked to main's docs/promote-private
├── scripts/
│   └── link-shadow.sh      # Creates symlinks based on directory structure
└── README.md               # Documents this shadow repo's purpose
```

## Commands

The `shadow` command provides several subcommands for managing shadow repositories:

### Core Commands

- **`shadow status`** - Show status of all shadow repositories and symlinks
- **`shadow add <shadow-repo-path>`** - Add a shadow repository to the current project
- **`shadow extract <path> <shadow-repo>`** - Move content to shadow repo and create symlink
- **`shadow import <path>`** - Import content back from shadow to main repo (removes symlink)
- **`shadow sync`** - Create/update all symlinks from shadow repositories
- **`shadow sync-excludes`** - Update `.git/info/exclude` to ignore shadow symlinks
- **`shadow sync-repos`** - Sync git status across all shadow repositories

### Command Examples

```bash
# Check what shadow repos are configured
shadow status

# Add a new shadow repository
shadow add ../my-project-private

# Move sensitive documentation to shadow
shadow extract docs/internal ../my-project-private
shadow extract plans/marketing.md ../my-project-private

# Bring content back to main repo when ready to publish
shadow import docs/internal

# Update symlinks after changes to shadow repos
shadow sync

# Ensure git ignores shadow content properly  
shadow sync-excludes
```

### Command Options

Most commands support standard options:
- **`-h, --help`** - Show help for the command
- **`-f, --force`** - Skip confirmation prompts (where applicable)

## Installation

Ensure the `bin/shadow` script is in your PATH.

## Example Workflow

Here's a complete example of using the shadow system for a project:

```bash
# 1. Start in your main project
cd dj

# 2. Create a shadow repository for private content  
mkdir ../dj-shadow
cd ../dj-shadow
git init
echo "# Private beats and mix plans for dj project" > README.md
git add README.md
git commit -m "Initial shadow commit"

# 3. Return to main project and add the shadow
cd ../dj
shadow add ../dj-shadow

# 4. Move sensitive content to shadow
shadow extract docs/unreleased-tracks ../dj-shadow
shadow extract gigs/private-bookings.md ../dj-shadow

# 5. Check status - should show symlinks are working
shadow status

# 6. Work normally - LLM and tools can see the content via symlinks
cat docs/unreleased-tracks/summer-mix.md  # This works transparently

# 7. When ready to release a track, import it back
shadow import docs/unreleased-tracks/summer-mix.md

# 8. Keep git excludes up to date (prevents accidental commits of shadow symlinks)
shadow sync-excludes
```

## Shadow Repository Patterns

### Naming Conventions

Shadow repositories follow specific naming conventions that the tools automatically recognize:

**Single-Project Shadows**
- **Pattern**: `<repo-name>-shadow`
- **Purpose**: Private content for a specific project only
- **Structure**: Files are symlinked directly from shadow root

```bash
# Examples
dj/          # Main repository  
dj-shadow/   # Private content for this project only

voicemode/
voicemode-shadow/

my-awesome-project/
my-awesome-project-shadow/
```

**Multi-Project Shared Shadows**
- **Pattern**: `shadow-<category>`
- **Purpose**: Content shared across multiple projects
- **Structure**: Contains subdirectories named after each project

```bash
# Examples
shadow-tasks/         # Shared task management
├── dj/              # Tasks for dj project
├── voicemode/       # Tasks for voicemode project
└── metool/          # Tasks for metool project

shadow-marketing/     # Marketing content for multiple projects
shadow-research/      # Research notes and competitive analysis
```

**How It Works**:
- The shadow tools automatically detect the naming pattern
- For `repo-shadow`: Files are symlinked directly
- For `shadow-*`: Tools look for a subdirectory matching the current repo name

### Example Multi-Project Setup

```bash
# Create a shared task shadow for multiple projects
mkdir shadow-tasks
cd shadow-tasks
git init

# Create project-specific directories
mkdir -p project-1 project-2
echo "# Project 1 Tasks" > project-1/tasks.md
echo "# Project 2 Tasks" > project-2/tasks.md
git add .
git commit -m "Initial task structure"

# Use from project-1
cd ../project-1
shadow add ../shadow-tasks
# Shadow tools will look for shadow-tasks/project-1/ and symlink its contents

# Use from project-2  
cd ../project-2
shadow add ../shadow-tasks
# Shadow tools will look for shadow-tasks/project-2/ and symlink its contents
```

### Shadow Repository Discovery

For projects using the `github.com/user/repo` checkout pattern:

1. **Naming Convention**: Shadow repos use `-shadow` suffix
   - Main: `github.com/user/project`
   - Shadow: `github.com/user/project-shadow`

2. **Multiple Shadows**: A `.shadowfile` lists shadow repository paths:
   ```
   # .shadowfile - List of shadow repository paths
   # Comments start with #, blank lines allowed
   
   # Main shadow for this project
   ../voicemode-shadow
   
   # Shared task management across projects
   ../../shadow-tasks
   
   # Competitive analysis (different host)
   ../../../gitlab.com/user/competitive-shadow
   ```
   
   Format rules:
   - One shadow repo path per line
   - Comments: Lines starting with `#`
   - Blank lines: Allowed for organization
   - Paths: Relative to main repo root
   - Shadow repos contain their own structure that mirrors where content should be linked

3. **Discovery Order**:
   - Check `.shadowfile` for explicit paths
   - Look for `<repo>-shadow` in same parent directory
   - Search parent paths for `*/<repo>-shadow`

### Gitignore Strategy

**Key Principle**: The public repository should have NO trace of the shadow system.

1. **Use .git/info/exclude** for ALL shadow-related ignores:
   ```
   # In .git/info/exclude (never committed)
   .shadowfile
   docs/tasks/private
   docs/promote-private
   # ... other shadow symlinks
   ```

2. **Main .gitignore**: Contains only standard project ignores, no shadow references

3. **Benefits**:
   - Public repo stays completely clean
   - No hints about private content structure
   - Each developer manages their own shadow ignores
   - Shadow setup is invisible to outside observers

### Example Workflow

1. Clone main repo: `git clone github.com/user/project`
2. Clone shadow repo: `git clone github.com/user/project-shadow`
3. Run shadow sync: `cd project && shadow sync`
4. Work normally - LLM sees both public and private content
5. Extract sensitive file: `shadow extract docs/internal-strategy.md ../project-shadow`

### Benefits

1. **Separation of Concerns**: Public vs. private content clearly separated
2. **Version Control**: Each repo maintains its own history
3. **Flexibility**: Easy to include/exclude augmented content
4. **Security**: Sensitive data never enters public repo
5. **Reusability**: Augmented content can be shared across projects

### Considerations

1. **LLM Access**: Ensure LLMs can follow symlinks
2. **Platform Compatibility**: Symlinks work differently on Windows
3. **Documentation**: Clear indicators of what's augmented vs. native
4. **Backup Strategy**: Augmented repos need separate backup
5. **Team Collaboration**: How to share private augmentations

## Implementation Tasks

- [ ] Design augmentation directory structure
- [ ] Create .gitignore patterns for augmented content  
- [ ] Implement symlink creation script
- [ ] Document setup process for new developers
- [ ] Create example private repo structure
- [ ] Test LLM access to symlinked content
- [ ] Consider alternative to symlinks for Windows

## Security Notes

- Never commit sensitive information to public repos
- Use separate Git hosting for private augmentations
- Consider encrypted repos for highly sensitive data
- Regular audit of what's public vs. private
