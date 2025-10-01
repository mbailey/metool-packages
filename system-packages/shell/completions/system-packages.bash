# Bash completion for system-packages command

_system_packages_completion() {
    local cur prev subcommands
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # Available subcommands
    subcommands="list diff install save user-installed edit upgrade completion"

    # If we're completing the first argument (subcommand)
    if [[ ${COMP_CWORD} -eq 1 ]]; then
        COMPREPLY=( $(compgen -W "${subcommands}" -- "${cur}") )
        return 0
    fi

    # Subcommand-specific completions
    case "${prev}" in
        completion)
            COMPREPLY=( $(compgen -W "bash zsh fish" -- "${cur}") )
            ;;
        *)
            # Default: complete with help flags
            if [[ ${cur} == -* ]]; then
                COMPREPLY=( $(compgen -W "-h --help" -- "${cur}") )
            fi
            ;;
    esac
}

complete -F _system_packages_completion system-packages
