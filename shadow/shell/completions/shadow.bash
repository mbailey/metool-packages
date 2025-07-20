#!/usr/bin/env bash
# Bash completion for shadow command

_shadow() {
    local cur prev words cword
    _init_completion || return

    local commands="add extract import sync sync-repos sync-excludes status find"

    # Complete first argument with available commands
    if [[ $cword -eq 1 ]]; then
        COMPREPLY=( $(compgen -W "$commands" -- "$cur") )
        return 0
    fi

    # Get the subcommand
    local cmd="${words[1]}"

    case "$cmd" in
        import)
            # For import, only complete with symlinks that point to shadow repos
            _shadow_complete_shadow_symlinks
            ;;
        extract)
            # For extract, complete with regular files/dirs (not symlinks)
            _shadow_complete_non_symlinks
            ;;
        sync|sync-repos|sync-excludes|status|find)
            # These commands typically don't need file completion
            return 0
            ;;
        add)
            # For add, complete with directories
            _filedir -d
            ;;
        *)
            # Default file/directory completion
            _filedir
            ;;
    esac
}

# Complete only symlinks that point to shadow repositories
_shadow_complete_shadow_symlinks() {
    local cur="$cur"
    local shadow_roots=()
    
    # Read shadow file if it exists
    if [[ -f .shadowfile ]]; then
        while IFS= read -r line; do
            # Skip comments and empty lines
            [[ "$line" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$line" ]] && continue
            
            # Resolve the shadow repo path
            local shadow_path="$line"
            if [[ ! "$shadow_path" = /* ]]; then
                shadow_path="$(pwd)/$shadow_path"
            fi
            shadow_path=$(readlink -f "$shadow_path" 2>/dev/null || echo "$shadow_path")
            shadow_roots+=("$shadow_path")
        done < .shadowfile
    fi
    
    # Find symlinks in current directory and subdirectories
    local symlinks=()
    while IFS= read -r -d '' symlink; do
        # Get the target of the symlink
        local target=$(readlink "$symlink" 2>/dev/null)
        if [[ -n "$target" ]]; then
            # Resolve to absolute path
            local abs_target
            if [[ "$target" = /* ]]; then
                abs_target="$target"
            else
                local symlink_dir=$(dirname "$symlink")
                abs_target="$symlink_dir/$target"
            fi
            abs_target=$(readlink -f "$abs_target" 2>/dev/null || echo "$abs_target")
            
            # Check if this symlink points to any shadow root
            for shadow_root in "${shadow_roots[@]}"; do
                if [[ "$abs_target" =~ ^"$shadow_root" ]]; then
                    # Remove leading ./ if present
                    symlink="${symlink#./}"
                    symlinks+=("$symlink")
                    break
                fi
            done
        fi
    done < <(find . -type l -print0 2>/dev/null)
    
    # Generate completions
    if [[ ${#symlinks[@]} -gt 0 ]]; then
        COMPREPLY=( $(compgen -W "${symlinks[*]}" -- "$cur") )
    fi
}

# Complete with files/directories that are NOT symlinks
_shadow_complete_non_symlinks() {
    local cur="$cur"
    local files=()
    
    # Find all files and directories that are not symlinks
    while IFS= read -r -d '' file; do
        # Remove leading ./ if present
        file="${file#./}"
        files+=("$file")
    done < <(find . -maxdepth 3 ! -type l -print0 2>/dev/null | grep -zv '^\./\.git')
    
    # Generate completions
    if [[ ${#files[@]} -gt 0 ]]; then
        COMPREPLY=( $(compgen -W "${files[*]}" -- "$cur") )
    fi
    
    # Also use standard file completion for current directory
    _filedir
}

complete -F _shadow shadow