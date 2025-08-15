{
  description = "nix-config: multi-env dev shells + nix-darwin system config for sitar-2";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # nix-homebrew only — no taps as inputs
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, nix-darwin, nix-homebrew, ... }:
  let
    system = "aarch64-darwin";

    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
        android_sdk.accept_license = true;
      };
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
        echo "🐍 Python dev shell powered by uv — Welcome!"
      '';
    };

    flutterShell = pkgs.mkShell {
      name = "flutter-dev-shell";
      buildInputs = sharedTools ++ [
        pkgs.flutter
        pkgs.android-tools
        pkgs.openjdk
        pkgs.androidsdk
      ];
      shellHook = ''
        echo "📱 Flutter dev shell with Android SDK & OpenJDK — Welcome!"
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
        echo "🌐 Web dev shell — Welcome!"
      '';
    };

    fullShell = pkgs.mkShell {
      name = "full-dev-shell";
      buildInputs = sharedTools ++ [
        pkgs.uv
        pkgs.flutter
        pkgs.android-tools
        pkgs.openjdk
        pkgs.androidsdk
        pkgs.nodejs
        pkgs.pnpm
        pkgs.typescript
        pkgs.prettier
        pkgs.eslint
        pkgs.esbuild
      ];
      shellHook = ''
        echo "💣 Full dev shell with EVERYTHING — Welcome!"
      '';
    };

    # nix-darwin system configuration
    darwinConfiguration = { pkgs, config, ... }: {
      nixpkgs.config = {
        allowUnfree = true;
      };

      environment.systemPackages = [
        pkgs.vim
        pkgs.bitwarden-desktop
        pkgs.mkalias
        pkgs.alacritty
      ];

      fonts.packages = [
        pkgs.nerd-fonts.jetbrains-mono
      ];

      nix.settings.experimental-features = [ "nix-command" "flakes" ];

      system.configurationRevision = self.rev or self.dirtyRev or null;
      system.stateVersion = 6;
      nixpkgs.hostPlatform = system;

      # ✅ nix-homebrew configuration with raw GitHub URLs
      nix-homebrew = {
        enable = true;
        enableRosetta = true;
        user = "rohan";

        taps = {
          "homebrew/homebrew-core" = "https://github.com/Homebrew/homebrew-core";
          "homebrew/homebrew-cask" = "https://github.com/Homebrew/homebrew-cask";
        };

        mutableTaps = false;
      };

      # Align homebrew.taps
      homebrew.taps = builtins.attrNames config.nix-homebrew.taps;

      # System applications linking
      system.activationScripts.applications.text = let
        env = pkgs.buildEnv {
          name = "system-applications";
          paths = config.environment.systemPackages;
          pathsToLink = "/Applications";
        };
      in
        pkgs.lib.mkForce ''
          echo "setting up /Applications..." >&2
          rm -rf /Applications/Nix\ Apps
          mkdir -p /Applications/Nix\ Apps
          find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
          while read -r src; do
            app_name=$(basename "$src")
            echo "copying $src" >&2
            ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
          done
        '';
    };

  in {
    darwinConfigurations."sitar-2" = nix-darwin.lib.darwinSystem {
      modules = [
        nix-homebrew.darwinModules.nix-homebrew
        darwinConfiguration
      ];
    };

    devShells.${system} = {
      default = pkgs.mkShell {
        name = "default-dev-shell";
        buildInputs = sharedTools;
        shellHook = ''
          echo "👋 Welcome to the shared tools shell!"
        '';
      };

      python = pythonShell;
      flutter = flutterShell;
      web = webShell;
      full = fullShell;
    };

    packages.${system}.default = pkgs.writeShellScriptBin "hello-nix" ''
      echo "👋 Hello from your nix-config flake!"
    '';
  };
}

