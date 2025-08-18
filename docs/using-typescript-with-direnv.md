# Using the TypeScript devShell with direnv

This document explains how to activate and use the TypeScript dev shell defined in this flake via `direnv`. It prefers a local flake for development, falls back to a pinned GitHub commit for collaborators, and finally tries the unpinned GitHub flake.

## Prerequisites

- Nix with flakes enabled (nix >= 2.4 with experimental `flakes` enabled).
- direnv installed and its shell hook loaded (`eval "$(direnv hook zsh)"` in `~/.zshrc` or similar).
- The `nix-config` flake is available locally at `~/Documents/nix-config` or on GitHub at `github:rohanbatrain/nix-config`.

## Copy this `.envrc` into your project root

This `.envrc` prefers the local flake, then a pinned commit on GitHub, then the unpinned GitHub flake.

```sh
# .envrc - prefer local flake, fallback to pinned GitHub rev, then unpinned
CANDIDATES=(
  "$HOME/Documents/nix-config#typescript"
  "github:rohanbatrain/nix-config/a9cfc73bb234f92fe4f669b51d1c45f400cc43e6#typescript"
  "github:rohanbatrain/nix-config#typescript"
)

for c in "${CANDIDATES[@]}"; do
  if use flake "$c" 2>/dev/null; then
    echo "direnv: using flake $c"
    exit 0
  fi
done

echo "direnv: warning — no usable devShell found among candidates"
```

Notes:
- Replace the pinned commit hash with whichever commit you want collaborators to use.
- The `use flake ... 2>/dev/null` calls keep direnv output quieter while attempting candidates.

## How to enable and use

1. Ensure `direnv` hook is loaded in your shell (zsh example):

```sh
# add once to ~/.zshrc
eval "$(direnv hook zsh)"
```

2. Put the `.envrc` file (shown above) in your project root.
3. Approve it once with:

```sh
cd /path/to/project
direnv allow
```

4. Open a new terminal in the project (or `cd` out and back in). direnv will load the first available dev shell.

Alternative — enter the dev shell directly without direnv:

```sh
cd ~/Documents/nix-config
nix develop .#typescript
```

## Verify the environment

After `direnv allow` and entering the project:

```sh
node --version
pnpm --version
tsc --version
```

If you prefer a single helper command in the project, create a small script `devshell-info` that prints these versions and make it executable.

## Troubleshooting

- `.envrc is blocked` → run `direnv allow` in the project once to approve.
- Long `direnv: export +AR +AS ...` line appears → the `.envrc` above suppresses noisy `use flake` output; reopen the terminal after changing `.envrc`. If it still appears, it is direnv showing what changed; see "Silencing direnv output" below.
- `nix flake show github:...` not showing the `typescript` devShell for the unpinned ref → flake index/caching can delay propagation. Use the pinned commit ref in `.envrc` (works immediately) or retry the unpinned ref after a few minutes.
- `use flake` warnings about a dirty tree when using a local flake → this is harmless; it warns that the local flake repo has uncommitted changes.

## Silencing direnv export summary (optional)

If you want to reduce direnv's export summary globally, add a machine-level tweak in `~/.config/direnv/direnvrc`. This affects all projects on your machine. Example (conservative):

```sh
# ~/.config/direnv/direnvrc
# keep direnv quiet for exports
export DIRENV_LOG_FORMAT=""  # minimal
```

Be careful: changing global direnv settings affects all projects. The repo-scoped `.envrc` above is usually the safest approach.

## Optional improvements

- Add an in-repo `devshell-info` script to show selected tool versions on demand.
- Remove the pinned commit in the `.envrc` after you confirm the unpinned GitHub flake exposes the `typescript` devShell reliably.

---

If you want, I can:
- Add the `.envrc` to `rohan_batra` and push it on a branch, or
- Create a `devshell-info` script in the repo and commit it. Which would you prefer?
