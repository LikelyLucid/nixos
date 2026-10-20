"""Seed agent-browser's owned temporary browser directory from Helium."""

import json
import os
from pathlib import Path
import shutil
import sqlite3
import sys
from urllib.parse import quote


EXCLUDED = {
    "Cache", "Code Cache", "GPUCache", "DawnGraphiteCache", "DawnWebGPUCache",
    "ShaderCache", "GrShaderCache", "Service Worker", "blob_storage",
    "File System", "GCM Store", "optimization_guide", "component_crx_cache",
    "History", "History-journal", "Login Data", "Login Data-journal",
    "Login Data For Account", "Login Data For Account-journal",
    "Sessions", "LOCK", "SingletonLock", "SingletonCookie", "SingletonSocket",
}


def copy_profile(source_root, destination, profile_name):
    try:
        state = json.loads((source_root / "Local State").read_text())
    except FileNotFoundError:
        return
    profiles = state.get("profile", {}).get("info_cache", {})
    matches = [
        key for key, value in profiles.items()
        if value.get("name", "").casefold() == profile_name.casefold()
    ]
    if not matches:
        return
    if len(matches) != 1:
        raise ValueError(f"Expected one Helium profile named {profile_name!r}; found {len(matches)}")
    directory = matches[0]
    if directory != Path(directory).name or directory in {".", ".."}:
        raise ValueError("Invalid Helium profile directory")
    source = source_root / directory
    if not source.is_dir():
        return
    destination.chmod(0o700)

    def ignore(folder, names):
        return [
            name for name in names
            if name in EXCLUDED or name.endswith(("-wal", "-shm"))
            or (Path(folder) / name).is_symlink()
        ]

    copied_profile = destination / "Default"
    copied_profile.mkdir()
    # Transfer authentication storage, without desktop extensions, proxy settings,
    # or startup preferences that can block an automated headless browser.
    for relative in ("Local Storage", "IndexedDB", "Session Storage"):
        storage = source / relative
        if storage.is_dir():
            shutil.copytree(storage, copied_profile / relative, ignore=ignore)
    (copied_profile / "Preferences").write_text(json.dumps({"profile": {"name": profile_name}}))
    # Capture committed cookie writes from the live database's WAL as well.
    for relative in ("Cookies", "Network/Cookies"):
        database = source / relative
        if database.is_file():
            (copied_profile / relative).parent.mkdir(parents=True, exist_ok=True)
            uri = f"file:{quote(str(database))}?mode=ro"
            with sqlite3.connect(uri, uri=True, timeout=5) as original:
                with sqlite3.connect(destination / "Default" / relative) as copied:
                    original.backup(copied)
    state = {"os_crypt": state.get("os_crypt", {}), "profile": {
        "info_cache": {"Default": profiles[directory]},
        "last_used": "Default",
        "last_active_profiles": ["Default"],
    }}
    (destination / "Local State").write_text(json.dumps(state))
    (destination / ".agent-browser-helium-profile").write_text(profile_name)


def launch_arguments(arguments, source_root, profile_name):
    directory = next((a.split("=", 1)[1] for a in arguments if a.startswith("--user-data-dir=")), None)
    # Only seed the disposable directories agent-browser creates and owns.
    # Explicit --profile paths and named profiles keep their usual semantics.
    if profile_name.lower() != "none" and directory:
        destination = Path(directory)
        if destination.name.startswith("agent-browser-chrome-"):
            if not any(destination.iterdir()):
                copy_profile(source_root, destination, profile_name)
        if (destination / ".agent-browser-helium-profile").is_file():
            # Use Helium's real keyring backend to decrypt its copied cookies.
            arguments = [a for a in arguments if a not in {"--password-store=basic", "--use-mock-keychain"}]
            arguments.append("--profile-directory=Default")
    return arguments


if __name__ == "__main__":
    try:
        arguments = launch_arguments(
            sys.argv[2:],
            Path.home() / ".config/net.imput.helium",
            os.environ.get("AGENT_BROWSER_HELIUM_PROFILE", "AGASSIST"),
        )
    except (OSError, ValueError, sqlite3.Error) as error:
        sys.exit(f"Cannot seed the agent browser from Helium: {error}")
    os.execv(sys.argv[1], [sys.argv[1], *arguments])
