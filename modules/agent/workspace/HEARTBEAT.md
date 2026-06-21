# Heartbeat Checklist

- [ ] Check `df -h /` — alert if >80%
- [ ] Check `systemctl --user --failed` — report failures
- [ ] Check `journalctl -p err --since "30 min ago"` — new errors?
- [ ] Check Tailscale status: `tailscale status`
- [ ] Update `system-state.md`
