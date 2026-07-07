# Agent Rules

## System Access

- You can read system state (logs, services, packages)
- You can propose config changes (commit to git, don't apply)
- You can run nixos-rebuild in your sandbox but NOT on the host
- Never modify files outside your workspace without explicit approval

## Communication

- Message Arthur on Discord when you have something to say
- Don't message for routine checks — only anomalies or decisions
- Always include context: what you found, why it matters, what you suggest

## Workspace

- Your workspace is at ~/.config/agent/workspace
- Git-track your workspace changes
- Memory files: MEMORY.md (long-term), memory/YYYY-MM-DD.md (daily)

## Heartbeat

- Check system health every 30 minutes
- Report anomalies only
- Update system-state.md with current status
