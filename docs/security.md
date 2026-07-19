# Desktop security boundaries

The desktop configuration improves service isolation and recovery readiness, but
two protections cannot be enabled safely as an ordinary rebuild.

## Full-disk encryption

The Linux root filesystem is an unencrypted ext4 partition. LUKS encryption
must be designed into the storage layout and normally requires backing up,
repartitioning, restoring, and validating the system from external media. It is
therefore intentionally not attempted by this configuration.

Before the next reinstall:

1. Verify the Restic restore procedure in [`backups.md`](backups.md).
2. Use LUKS2 for the NixOS root filesystem.
3. Keep `/boot` free of secrets and use a strong recovery passphrase.
4. Store the recovery key somewhere physically separate from the laptop.

## Fingerprint authentication

The XPS exposes a Goodix `27c6:63ac` fingerprint reader. Fingerprint support was
not enabled because hardware presence does not prove that the installed
`libfprint` release supports enrollment and reliable matching. Enabling an
untested PAM path can make login and authorization less predictable.

Password authentication remains the dependable path for greetd, screen unlock,
sudo, and PolicyKit. Fingerprint authentication should only be added after a
successful disposable enrollment test and must never replace the password
fallback.

## Backups

The Restic service is deliberately dormant until an off-device repository and
sops-managed password exist. Synchronization through Syncthing is useful but is
not a substitute for an independently retained, tested backup.
