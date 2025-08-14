{
  description = "nix-config: multi-env dev shells + nix-darwin system config for sitar-2";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, nix-darwin, ... }:
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
    darwinConfiguration = { pkgs, ... }: {
      environment.systemPackages = [
        pkgs.vim
      ];

      nix.settings.experimental-features = "nix-command flakes";

      system.configurationRevision = self.rev or self.dirtyRev or null;

      system.stateVersion = 6;
      nixpkgs.hostPlatform = system;

      # Optional: Enable any extra services or programs
      # programs.fish.enable = true;
    };

  in {
    # Use device name: sitar-2
    darwinConfigurations."sitar-2" = nix-darwin.lib.darwinSystem {
      modules = [ darwinConfiguration ];
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

