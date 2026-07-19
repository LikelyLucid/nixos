# Encrypted home backups

The desktop defines a dormant daily Restic job named `home`. It backs up
`/home/lucid`, excludes reproducible caches and dependency directories, and
keeps seven daily, five weekly, twelve monthly, and three yearly snapshots.

The job starts only when both of these files exist:

- `/etc/restic/repository` — one line containing an off-device Restic repository
- `/run/secrets/restic-password` — the repository password, provisioned by sops

Until then, the timer may be present but the service is cleanly skipped rather
than failing.

## Provision the destination

Choose storage that is physically separate from `artsxps`, such as an SFTP
repository on another machine or an object-storage repository. Do not use
another directory on the laptop as the only backup.

Example repository file:

```text
sftp:backup@server:/srv/restic/artsxps-home
```

Add `restic-password` to `secrets/secrets.yaml` with sops, then declare that
secret in the repository's sops module so it is materialized at
`/run/secrets/restic-password`. Create `/etc/restic/repository` with mode `0600`.

## Verify before relying on it

```bash
sudo systemctl start restic-backups-home.service
sudo systemctl status restic-backups-home.service
sudo restic --repository-file /etc/restic/repository \
  --password-file /run/secrets/restic-password snapshots
sudo restic --repository-file /etc/restic/repository \
  --password-file /run/secrets/restic-password check
```

Perform a test restore into an empty temporary directory at least once:

```bash
restore_dir=$(mktemp -d)
sudo restic --repository-file /etc/restic/repository \
  --password-file /run/secrets/restic-password \
  restore latest --target "$restore_dir"
```

A successful backup without a tested restore is not yet proven recovery.
