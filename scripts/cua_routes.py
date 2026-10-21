"""Prefer registered Tailscale endpoints before dispatching CUA work.

This selects a transport before a request. It never retries a dispatched action.
Lifecycle operations retain the relay identity, which owns the sandbox.
"""

import json
import os
from pathlib import Path
import subprocess
import sys
import threading
import urllib.error
import urllib.request

LIFECYCLE_TOOLS = {
    "delete_space", "remove_space", "start_space", "stop_space",
    "share_space", "unshare_space",
}


class Router:
    def __init__(self, routes, probe=None):
        self.routes = routes
        self.aliases = {route["direct"]: relay for relay, route in routes.items()}
        self.probe = probe or self.healthy
        self.last_routes = {}

    @staticmethod
    def healthy(route):
        # Ignore HTTP proxy environment variables: this address is inside the tailnet.
        try:
            cua_home = Path(os.environ.get("CUA_HOME", str(Path.home() / ".cua")))
            credentials = json.loads((cua_home / "spaces-credentials.json").read_text())
            if not credentials.get(route["direct"], {}).get("token"):
                return False
            opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
            with opener.open(route["url"].rstrip("/") + "/health", timeout=1.5) as response:
                return response.status == 204
        except (OSError, ValueError, urllib.error.URLError):
            return False

    def select(self, space):
        space = self.aliases.get(space, space)
        route = self.routes.get(space)
        if route is None:
            return space
        choice = space
        if os.environ.get("CUA_ROUTE_POLICY") != "relay" and self.probe(route):
            choice = route["direct"]
        if self.last_routes.get(space) != choice:
            transport = "tailscale" if choice != space else "relay"
            print(f"cua route: {space} via {transport}", file=sys.stderr, flush=True)
            self.last_routes[space] = choice
        return choice

    def request(self, message):
        if message.get("method") != "tools/call":
            return message
        params = message.get("params", {})
        arguments = params.get("arguments", {})
        space = arguments.get("space")
        if isinstance(space, str) and (space in self.routes or space in self.aliases):
            choice = (self.aliases.get(space, space)
                      if params.get("name") in LIFECYCLE_TOOLS else self.select(space))
            # Only the identity field changes. Text, paths and commands are literal.
            message = {**message, "params": {**params, "arguments": {
                **arguments, "space": choice,
            }}}
        return message

    def cli(self, arguments):
        arguments = arguments.copy()
        # Recognize identity positions only; never rewrite a shell command or prompt.
        if len(arguments) > 2 and (
            arguments[:2] in (["sb", "exec"], ["sandbox", "exec"], ["agent", "run"])
        ):
            arguments[2] = self.select(arguments[2])
        if arguments[:2] == ["teleport", "push"]:
            for index in range(2, len(arguments) - 1):
                if arguments[index] in ("--sandbox", "-s"):
                    arguments[index + 1] = self.select(arguments[index + 1])
                    break
        return arguments


def load_routes():
    config_home = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config")))
    path = Path(os.environ.get("CUA_ROUTES_FILE", str(config_home / "cua/routes.json")))
    if not path.exists():
        return {}
    routes = json.loads(path.read_text())
    if not isinstance(routes, dict):
        raise ValueError("CUA routes must be an object")
    for space, route in routes.items():
        if (not space.startswith("relay:") or not isinstance(route, dict)
                or not isinstance(route.get("direct"), str)
                or not route["direct"].startswith("direct:")
                or not isinstance(route.get("url"), str)
                or not route["url"].startswith(("http://", "https://"))):
            raise ValueError("Invalid CUA route")
    return routes


def mcp(upstream, arguments, router):
    process = subprocess.Popen([upstream, *arguments], stdin=subprocess.PIPE,
                               stdout=subprocess.PIPE, text=True)

    def forward_output():
        for line in process.stdout:
            sys.stdout.write(line)
            sys.stdout.flush()

    output = threading.Thread(target=forward_output, daemon=True)
    output.start()
    try:
        for line in sys.stdin:
            try:
                message = router.request(json.loads(line))
                line = json.dumps(message, separators=(",", ":")) + "\n"
            except (ValueError, TypeError):
                pass  # Let the actual MCP server report invalid JSON-RPC.
            process.stdin.write(line)
            process.stdin.flush()
        process.stdin.close()
        return process.wait()
    except (BrokenPipeError, KeyboardInterrupt):
        return process.poll() or 1
    finally:
        if process.poll() is None:
            process.terminate()
        process.wait()
        output.join(timeout=2)


def main():
    # Nix passes the upstream executable explicitly, so this cannot recurse.
    upstream, *arguments = sys.argv[1:]
    router = Router(load_routes())
    if arguments[:1] in (["mcp"], ["serve-mcp"]):
        return mcp(upstream, arguments, router)
    os.execv(upstream, [upstream, *router.cli(arguments)])


if __name__ == "__main__":
    raise SystemExit(main())
