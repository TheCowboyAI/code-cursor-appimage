# Cursor Editor NixOS Module

A NixOS module for the Cursor Editor with nixfmt-rfc-style formatting support.

## Features

- Installs and configures Cursor Editor
- Sets up nixfmt-rfc-style as the default Nix formatter
- Provides proper Wayland support
- Includes custom settings management
- Development shell with required dependencies

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

The script automatically:
- Determines your system architecture (x86_64 or aarch64)
- Fetches the latest version information
- Finds the appropriate download URL
- Calculates the SHA256 hash
- Updates the flake.nix file with the new URL and hash

## Configuration Options

The module provides the following options:

- `code-cursor.enable`: Enable or disable the Cursor editor module

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

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

MIT License - See LICENSE file for details 