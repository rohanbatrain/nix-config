{
  description = "nix-config: nix-darwin + home-manager system config for sitar-2";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # 👇 Added: Flake for a large collection of VS Code extensions
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, nix-homebrew, home-manager, nix-vscode-extensions, ... }:
    let
      system = "aarch64-darwin";

      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          android_sdk.accept_license = true;
        };
      };

      # Home Manager config for user "rohan"
      homeConfiguration = { pkgs, lib, ... }: {
        home.username = "rohan";
        home.stateVersion = "24.05";

        # 👇 Added: Declarative VS Code extensions managed by home-manager
        programs.vscode = {
          enable = true;
          # This specifies to use the VS Code package installed at the system level
          package = pkgs.vscode;
          profiles.default.extensions = with pkgs.vscode-extensions; [
            # A great starter pack of useful extensions
            ms-python.python
            jnoortheen.nix-ide
            # TypeScript / JS tooling
            dbaeumer.vscode-eslint
            esbenp.prettier-vscode
            # ms-vscode.vscode-typescript-next removed: not available in the overlay
            # ms-vscode.vscode-js-debug removed: not available in the overlay
          ];
        };

        home.packages = with pkgs; [
          git
          gh
          openssh
        ];

        programs.git = {
          enable = true;
          userName = "Rohan Batra";
          userEmail = "116573125+rohanbatrain@users.noreply.github.com";
        };

        programs.zsh = {
            enable = true;
            sessionVariables = {
              EDITOR = "vim";
              SSH_AUTH_SOCK = "/Users/rohan/.bitwarden-ssh-agent.sock";
              SECOND_BRAIN_DATABASE_CONFIG_PATH = "/Users/rohan/Documents/repos/second_brain_database/.sbd";
            };
          };
          
        # home.sessionVariables = {
        #   SSH_AUTH_SOCK = "/Users/rohan/.bitwarden-ssh-agent.sock";
        #   SECOND_BRAIN_DATABASE_CONFIG_PATH = "/Users/rohan/Documents/repos/second_brain_database/.sbd";
        # };

  programs.home-manager.enable = true;
  # Enable direnv so projects can auto-load flake dev shells via .envrc
  programs.direnv.enable = true;

        # 👇 Activation hook: clone or update repos (with GIT_SSH_COMMAND)
        home.activation.cloneRepos = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          reposDir="$HOME/Documents/repos"
          mkdir -p "$reposDir"

          clone_or_update () {
            local url="$1"
            local dest="$reposDir/$(basename "$url" .git)"
            if [ -d "$dest/.git" ]; then
              echo "🔄 Updating $dest..."
              GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh" \
                ${pkgs.git}/bin/git -C "$dest" pull --ff-only || true
            else
              echo "⬇️ Cloning $url into $dest..."
              mkdir -p "$dest"
              GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh" \
                ${pkgs.git}/bin/git clone "$url" "$dest" || echo "⚠️ Failed to clone $url"
            fi
          }

          clone_or_update git@github.com:rohanbatrain/emotion_tracker.git
          clone_or_update git@github.com:rohanbatrain/second_brain_database.git
          clone_or_update git@github.com:rohanbatrain/rohan_batra.git
          clone_or_update git@github.com:rohanbatrain/Portfolio.git
          clone_or_update git@github.com:rohanbatrain/docker-compose-setup.git
        '';
        # After cloning repos, run `direnv allow` in the project so the env is trusted
        home.activation.ensureDirenvAllowed = lib.hm.dag.entryAfter [ "cloneRepos" ] ''
          projectDir="$HOME/Documents/repos/rohan_batra"
          if [ -f "$projectDir/.envrc" ]; then
            echo "Running direnv allow in $projectDir"
            # Use the direnv provided by Nix to allow the envrc
            (cd "$projectDir" && ${pkgs.direnv}/bin/direnv allow) || true
          else
            echo "No .envrc in $projectDir; skipping direnv allow"
          fi
        '';
      };

      darwinConfiguration = { pkgs, config, ... }: {
        nixpkgs.config.allowUnfree = true;
        # 👇 Added: This overlay makes the `vscode-extensions` packages available
        nixpkgs.overlays = [
          nix-vscode-extensions.overlays.default
        ];
        
        users.users.rohan = {
          home = "/Users/rohan";
          name = "rohan";
        };

        environment.systemPackages = [
          pkgs.vim
          pkgs.mkalias
          pkgs.alacritty
          pkgs.git
          pkgs.openssh
          pkgs.uv
          pkgs.vscode
          pkgs.flutter
          pkgs.mongodb-compass
          pkgs.direnv
        ];

        security.pam.services.sudo_local.touchIdAuth = true;
        
        homebrew = {
          user = "rohan";
          enable = true;
          brews = [ "mas" "gh" "docker-compose" ];
          casks = [ "warp" "bitwarden" "github" "docker" ];
          masApps = { };
          onActivation.cleanup = "zap";
        };
        
        fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

        nix.settings.experimental-features = [ "nix-command" "flakes" ];

        system.configurationRevision = self.rev or self.dirtyRev or null;
        system.stateVersion = 6;
        nixpkgs.hostPlatform = system;

        system.activationScripts.applications.text = let
          env = pkgs.buildEnv {
            name = "system-applications";
            paths = config.environment.systemPackages;
            pathsToLink = "/Applications";
          };
        in pkgs.lib.mkForce ''
          echo "setting up /Applications..." >&2
          rm -rf /Applications/Nix\ Apps
          mkdir -p /Applications/Nix\ Apps
          find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + | while read -r src; do
            app_name=$(basename "$src")
            echo "copying $src" >&2
            ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
          done
        '';
      };

    in {
      darwinConfigurations."sitar-2" = nix-darwin.lib.darwinSystem {
        modules = [
          darwinConfiguration
          nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = true;
              user = "rohan";
              autoMigrate = true;
            };
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.rohan = homeConfiguration;
          }
        ];
      };
      # A reproducible TypeScript development shell. Enter with:
      #   nix develop .#aarch64-darwin.typescript
      devShells = {
        aarch64-darwin = {
          typescript = pkgs.mkShell {
            buildInputs = [
              pkgs.nodejs
              pkgs.pnpm
              pkgs.nodePackages.typescript
              pkgs.nodePackages."typescript-language-server"
              pkgs.nodePackages.eslint
              pkgs.nodePackages.prettier
            ];
            shellHook = ''
              export PATH=${pkgs.pnpm}/bin:$PATH
              echo "TypeScript dev shell ready: node $(node --version) pnpm $(pnpm --version 2>/dev/null || echo unknown) tsc $(tsc --version 2>/dev/null || echo unknown)"
            '';
          };
        };
      };
    };
}
