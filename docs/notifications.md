# Notifications

Hokum owns `org.freedesktop.Notifications`. Open **Hokum** from the application
launcher, press `Super + N`, or run `hokum` to show its settings window.

Hokum is a single process: the service draws the cards on a click-through
layer-shell overlay and hosts the settings window. The cards are not an
application window, so they do not take focus or appear in the window list.

The desktop Home Manager feature is in `modules/desktop/hokum.nix`. The daemon
is packaged from the pinned upstream v0.1.2 linux-x64 release and exposed as
`packages.hokum`, with its ELF dependencies adapted to NixOS.

## Service

Hokum starts on demand: the unit is `Type=dbus` with
`BusName=org.freedesktop.Notifications`, and the D-Bus activation file in
`~/.local/share/dbus-1/services/` lets the first notification start it. It also
starts with the graphical session and restarts on failure. The unit is skipped
when `WAYLAND_DISPLAY` is unset, so it does not attempt to run on a TTY.

```sh
systemctl --user status hokum
journalctl --user -u hokum
hokum check            # report problems in config.kdl or a theme
```

If another daemon already owns the bus name, `hokum service` refuses to start
and says which one. Stop it first, or pass `--replace`.

## Configuration

Hokum reads `~/.config/hokum/config.kdl`. This configuration keeps that file in
`~/dotfiles/hokum/config.kdl` and symlinks it out of the store, because Hokum
rewrites it in place when Do not disturb or the theme changes. A read-only
store symlink would break `hokum dnd` and the settings window.

The file picks the wallust theme and sets behaviour:

```kdl
theme "~/dotfiles/hokum/wallust.kdl"

behaviour {
    position "top-right"
    stay 5
    show-at-most 5
    pause-on-hover #true
    do-not-disturb #false
    appearance "dark"
}
```

`behaviour` lives only here, never in a theme. The appearance switch and the
Behaviour page in the settings window write this block; each app's page writes a
`rule app="…"` block. Hand edits apply as you save.

## Theme

The look is generated from the wallpaper palette, so palette changes reach
Hokum live:

```text
~/dotfiles/wallust/templates/hokum.kdl   template, edited by hand
~/dotfiles/hokum/wallust.kdl             generated output, committed
```

Edit the template, not the output. Run `wallust run ~/dotfiles/media/wallpapers/wallpaper.jpg`
to regenerate, then `hokum check` to validate.

The theme follows the rest of the desktop: 7 px radius, JetBrains Mono at 13 px,
the wallust panel colour at 94% opacity, a 1 px hairline border, a flat shadow,
and an accent stripe down the left edge that turns red for critical
notifications.

`hokum check [path]` validates a theme or config file and reports problems with
line numbers. Render a theme without a compositor to inspect it:

```sh
hokum --snap /tmp/cards.png --scene hokum
```

## Do not disturb

```sh
hokum dnd          # print on or off
hokum dnd toggle   # or: on, off
hokum dnd --json   # {"dnd":false}
```

These commands need the service running; they talk to it over D-Bus. Do not
disturb is also on the Waybar bell, in the rofi system menu, and in the eww
system panel. While it is on, only critical notifications and apps whose rule
sets `interrupt` are shown.

## Dismissing

`hokum dismiss` closes the visible card; `hokum dismiss --all` clears them. The
desktop's clear action asks for confirmation first, because Hokum keeps no
retrievable history after a card is gone.

## What is not available

Hokum has no count or history API. The desktop shell therefore shows Do not
disturb state rather than an unread count, and the eww notifications panel opens
Hokum's settings instead of listing past notifications.
