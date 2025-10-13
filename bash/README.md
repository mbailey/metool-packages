# Bash

Shell prompt configuration and utilities for bash.

## Installation

```bash
mt install bash
```

## Components

- `shell/prompt` - Customizable bash prompt with git info, AWS/Azure profile display, and colorization

## Features

### Colorized Prompt

The prompt automatically colorizes usernames, hostnames, and cloud profiles for easy visual identification:

- User and hostname colorization based on hash
- Git branch and stash information
- AWS profile and region display
- Azure subscription and resource group display
- Automatic dark/light mode adaptation

### Prompt Functions

- `prompt` - Enable standard prompt with AWS info
- `prompt-long` (alias: `pl`) - Enable prompt with AWS and Azure info
- `prompt-short` (alias: `pz`) - Disable cloud info in prompt
- `prompt-shorter` (alias: `psr`) - Minimal prompt showing only current directory
- `prompt-aws [true|false]` - Toggle AWS info display
- `prompt-azure [true|false]` - Toggle Azure info display

### Git Integration

- Shows current branch name
- Displays stash count and last stash date
- Updates automatically with PROMPT_COMMAND

## Requirements

- bash 4.0+
- git (for git prompt features)
- Optional: aws CLI (for AWS profile display)
- Optional: az CLI (for Azure profile display)

## Configuration

The prompt is enabled by default when sourced. You can customize behavior with environment variables:

- `MT_PROMPT_AWS` - Set to "true" or "false" to control AWS info display
- `MT_PROMPT_AZURE` - Set to "true" or "false" to control Azure info display

## Usage Examples

```bash
# Standard prompt with AWS info
prompt

# Long prompt with AWS and Azure info
pl

# Short prompt without cloud info
pz

# Minimal prompt
psr

# Toggle AWS display
prompt-aws-toggle

# Toggle Azure display
prompt-azure-toggle
```
