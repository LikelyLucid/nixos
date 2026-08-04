#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
temporary_directory=$(mktemp -d)
trap 'rm -rf "$temporary_directory"' EXIT
repository="$temporary_directory/repository"
bin="$temporary_directory/bin"
mkdir -p "$repository/.githooks" "$repository/modules" "$repository/scripts" "$bin"

cp "$root/.githooks/pre-commit" "$repository/.githooks/pre-commit"
cp "$root/scripts/check-dendritic.py" "$repository/scripts/check-dendritic.py"

cat > "$repository/dendritic-policy.json" <<'EOF'
{
  "homeManagerModuleGroups": ["common"],
  "nixosModuleGroups": ["common"],
  "hosts": {},
  "localOptionModules": []
}
EOF
cat > "$repository/flake.nix" <<'EOF'
{ outputs = _: { }; }
EOF
cat > "$repository/modules/example.nix" <<'EOF'
{ ... }:
{
  nixos.modules.common = { };
}
EOF

for command in nixfmt statix deadnix nix-instantiate; do
  cat > "$bin/$command" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
for argument in "$@"; do
  if [[ -f $argument ]] && grep -q WORKTREE_ONLY "$argument"; then
    echo "checker read unstaged content: $argument" >&2
    exit 1
  fi
done
EOF
  chmod +x "$bin/$command"
done

(
  cd "$repository"
  git init -q
  git config user.name Test
  git config user.email test@example.com
  git config core.hooksPath .githooks
  git add .

  printf '\nWORKTREE_ONLY = true;\n' >> modules/example.nix
  PATH="$bin:$PATH" .githooks/pre-commit
  if git show :modules/example.nix | grep -q WORKTREE_ONLY; then
    echo "pre-commit staged an unstaged hunk" >&2
    exit 1
  fi

  git add modules/example.nix
  if PATH="$bin:$PATH" .githooks/pre-commit 2>/dev/null; then
    echo "pre-commit accepted an unsupported staged top-level contribution" >&2
    exit 1
  fi
)

echo "pre-commit snapshot isolation: passed"
