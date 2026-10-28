# Run from the checkout with the target root filesystem mounted. Only the
# target's public identity leaves that filesystem.
set -euo pipefail

target_root=$(realpath "${1:?Usage: agent-server-enroll-secrets /mnt}")
if [[ "$target_root" == / ]] || ! mountpoint -q "$target_root"; then
  echo "Expected a mounted target filesystem, such as /mnt, not the running root." >&2
  exit 1
fi
repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

export SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-$HOME/.secrets/age.agekey}"
if [[ ! -r "$SOPS_AGE_KEY_FILE" ]]; then
  echo "Set SOPS_AGE_KEY_FILE to your existing administrator age identity." >&2
  exit 1
fi
if [[ ! -f secrets/agent-server.yaml ]]; then
  echo "The encrypted server secrets file is missing." >&2
  exit 1
fi

sudo install -d -m 755 "$target_root/etc/ssh"
if ! sudo test -e "$target_root/etc/ssh/ssh_host_ed25519_key"; then
  sudo ssh-keygen -q -t ed25519 -N '' -f "$target_root/etc/ssh/ssh_host_ed25519_key"
fi
host_recipient=$(ssh-to-age -i "$target_root/etc/ssh/ssh_host_ed25519_key.pub")
config_file=$(mktemp "$repo_root/.sops-enrollment.XXXXXX.yaml")
trap 'rm -f "$config_file"' EXIT
cp .sops.yaml "$config_file"
existing_recipients=$(yq -r '.creation_rules[0].age' .sops.yaml)
case ",$existing_recipients," in
  *",$host_recipient,"*) ;;
  *) existing_recipients="$existing_recipients,$host_recipient" ;;
esac
export AGENT_SERVER_RECIPIENTS="$existing_recipients"
yq -i '.creation_rules[0].age = strenv(AGENT_SERVER_RECIPIENTS)' "$config_file"
sops --config "$config_file" updatekeys --yes secrets/agent-server.yaml
mv "$config_file" .sops.yaml
echo "Enrolled the target SSH identity for automatic secret decryption."
echo "Commit and push .sops.yaml and secrets/agent-server.yaml before installation."
