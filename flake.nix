{
  description = "NixOS module for Cursor Editor From AppImage";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      
      # Import the update-cursor script from a separate module
      update-cursor-script = import ./modules/update-cursor.nix { inherit pkgs; };
    in {
      # The main NixOS module
      nixosModules.default = import ./modules/code-cursor;

      # For backwards compatibility
      nixosModule = self.nixosModules.default;

      # Example configuration
      nixosModules.example = {
        imports = [ self.nixosModules.default ];
        code-cursor.enable = true;
      };

      # Package for standalone use
      packages = {
        default = pkgs.appimageTools.wrapType2 {
          pname = "cursor";
          version = "0.48.8";
          src = pkgs.fetchurl {
            url = "https://downloads.cursor.com/production/66290080aae40d23364ba2371832bda0933a3641/linux/x64/Cursor-0.48.8-x86_64.AppImage";
            sha256 = "sha256-nnPbv74DOcOqgnAqW2IZ1S/lVbfv8pSe6Ab5BOdzkrs";
          };
          extraPkgs = pkgs: with pkgs; [ nixfmt-rfc-style ];
        };
        
        # Script to update Cursor AppImage URL and hash
        update-cursor = update-cursor-script;
      };

      # Development shell with required dependencies
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          nixfmt-rfc-style
          nodejs_22
          self.packages.${system}.update-cursor  # Add update script to devShell
          curl
          gnugrep
          gnused
        ];
      };
    });
} 