# Contributing to the Cursor Editor NixOS Module

Thank you for considering contributing to this project! This document outlines the process for contributing to the Cursor Editor NixOS module.

## Development Setup

1. Fork the repository on GitHub
2. Clone your fork locally
   ```bash
   git clone https://github.com/YOUR-USERNAME/code-cursor-appimage.git
   cd code-cursor-appimage
   ```
3. Set up the development environment using Nix
   ```bash
   # Using flakes (recommended)
   nix develop
   
   # If not using flakes
   nix-shell
   ```

## Making Changes

1. Create a new branch for your changes
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes following the code style guidelines below
3. Test your changes thoroughly
4. Update documentation as needed

## Testing

Before submitting a pull request, ensure your changes work correctly:

1. Test that the module can be imported in a NixOS configuration
2. Test that the Cursor editor launches correctly with your changes
3. If you modified the updater script, test that it can still fetch the latest version correctly

## Code Style Guidelines

### Nix

- Follow the [Nixpkgs contribution guidelines](https://github.com/NixOS/nixpkgs/blob/master/CONTRIBUTING.md)
- Use 2-space indentation
- Sort attribute sets alphabetically when appropriate
- Use descriptive variable names
- Add comments for complex operations

### Shell Scripts

- Use `shellcheck` to validate your scripts
- Add comments explaining non-obvious operations
- Make scripts POSIX-compliant when possible

## Pull Request Process

1. Update the CHANGELOG.md with details of your changes
2. Ensure any temporary or build files are removed before committing
3. Update the README.md with any necessary changes to document new features
4. Submit a pull request with a clear title and description
5. Link any related issues in your pull request description

## Commit Messages

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Reference issues and pull requests liberally
- Consider starting the commit message with an applicable emoji:
    - ✨ `:sparkles:` when adding a new feature
    - 🐛 `:bug:` when fixing a bug
    - 📚 `:books:` when adding or updating documentation
    - ♻️ `:recycle:` when refactoring code
    - 🚀 `:rocket:` when improving performance
    - 🧪 `:test_tube:` when adding tests

## Release Process

1. Maintainers will review and merge accepted pull requests
2. Version updates will be managed according to semantic versioning principles
3. Releases will be tagged and documented in the CHANGELOG.md

## Questions?

If you have any questions or need help, please open an issue on GitHub or reach out to the maintainers directly.

Thank you for your contributions! 