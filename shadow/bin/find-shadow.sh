#!/usr/bin/env bash
# find-shadow.sh - Discover or create shadow repositories
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the current repository name
REPO_NAME=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

echo -e "${BLUE}Shadow Repository Discovery${NC}"
echo -e "Current repo: ${GREEN}$REPO_NAME${NC}"
echo

# Function to check if a directory is a git repo
is_git_repo() {
    [ -d "$1/.git" ] || git -C "$1" rev-parse --git-dir >/dev/null 2>&1
}

# Function to check for .shadowfile
check_shadowfile() {
    if [ -f "$REPO_ROOT/.shadowfile" ]; then
        echo -e "${GREEN}Found .shadowfile:${NC}"
        cat "$REPO_ROOT/.shadowfile"
        return 0
    fi
    return 1
}

# Function to look for shadow repos
find_shadows() {
    local shadows=()
    
    # Check parent directory for <repo>-shadow
    local parent_dir=$(dirname "$REPO_ROOT")
    local standard_shadow="$parent_dir/$REPO_NAME-shadow"
    
    if [ -d "$standard_shadow" ] && is_git_repo "$standard_shadow"; then
        shadows+=("$standard_shadow")
    fi
    
    # Look for shadow-tasks or other shadow-* repos in parent
    for shadow_dir in "$parent_dir"/shadow-*; do
        if [ -d "$shadow_dir" ] && is_git_repo "$shadow_dir"; then
            shadows+=("$shadow_dir")
        fi
    done
    
    # Look one level up for any *-shadow repos
    local grandparent_dir=$(dirname "$parent_dir")
    for shadow_dir in "$grandparent_dir"/*-shadow "$grandparent_dir"/shadow-*; do
        if [ -d "$shadow_dir" ] && is_git_repo "$shadow_dir"; then
            shadows+=("$shadow_dir")
        fi
    done
    
    printf '%s\n' "${shadows[@]}" | sort -u
}

# Main logic
echo "1. Checking for .shadowfile..."
if check_shadowfile; then
    echo
    echo "Use the shadow repositories listed in .shadowfile"
    exit 0
fi

echo -e "${YELLOW}No .shadowfile found${NC}"
echo

echo "2. Searching for shadow repositories..."
SHADOW_REPOS=($(find_shadows))

if [ ${#SHADOW_REPOS[@]} -eq 0 ]; then
    echo -e "${YELLOW}No shadow repositories found${NC}"
    echo
    
    # Show where shadows would be created
    PARENT_DIR=$(dirname "$REPO_ROOT")
    echo "Would you like to create a shadow repository?"
    echo -e "Location: ${BLUE}$PARENT_DIR${NC}"
    echo
    echo "Options:"
    echo "  1) $REPO_NAME-shadow (repo-specific shadow)"
    echo "     → $PARENT_DIR/$REPO_NAME-shadow"
    echo "  2) shadow-tasks (shared task shadow)"
    echo "     → $PARENT_DIR/shadow-tasks"
    echo "  3) Custom name"
    echo "  4) Skip"
    
    read -p "Choice [1-4]: " choice
    
    case $choice in
        1)
            SHADOW_NAME="$REPO_NAME-shadow"
            SHADOW_PATH="$(dirname "$REPO_ROOT")/$SHADOW_NAME"
            ;;
        2)
            SHADOW_NAME="shadow-tasks"
            SHADOW_PATH="$(dirname "$REPO_ROOT")/$SHADOW_NAME"
            ;;
        3)
            read -p "Enter shadow repo name: " SHADOW_NAME
            SHADOW_PATH="$(dirname "$REPO_ROOT")/$SHADOW_NAME"
            ;;
        4)
            echo "Skipping shadow creation"
            exit 0
            ;;
        *)
            echo "Invalid choice"
            exit 1
            ;;
    esac
    
    echo
    echo -e "Creating shadow repository: ${GREEN}$SHADOW_PATH${NC}"
    
    # Create shadow repo
    mkdir -p "$SHADOW_PATH"
    cd "$SHADOW_PATH"
    git init
    
    # Create initial structure
    mkdir -p scripts
    
    # Create link script
    cat > scripts/link-shadow.sh << 'EOF'
#!/usr/bin/env bash
# link-shadow.sh - Create symlinks from shadow to main repo
set -euo pipefail

MAIN_REPO="${1:?Usage: $0 <main-repo-path>}"
SHADOW_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "Linking shadow content to: $MAIN_REPO"

# Create symlinks for each directory in shadow
find "$SHADOW_ROOT" -mindepth 1 -maxdepth 3 -type d \
    -not -path "*/\.*" \
    -not -path "*/scripts" \
    -not -path "*/scripts/*" | while read -r shadow_dir; do
    
    # Get relative path from shadow root
    rel_path="${shadow_dir#$SHADOW_ROOT/}"
    target_dir="$MAIN_REPO/$rel_path"
    target_parent=$(dirname "$target_dir")
    
    # Skip if target already exists and is not a symlink
    if [ -e "$target_dir" ] && [ ! -L "$target_dir" ]; then
        echo "  Skipping $rel_path (already exists)"
        continue
    fi
    
    # Create parent directory if needed
    mkdir -p "$target_parent"
    
    # Create symlink
    ln -sfn "$shadow_dir" "$target_dir"
    echo "  Linked: $rel_path"
done

echo "Done! Remember to update .git/info/exclude in the main repo."
EOF
    
    chmod +x scripts/link-shadow.sh
    
    # Create README
    cat > README.md << EOF
# Shadow Repository: $SHADOW_NAME

This is a shadow repository for private/sensitive content that should not be in the public repository.

## Usage

1. Add content to this repository matching the structure of the main repo
2. Run \`./scripts/link-shadow.sh /path/to/main/repo\` to create symlinks
3. Update \`.git/info/exclude\` in the main repo to ignore shadow content

## Structure

Place files in this repository using the same directory structure as where they should appear in the main repository.

Example:
- \`docs/private/\` → will be linked to main repo's \`docs/private/\`
- \`tasks/personal/\` → will be linked to main repo's \`tasks/personal/\`
EOF
    
    git add .
    git commit -m "Initial shadow repository setup"
    
    echo
    echo -e "${GREEN}Shadow repository created successfully!${NC}"
    echo
    echo "Next steps:"
    echo "1. Add private content to: $SHADOW_PATH"
    echo "2. Run: cd $SHADOW_PATH && ./scripts/link-shadow.sh $REPO_ROOT"
    echo "3. Update $REPO_ROOT/.git/info/exclude with shadow patterns"
    
else
    echo -e "${GREEN}Found shadow repositories:${NC}"
    for shadow in "${SHADOW_REPOS[@]}"; do
        echo "  - $shadow"
    done
    echo
    echo "To use a shadow repository:"
    echo "1. Create a .shadowfile in the main repo with the shadow path(s)"
    echo "2. Or run the link script from the shadow repo"
fi