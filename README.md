# Cursor Editor NixOS Module

A NixOS module for the Cursor Editor with nixfmt-rfc-style formatting support.

## Features

- Installs and configures Cursor Editor using AppImage (no compilation required)
- Sets up nixfmt-rfc-style as the default Nix formatter
- Provides proper Wayland support
- Includes custom settings management
- Development shell with required dependencies
- Nixpkgs-compatible metadata and structure

## Installation

Add this flake to your NixOS configuration:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    code-cursor.url = "github:thecowboyai/code-cursor-appimage";
  };

  outputs = { self, nixpkgs, code-cursor, ... }: {
    nixosConfigurations.your-hostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        code-cursor.nixosModules.default
        {
          code-cursor.enable = true;
        }
      ];
    };
  };
}
```

> **Note:** When updating the flake.nix file, you'll need to select a download URL for the Cursor AppImage from the [cursor-ai-downloads repository](https://github.com/oslook/cursor-ai-downloads). This repository maintains a comprehensive list of official Cursor AI download links for all versions.

> **Important:** This module installs Cursor Editor using the official AppImage directly from Cursor's servers. It does not compile Cursor from source code, which ensures you get the official, unmodified version with all AI features intact.
> **We Understand This Is Not Preferred** This is an Unfree Application and we are simply accomodating those who Opt-In for this approach.

## Standalone Usage

You can also use the Cursor editor package directly without enabling the module:

```nix
{
  inputs.code-cursor.url = "github:thecowboyai/code-cursor-appimage";
  
  outputs = { self, code-cursor }: {
    packages.x86_64-linux.cursor = code-cursor.packages.x86_64-linux.default;
  };
}
```

## Version Selection

You can specify which version of Cursor you want to use in several ways:

### 1. Using Predefined Packages

The flake includes predefined packages for specific versions:

```nix
# In your NixOS configuration
{
  environment.systemPackages = [ 
    # Specific version
    inputs.code-cursor.packages.x86_64-linux.cursor_0_48_7 
    
    # Latest version
    inputs.code-cursor.packages.x86_64-linux.cursor_latest
  ];
}

# Or directly with nix build
nix build .#cursor_0_48_7
nix build .#cursor_latest
```

### 2. Using Environment Variables

When building the flake, you can set environment variables to control the version:

```bash
# Use the latest version (default)
nix build
# or explicitly
CURSOR_VERSION=latest nix build

# Specify a specific version (supports 0.48.7 and 0.48.8 by default)
CURSOR_VERSION=0.48.7 nix build

# For other versions, you'll need to provide the hash as well
CURSOR_VERSION=0.48.6 CURSOR_HASH="sha256-xxxx" nix build
```

### 3. Using mkCursorPackage Function

The flake provides a function to create a package with a specific version:

```nix
{
  inputs.code-cursor.url = "github:thecowboyai/code-cursor-appimage";
  
  outputs = { self, code-cursor, ... }: {
    # Use the latest version
    packages.x86_64-linux.myCursor = code-cursor.packages.x86_64-linux.mkCursorPackage {
      version = "latest";  # This is the default, so you can omit it
    };
    
    # Use a specific version
    packages.x86_64-linux.myCursorSpecific = code-cursor.packages.x86_64-linux.mkCursorPackage {
      version = "0.48.7";
      # hash is optional for known versions (0.48.7, 0.48.8)
    };
  };
}
```

For unknown versions, you need to provide the hash:

```nix
{
  packages.x86_64-linux.myCursor = code-cursor.packages.x86_64-linux.mkCursorPackage {
    version = "0.48.6";
    hash = "sha256-xxxx"; # Replace with actual hash
  };
}
```

### 4. Using the update-cursor Script

The included `update-cursor` script can automatically calculate the hash for any version:

```bash
# Update flake.nix to a specific version
nix develop -c update-cursor --version 0.48.7

# Then build normally
nix build
```

## Development

To enter a development shell with all required dependencies:

```bash
nix develop github:thecowboyai/code-cursor-appimage
```

## Automated Updates

This module includes a built-in script to automate updating the Cursor AppImage URL and hash in the flake.nix file. The script fetches the latest version from the [cursor-ai-downloads repository](https://github.com/oslook/cursor-ai-downloads), determines the appropriate download URL for your system, calculates the hash, and updates the flake.nix file.

To use the automated update script:

1. Enter the development shell:
   ```bash
   nix develop github:thecowboyai/code-cursor-appimage
   ```

2. Run the update script:
   ```bash
   update-cursor
   ```

3. After the script completes successfully, update the lockfile:
   ```bash
   nix flake update
   ```

### Update Script Options

The update-cursor script supports the following options:

- `--dry-run`: Preview changes without applying them
- `-v, --version VERSION`: Update to a specific version instead of the latest
- `-h, --help`: Display usage information

Example usage:

```bash
# Update to the latest version
update-cursor

# Preview what would be updated without making changes
update-cursor --dry-run

# Update to a specific version
update-cursor --version 0.48.7
```

The script automatically:
- Determines your system architecture (x86_64 or aarch64)
- Fetches the latest version information (or uses your specified version)
- Finds the appropriate download URL
- Calculates the SHA256 hash
- Updates the flake.nix file with the new URL and hash

## Configuration Options

The module provides the following options:

- `code-cursor.enable`: Enable or disable the Cursor editor module
- `code-cursor.version`: The version of Cursor to use (defaults to "latest")
- `code-cursor.package`: The Cursor package to use (defaults to the included one)
- `code-cursor.settings`: Additional settings to add to Cursor's settings.json

Example configuration with custom settings and specific version:

```nix
{
  code-cursor = {
    enable = true;
    version = "0.48.7"; # Use a specific version (default is "latest")
    settings = {
      "editor.fontSize" = 14;
      "workbench.colorTheme" = "Default Dark+";
    };
  };
}
```

Note: When applying settings through this module, they will be merged with any existing `settings.json` in your Cursor configuration. This means your personal settings will be preserved while the module's settings are added or updated.

## Running Cursor

After installation, launch Cursor using:

```bash
cursor-with-settings
```

The editor will launch with the preconfigured settings:
- nixfmt-rfc-style as the Nix formatter
- Proper Wayland support
- Custom editor settings

## Nixpkgs Compatibility

This repository is structured to be compatible with Nixpkgs standards:

- Proper metadata for package and module
- Clear documentation
- Maintainers field
- License and source provenance information
- Structured options with descriptions

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

MIT License - See LICENSE file for details 