{
  description = "nix-config: multi-env dev shells for Python (uv), Flutter, Web (Next.js) and a full combo";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        sharedTools = with pkgs; [
          git
          jq
          nixpkgs-fmt
        ];

        pythonShell = pkgs.mkShell {
          name = "python-dev-shell";
          buildInputs = sharedTools ++ [ pkgs.uv ];
          shellHook = ''
            echo "🐍 Python dev shell powered by uv — Welcome to Rohanbatrain’s Nix Config!"
          '';
        };

        flutterShell = pkgs.mkShell {
          name = "flutter-dev-shell";
          buildInputs = sharedTools ++ [
            pkgs.flutter
            pkgs.androidsdk.platformtools
            pkgs.openjdk
            pkgs.androidsdk.buildtools
          ];
          shellHook = ''
            echo "📱 Flutter dev shell with Android SDK & OpenJDK — Enjoy Rohanbatrain’s Nix Config!"
          '';
        };

        webShell = pkgs.mkShell {
          name = "web-dev-shell";
          buildInputs = sharedTools ++ [
            pkgs.nodejs
            pkgs.pnpm
            pkgs.typescript
            pkgs.prettier
            pkgs.eslint
            pkgs.esbuild
          ];
          shellHook = ''
            echo "🌐 Web dev shell (Node.js, pnpm, TS, prettier, eslint, esbuild) — Brought to you by Rohanbatrain’s Nix Config."
          '';
        };

        fullShell = pkgs.mkShell {
          name = "full-dev-shell";
          buildInputs = sharedTools ++ [
            pkgs.uv
            pkgs.flutter
            pkgs.androidsdk.platformtools
            pkgs.openjdk
            pkgs.androidsdk.buildtools
            pkgs.nodejs
            pkgs.pnpm
            pkgs.typescript
            pkgs.prettier
            pkgs.eslint
            pkgs.esbuild
          ];
          shellHook = ''
            echo "💣 Full dev shell with EVERYTHING — Experience Rohanbatrain’s ultimate Nix Config combo!"
          '';
        };

      in {
        devShells = {
          default = pkgs.mkShell {
            name = "default-dev-shell";
            buildInputs = sharedTools;
            shellHook = ''
              echo "👋 Hello! Welcome to Rohanbatrain’s Nix Config Shell — your shared tools hub."
            '';
          };

          python = pythonShell;
          flutter = flutterShell;
          web = webShell;
          full = fullShell;
        };

        packages.default = pkgs.writeShellScriptBin "hello-nix" ''
          echo "👋 Hello from your nix-config flake!"
        '';
      }
    );
}

