# Logs

Command output logging utilities for saving and sharing command results.

## Installation

```bash
mt install logs
```

## Tools

### log-command

Execute a command and save output to a timestamped log file.

**Usage:**
```bash
log-command [-h|--here] command [args...]
```

**Options:**
- `-h, --here` - Save log in current directory (default: `~/.logs`)
- `--help` - Show help message

**Examples:**

```bash
# Run a command and save output to ~/.logs/
log-command make lambda-invoke

# Re-run the previous command with logging
log-command !!

# Save log in current directory instead of ~/.logs/
log-command -h aws s3 ls s3://my-bucket

# Any command works
log-command docker ps -a
log-command curl -s https://api.example.com/status | jq .
```

**Features:**

- **Automatic timestamping**: Files are prefixed with timestamp (YYYYMMDD-HHMMSS) for chronological sorting
- **Smart filename sanitization**: Command is sanitized into a safe filename
- **Live output**: Uses `tee` so you see output while it's being logged
- **Organized storage**: Defaults to `~/.logs/` directory to keep logs centralized
- **Works with history**: Use `!!` to re-run and log your last command

**Log Filename Format:**

```
~/.logs/20241015-153045-make-lambda-invoke.log
        └──┬──┘ └──┬──┘ └────────┬─────────┘
     timestamp  time    sanitized command
```

**Dependencies:**

- Optional: `datestamp` command (from mt-public/time) for cleaner timestamps
- Falls back to `date +%Y%m%d-%H%M%S` if `datestamp` not available

## Use Cases

- **Sharing command results**: Run a command, capture output, commit the log file
- **Proof of work**: Demonstrate that a task was completed and show the results
- **Command history**: Keep a searchable history of important command outputs
- **Debugging**: Save error output for later analysis or sharing with team
- **Documentation**: Capture output for inclusion in reports or documentation
