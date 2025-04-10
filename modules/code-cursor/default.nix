{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.code-cursor;
  
  # This is just a fallback for when the module is used standalone
  # When used via the flake, the flake's package will be used instead
  cursor = pkgs.appimageTools.wrapType2 {
    pname = "cursor";
    version = cfg.version;
    src = pkgs.fetchurl {
      url = "https://downloads.cursor.com/production/7801a556824585b7f2721900066bc87c4a09b743/linux/x64/Cursor-0.48.8-x86_64.AppImage";
      sha256 = "sha256-/5mwElzN0uURppWCLYPPECs6GzXtB54v2+jQD1RHcJE="; # Replace with actual hash
    };
    extraPkgs = pkgs: with pkgs; [ ];
    
    meta = with lib; {
      description = "Cursor AI Code Editor packaged as AppImage";
      homepage = "https://cursor.sh";
      license = licenses.unfree; # The AppImage is proprietary, though our module is MIT
      maintainers = with maintainers; [ thecowboyai ];
      platforms = [ "x86_64-linux" ];
      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
      mainProgram = "cursor";
    };
  };
  
  # Load cursor settings
  cursorSettingsFile = ./settings.json;
  cursorSettings = builtins.readFile cursorSettingsFile;
  
  # Create a wrapper script
  cursorWrapper = pkgs.writeScriptBin "cursor-with-settings" (builtins.readFile ./cursor-wrapper.sh);
  
  # Create a package with the settings file
  cursorSettingsPackage = pkgs.writeTextFile {
    name = "cursor-settings";
    text = cursorSettings;
    destination = "/etc/cursor/settings.json";
  };
in {
  options.code-cursor = {
    enable = mkEnableOption "Cursor AI Code Editor with NixOS integration";
    
    version = mkOption {
      type = types.str;
      default = "latest";
      description = "Version of Cursor to use. Set to 'latest' for the latest version, or a specific version number.";
      example = "0.48.7";
    };
    
    package = mkOption {
      type = types.package;
      default = cursor;
      defaultText = literalExpression "cursor";
      description = "The Cursor package to use.";
    };
    
    settings = mkOption {
      type = types.attrs;
      default = {};
      description = "Additional settings to add to Cursor's settings.json.";
      example = literalExpression ''
        {
          "editor.fontSize" = 14;
          "workbench.colorTheme" = "Default Dark+";
        }
      '';
    };
  };
  
  # if we enable it, use this...
  config = mkIf cfg.enable {
    environment.variables = {
      ELECTRON_OZONE_PLATFORM_HINT = "wayland";
      NIXFMT_PATH = "${pkgs.nixfmt-rfc-style}/bin/nixfmt-rfc-style";
    };
    
    environment.systemPackages = with pkgs; [
      appimage-run
      poppler_utils #pdftotext
      # for npx to use MCPs
      nodejs_22
      nixfmt-rfc-style
      cfg.package
      # Add the cursor wrapper
      cursorWrapper
      # Include settings package
      cursorSettingsPackage
    ];
    
    programs.appimage = {
      enable = true;
      binfmt = true;
    };
    
    # Create directory and link the settings file
    system.activationScripts.cursorSettings = {
      text = ''
        mkdir -p /etc/cursor
        ln -sf ${cursorSettingsPackage}/etc/cursor/settings.json /etc/cursor/settings.json
      '';
      deps = [];
    };
  };
  
  meta = {
    maintainers = [ /* Add yourself here */ ];
    doc = "https://github.com/thecowboyai/code-cursor-appimage";
    description = ''
      This module installs and configures the Cursor AI Code Editor.
      Cursor is packaged as an AppImage and this module provides Wayland support
      and a wrapper script that ensures proper configuration with Nix-specific settings.
      It also sets up nixfmt-rfc-style as the default Nix formatter.
    '';
  };
}
