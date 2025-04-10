{
  description = "NixOS module for Cursor Editor From AppImage";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    
    # Default Cursor version info - can be overridden
    cursorVersionInfo = {
      url = "github:oslook/cursor-ai-downloads";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, cursorVersionInfo, ... }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      
      # Default to "latest" version for better UX
      specifiedVersion = builtins.getEnv "CURSOR_VERSION" or "latest";
      
      # Import the update-cursor script from a separate module
      update-cursor-script = import ./modules/update-cursor.nix { inherit pkgs; };
      
      # Try to parse version info, or use hardcoded defaults
      versionInfo = let
        versionPath = "${cursorVersionInfo}/version-history.json";
        versionExists = builtins.pathExists versionPath;
      in 
        if versionExists then builtins.fromJSON (builtins.readFile versionPath)
        else {
          versions = [
            {
              version = "0.48.8";
              "linux-x64" = "https://downloads.cursor.com/production/7801a556824585b7f2721900066bc87c4a09b743/linux/x64/Cursor-0.48.8-x86_64.AppImage";
            }
            {
              version = "0.48.7";
              "linux-x64" = "https://downloads.cursor.com/production/66290080aae40d23364ba2371832bda0933a3641/linux/x64/Cursor-0.48.7-x86_64.AppImage";
            }
          ];
        };
      
      # Get latest version from the version info
      latestVersion = (builtins.head versionInfo.versions).version;
      
      # Determine the version to use
      cursorVersionToUse = 
        if specifiedVersion == "latest" then latestVersion
        else specifiedVersion;
      
      # Verify version exists
      versionExists = builtins.length (builtins.filter (v: v.version == cursorVersionToUse) versionInfo.versions) > 0;
      
      # Use assert to fail if version doesn't exist
      # assert versionExists -> "Error: Cursor version ${cursorVersionToUse} not found. Available versions: ${builtins.concatStringsSep ", " (map (v: v.version) versionInfo.versions)}";
      
      # Get version data safely
      versionData = 
        if versionExists 
        then builtins.head (builtins.filter (v: v.version == cursorVersionToUse) versionInfo.versions)
        else throw "Error: Cursor version ${cursorVersionToUse} not found. Available versions: ${builtins.concatStringsSep ", " (map (v: v.version) versionInfo.versions)}";
      
      # Get the appropriate URL for the current system
      archKey = if system == "x86_64-linux" then "linux-x64" else "linux-arm64";
      downloadUrl = versionData.${archKey} or "https://downloads.cursor.com/production/7801a556824585b7f2721900066bc87c4a09b743/linux/x64/Cursor-0.48.8-x86_64.AppImage";
      
      # Known hashes for common versions
      knownHashes = {
        "0.48.8" = "sha256-/5mwElzN0uURppWCLYPPECs6GzXtB54v2+jQD1RHcJE=";
        "0.48.7" = "sha256-nnPbv74DOcOqgnAqW2IZ1S/lVbfv8pSe6Ab5BOdzkrs=";
      };
      
      # This hash lookup is now more flexible and user-friendly
      cursorHash = 
        if builtins.getEnv "CURSOR_HASH" != "" then builtins.getEnv "CURSOR_HASH"
        else if builtins.hasAttr cursorVersionToUse knownHashes
             then knownHashes.${cursorVersionToUse}
             else throw "Unknown Cursor version ${cursorVersionToUse}. Please specify a hash using CURSOR_HASH env var or use one of the known versions: ${builtins.concatStringsSep ", " (builtins.attrNames knownHashes)}";
      
      # Generic function to create a package with a specific version
      mkCursorPackage = { version ? "latest", hash ? null }: let
        # Determine the actual version to use
        actualVersion = 
          if version == "latest" then latestVersion
          else version;
        
        # Check if version exists
        versionFound = builtins.length (builtins.filter (v: v.version == actualVersion) versionInfo.versions) > 0;
        
        # Get version data
        vData = 
          if versionFound
          then builtins.head (builtins.filter (v: v.version == actualVersion) versionInfo.versions)
          else throw "Error: Cursor version ${actualVersion} not found. Available versions: ${builtins.concatStringsSep ", " (map (v: v.version) versionInfo.versions)}";
          
        url = vData.${archKey} or null;
        
        # Ensure we have a URL
        finalUrl = 
          if url != null 
          then url
          else throw "Error: No download URL found for Cursor ${actualVersion} on ${archKey}";
        
        # Determine hash to use
        versionHash = 
          if hash != null then hash
          else if builtins.hasAttr actualVersion knownHashes
               then knownHashes.${actualVersion}
               else throw "Unknown Cursor version ${actualVersion}. Please provide a hash or use one of the known versions: ${builtins.concatStringsSep ", " (builtins.attrNames knownHashes)}";
      in
        pkgs.appimageTools.wrapType2 {
          pname = "cursor";
          version = actualVersion;
          src = pkgs.fetchurl {
            url = finalUrl;
            sha256 = versionHash;
          };
          extraPkgs = pkgs: with pkgs; [ nixfmt-rfc-style ];
        };
    in {
      # The main NixOS module
      nixosModules.default = { config, ... }: {
        imports = [ (import ./modules/code-cursor) ];
        nixpkgs.overlays = [
          (final: prev: {
            code-cursor-package = mkCursorPackage {
              version = config.code-cursor.version or "latest";
            };
          })
        ];
        # Override the package with our version-aware one
        config.code-cursor.package = config.nixpkgs.config.code-cursor-package or (
          mkCursorPackage {
            version = config.code-cursor.version or "latest";
          }
        );
      };

      # For backwards compatibility
      nixosModule = self.nixosModules.default;

      # Example configuration
      nixosModules.example = {
        imports = [ self.nixosModules.default ];
        code-cursor.enable = true;
        # You can optionally specify a version
        # code-cursor.version = "0.48.7";
      };

      # Package for standalone use
      packages = {
        default = mkCursorPackage { 
          version = specifiedVersion;
          hash = if specifiedVersion == "latest" || builtins.hasAttr cursorVersionToUse knownHashes
                 then null
                 else cursorHash;
        };
        
        # Allow specifying specific versions
        cursor_0_48_7 = mkCursorPackage { 
          version = "0.48.7"; 
        };
        
        cursor_0_48_8 = mkCursorPackage { 
          version = "0.48.8"; 
        };
        
        # Latest version
        cursor_latest = mkCursorPackage {
          version = "latest";
        };
        
        # Function to create a package with a specific version
        mkCursorPackage = mkCursorPackage;
        
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