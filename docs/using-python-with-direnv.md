# Using the Python devShell (uv) with direnv

This document explains how to activate and use the Python dev shell (with `uv`) provided by this flake via `direnv`. It follows the same local-first + pinned fallback pattern used for the TypeScript dev shell.

## Prerequisites

- Nix with flakes enabled.
- direnv installed and its shell hook loaded (`eval "$(direnv hook zsh)"` in `~/.zshrc`).
- The `nix-config` flake is available locally at `~/Documents/nix-config` or on GitHub at `github:rohanbatrain/nix-config`.

## Copy this `.envrc` into the `second_brain_database` project root

```sh
# .envrc - prefer local flake, fallback to pinned GitHub rev, then unpinned
CANDIDATES=(
  "$HOME/Documents/nix-config#python"
  "github:rohanbatrain/nix-config/a9cfc73bb234f92fe4f669b51d1c45f400cc43e6#python"
  "github:rohanbatrain/nix-config#python"
)

for c in "${CANDIDATES[@]}"; do
  if use flake "$c" 2>/dev/null; then
    echo "direnv: using flake $c"
    exit 0
  fi
done

echo "direnv: warning — no usable devShell found among candidates"
```

## How to use

1. Ensure `direnv` hook is loaded in your shell.
2. Place the `.envrc` above in `/Users/rohan/Documents/repos/second_brain_database`.
3. Run `direnv allow` in that project.

## Verify

After allowing and entering the directory:

```sh
python --version
pip --version
python -c "import uv; print('uv imported')" || echo "uv not importable"
```

## Troubleshooting

- If the pinned GitHub ref is necessary because the unpinned flake doesn't show `python` yet, use the pinned ref as in the `.envrc` above.
- If `use flake` complains, ensure Nix flakes are enabled and `direnv` is updated.

---

I created the `.envrc` in the `second_brain_database` repo and added this doc to `docs/using-python-with-direnv.md` in the `nix-config` repo.
