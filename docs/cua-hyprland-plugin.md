# CUA Hyprland agent seats

The desktop configuration loads CUA's optional Hyprland plugin with its input v3
build enabled. The plugin source comes from the same pinned `cua-driver` input
as the driver. `modules/ai/cua-hyprland-plugin.nix` builds it with the configured
compositor's headers, libraries, and compiler. The build runs the upstream CTest
suite and verifies dynamic C++ runtime linkage.

Hyprland loads the module from its Home Manager Lua configuration and enables
the local transport with `plugin.cua.enabled = true`. The two lanes use independent
`Cua-Agent` and `Cua-Agent-2` seats. Driver permissions still apply to each action.

Inspect the running module with:

```bash
hyprctl plugin list
hyprctl -j cua:status
```

Expected status includes `abi.match: true`, `configured: true`,
`transport.ready: true`, `state: input_v3_candidate`, and two entries in
`input.lanes`. This confirms the module and transport, not application delivery.

The initial installation passed all 20 upstream build tests and both manual
loading and automatic Lua startup loading in disposable nested Hyprland sessions.
The test compositor had physical-seat access disabled and its own runtime directory.
No application input was injected during these installation checks.

## Compatibility limits

Upstream's recorded raw background-input qualification covers the specific Arch
Calc and Inkscape builds in [PR #3572](https://github.com/trycua/cua/pull/3572).
Installing this plugin on NixOS does not qualify other application packages.
Chromium, Electron, XWayland raw input, Unicode, IME, multiple layouts, and modified
pointer gestures are outside that recorded qualification. Explicit foreground
actions can change focus and pointer position without restoring them.

The plugin checks the full Hyprland ABI fingerprint before other compositor APIs.
Rebuild the plugin and compositor together after an upgrade. Replace a loaded input
module by logging out and starting a new desktop session; its seat lifetime is
the compositor's lifetime. Do not hot-replace it with a newly built module.

To disable its transport temporarily, change the Lua configuration's
`plugin.cua.enabled` to `false` and reload Hyprland. A runtime keyword alone does
not reconcile the transport. To remove it permanently, remove this feature's
configuration contribution and apply the updated Home Manager configuration.
