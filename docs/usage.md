# nix-config: Multi-Environment Flake Setup for macOS

This repository uses Nix flakes to provide reproducible, modular development environments tailored for Python (with uv), Flutter, Web (Next.js), and a full “everything included” shell.

---

## Environments

| Environment | Description                              | Usage                      |
|-------------|--------------------------------------|----------------------------|
| `default`   | Shared tools only (git, jq, nixpkgs-fmt) | `nix develop`              |
| `python`    | Python dev shell managed by uv         | `nix develop .#python`     |
| `flutter`   | Flutter + Android SDK + OpenJDK         | `nix develop .#flutter`    |
| `web`       | Node.js + pnpm + TypeScript + tooling  | `nix develop .#web`        |
| `full`      | All tools combined                      | `nix develop .#full`       |

---

## Getting Started

1. **Clone the repo:**

   ```bash
   git clone https://github.com/yourusername/nix-config.git
   cd nix-config
````

2. **Enter any dev environment:**

   For example, enter the Python shell:

   ```bash
   nix develop .#python
   ```

3. **Use the environment:**

   All tools will be available as specified (e.g., `uv` for Python, `flutter` and `adb` for Flutter, `pnpm` and `node` for web).

4. **Exit shell:**

   Just run `exit` or press `Ctrl+D`.

---

## Optional: Use with direnv

If you want automatic environment loading when you `cd` into this repo, install [direnv](https://direnv.net/) and run:

```bash
brew install direnv
echo "use flake" > .envrc
direnv allow
```

---

## Continuous Integration

This repo uses a GitHub Actions workflow to:

* Build the flake to ensure no errors
* Check formatting with `nixpkgs-fmt`
* Validate the flake structure

Workflow is located in `.github/workflows/ci.yml`.

---

## Updating Dependencies

Update your flake inputs with:

```bash
nix flake update
```

---

## Notes

* The Python environment uses `uv` to manage Python and dependencies internally.
* Flutter environment includes the Android SDK and OpenJDK.
* Web environment provides Node.js, pnpm, TypeScript, and popular JS tooling.
* The full environment (`.#full`) contains all tools for when you want everything at once.

---

Happy hacking! 🚀

