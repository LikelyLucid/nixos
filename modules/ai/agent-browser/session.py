"""Choose a stable browser session without sharing the default browser."""

import hashlib
import os
from pathlib import Path
import re
import sys


def agent_process():
    pid = os.getppid()
    while pid > 1:
        try:
            process = Path(f"/proc/{pid}")
            name = (process / "comm").read_text().strip()
            stat = (process / "stat").read_text().rsplit(")", 1)[1].split()
            if name in {"codex", "claude", "opencode", "pi", "hermes", "prime-agent"}:
                return f"{name}-{pid}-{stat[19]}"
            pid = int(stat[1])
        except (OSError, ValueError, IndexError):
            break
    return f"terminal-{os.getsid(0)}"


def session_name(environment, process):
    for key in (
        "AGENT_BROWSER_AGENT_ID",
        "CODEX_THREAD_ID",
        "CLAUDE_SESSION_ID",
        "OPENCODE_SESSION_ID",
        "T3_THREAD_ID",
    ):
        if environment.get(key):
            identity = f"{environment[key]}:{process}"
            label = re.sub(r"[^a-zA-Z0-9_-]", "-", environment[key])[:24]
            return f"{label}-{hashlib.sha256(identity.encode()).hexdigest()[:12]}"
    return process


def default_session(environment, process, arguments, pid):
    # A Codex app-server can own several MCP processes. Scope each connection
    # to its own lifetime rather than sharing its parent app-server's browser.
    if arguments[:1] == ["mcp"]:
        process = f"browser-mcp-{pid}"
    return session_name(environment, process)


if __name__ == "__main__":
    os.environ.setdefault(
        "AGENT_BROWSER_SESSION",
        default_session(os.environ, agent_process(), sys.argv[2:], os.getpid()),
    )
    os.execv(sys.argv[1], [sys.argv[1], *sys.argv[2:]])
