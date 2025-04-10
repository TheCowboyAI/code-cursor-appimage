{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.code-cursor;
  
  cursor = pkgs.appimageTools.wrapType2 {
    pname = "cursor";
    version = "0.48.8";
    src = pkgs.fetchurl {
      url = "https://downloads.cursor.com/production/7801a556824585b7f2721900066bc87c4a09b743/linux/x64/Cursor-0.48.8-x86_64.AppImage";
      sha256 = "sha256-/5mwElzN0uURppWCLYPPECs6GzXtB54v2+jQD1RHcJE="; # Replace with actual hash
    };
    extraPkgs = pkgs: with pkgs; [ ];
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
  options.code-cursor.enable = lib.mkEnableOption "Enable code-cursor";
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
      cursor
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
}
