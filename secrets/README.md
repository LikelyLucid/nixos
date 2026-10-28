# SOPS Secrets

Store your encrypted `secrets.yaml` files here. Do not commit real secrets to version control.

`agent-server.yaml` is a separate SOPS document for the coding server's proxy
and Tailscale credentials. Only ciphertext belongs in Git. Enroll the server's
SSH host identity once with `nix run .#agent-server-enroll-secrets -- /mnt`;
see [Coding agent server](../docs/agent-server.md). The host then decrypts its
credentials automatically during boot.
