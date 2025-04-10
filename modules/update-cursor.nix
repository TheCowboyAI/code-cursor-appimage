{ pkgs, ... }:

pkgs.writeScriptBin "update-cursor" ''
  #!/usr/bin/env bash
  set -e

  # Display help information
  function show_help {
    echo "Cursor Editor Update Script"
    echo "============================="
    echo "This script updates the Cursor Editor AppImage URL and hash in flake.nix."
    echo ""
    echo "Usage: update-cursor [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help             Show this help message and exit"
    echo "  --dry-run              Show what changes would be made without applying them"
    echo "  -v, --version VERSION  Specify a specific version to use (e.g., 0.48.7, or 'latest')"
    echo ""
    echo "Examples:"
    echo "  update-cursor                    # Update to the latest version"
    echo "  update-cursor --dry-run          # Show what would be updated without making changes"
    echo "  update-cursor --version latest   # Explicitly update to the latest version"
    echo "  update-cursor --version 0.48.7   # Update to a specific version"
    echo ""
    exit 0
  }

  # Parse command line arguments
  DRY_RUN=0
  TARGET_VERSION=""
  while [[ $# -gt 0 ]]; do
    case $1 in
      -h|--help)
        show_help
        ;;
      --dry-run)
        DRY_RUN=1
        shift
        ;;
      -v|--version)
        if [ -z "$2" ]; then
          echo "Error: --version requires a version number or 'latest'"
          exit 1
        fi
        TARGET_VERSION="$2"
        shift 2
        ;;
      *)
        echo "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
    esac
  done

  # Determine current system architecture
  if [[ "$(uname -m)" == "x86_64" ]]; then
    ARCH="x64"
  elif [[ "$(uname -m)" == "aarch64" ]]; then
    ARCH="arm64"
  else
    echo "Unsupported architecture: $(uname -m)"
    exit 1
  fi

  # Fetch latest version info from cursor-ai-downloads repository
  echo "Fetching latest version information..."
  VERSION_JSON=$(curl -s "https://raw.githubusercontent.com/oslook/cursor-ai-downloads/main/version-history.json")
  
  # Get the latest version first, as we'll need it anyway
  LATEST_VERSION=$(echo "$VERSION_JSON" | grep -o '"version": *"[^"]*"' | head -1 | cut -d'"' -f4)
  if [ -z "$LATEST_VERSION" ]; then
    echo "Failed to determine latest version"
    exit 1
  fi
  echo "Latest version: $LATEST_VERSION"
  
  # Determine which version to use
  if [ -z "$TARGET_VERSION" ] || [ "$TARGET_VERSION" = "latest" ]; then
    VERSION_TO_USE="$LATEST_VERSION"
    echo "Using latest version: $VERSION_TO_USE"
  else
    echo "Using specified version: $TARGET_VERSION"
    VERSION_TO_USE="$TARGET_VERSION"
    
    # Verify the specified version exists
    if ! echo "$VERSION_JSON" | grep -q "\"version\": *\"$TARGET_VERSION\""; then
      echo "Warning: Version $TARGET_VERSION not found in version history"
      echo "Continuing anyway, but URL lookup might fail"
    fi
  fi

  # Get current version from flake.nix
  CURRENT_VERSION=$(grep -o 'version = "[^"]*' flake.nix | head -1 | cut -d'"' -f2)
  echo "Current version: $CURRENT_VERSION"

  if [ "$VERSION_TO_USE" = "$CURRENT_VERSION" ] && [ "$CURRENT_VERSION" != "latest" ]; then
    echo "Already using version $CURRENT_VERSION. No changes needed."
    exit 0
  fi

  # Extract the direct URL from the version history if available
  echo "Checking for direct URL in version history for linux-$ARCH..."
  if [[ "$ARCH" == "x64" ]]; then
    DIRECT_URL=$(echo "$VERSION_JSON" | grep -A20 "\"version\": *\"$VERSION_TO_USE\"" | grep -o '"linux-x64": *"[^"]*"' | head -1 | cut -d'"' -f4)
  else
    DIRECT_URL=$(echo "$VERSION_JSON" | grep -A20 "\"version\": *\"$VERSION_TO_USE\"" | grep -o '"linux-arm64": *"[^"]*"' | head -1 | cut -d'"' -f4)
  fi

  if [ ! -z "$DIRECT_URL" ]; then
    echo "Found direct URL in version history: $DIRECT_URL"
    DOWNLOAD_URL="$DIRECT_URL"
  else
    # Fallback to README.md parsing if direct URL not found
    echo "Direct URL not found, searching README.md..."
    echo "Finding download URL for Cursor $VERSION_TO_USE for linux-$ARCH..."
    DOWNLOAD_PAGE=$(curl -s "https://raw.githubusercontent.com/oslook/cursor-ai-downloads/main/README.md")
    
    # Search for the specific version in the README
    SECTION_START=$(echo "$DOWNLOAD_PAGE" | grep -n "## $VERSION_TO_USE" | cut -d: -f1)
    
    if [ -z "$SECTION_START" ]; then
      echo "Warning: Version $VERSION_TO_USE section not found in README.md"
      # Fall back to searching the entire README
      DOWNLOAD_URL=$(echo "$DOWNLOAD_PAGE" | grep -o "https://[^)]*linux/appImage/$ARCH[^)]*" | head -1)
    else
      # Find the next section heading or end of file
      NEXT_SECTION=$(echo "$DOWNLOAD_PAGE" | tail -n +$SECTION_START | grep -n "^## " | head -1 | cut -d: -f1)
      
      if [ -z "$NEXT_SECTION" ]; then
        # No next section, use until end of file
        SECTION_CONTENT=$(echo "$DOWNLOAD_PAGE" | tail -n +$SECTION_START)
      else
        # Calculate lines to include
        LINES_TO_INCLUDE=$((NEXT_SECTION - 1))
        SECTION_CONTENT=$(echo "$DOWNLOAD_PAGE" | tail -n +$SECTION_START | head -n $LINES_TO_INCLUDE)
      fi
      
      # Find the download URL in the section content
      DOWNLOAD_URL=$(echo "$SECTION_CONTENT" | grep -o "https://[^)]*linux/appImage/$ARCH[^)]*" | head -1)
    fi
  fi

  if [ -z "$DOWNLOAD_URL" ]; then
    echo "Failed to find download URL for linux-$ARCH"
    exit 1
  fi

  echo "Found download URL: $DOWNLOAD_URL"

  # Calculate the SHA256 hash
  echo "Calculating SHA256 hash..."
  SHA256=$(nix-prefetch-url "$DOWNLOAD_URL" 2>/dev/null)

  if [ -z "$SHA256" ]; then
    echo "Failed to calculate SHA256 hash"
    exit 1
  fi

  echo "SHA256: $SHA256"

  # Format the hash correctly for SRI format using the newer command
  SRI_HASH=$(nix hash convert --to sri --type sha256 $SHA256 2>/dev/null || nix hash to-sri --type sha256 $SHA256)
  
  if [ $DRY_RUN -eq 1 ]; then
    echo "DRY RUN: Would update flake.nix with the following changes:"
    if [ "$VERSION_TO_USE" = "$LATEST_VERSION" ]; then
      echo "  - Change version from $CURRENT_VERSION to \"latest\" (which is currently $LATEST_VERSION)"
    else
      echo "  - Change version from $CURRENT_VERSION to $VERSION_TO_USE"
    fi
    echo "  - Update download URL to: $DOWNLOAD_URL"
    echo "  - Update SHA256 hash to: $SRI_HASH"
    
    if [ "$VERSION_TO_USE" = "$LATEST_VERSION" ] && grep -q "knownHashes" flake.nix; then
      echo "  - Update or add $LATEST_VERSION to knownHashes"
    fi
    
    echo ""
    echo "Run without --dry-run to apply these changes"
  else
    # Update the flake.nix file
    echo "Updating flake.nix..."
    
    if [ "$VERSION_TO_USE" = "$LATEST_VERSION" ]; then
      # Set to "latest" instead of a specific version for better future-proofing
      sed -i -E 's|version = "[^"]*";|version = "latest";|' flake.nix
      
      # Also update the knownHashes section to include the latest version
      if grep -q "knownHashes" flake.nix; then
        # Check if this version is already in knownHashes
        if ! grep -q "\"$LATEST_VERSION\" = " flake.nix; then
          # Add the new version to knownHashes
          sed -i -E "/knownHashes = \{/a\\        \"$LATEST_VERSION\" = \"$SRI_HASH\";" flake.nix
        else
          # Update the existing hash
          sed -i -E "s|\"$LATEST_VERSION\" = \"[^\"]*\"|\"$LATEST_VERSION\" = \"$SRI_HASH\"|" flake.nix
        fi
      fi
    else
      # Set to the specific version
      sed -i -E "s|version = \"[^\"]*\";|version = \"$VERSION_TO_USE\";|" flake.nix
    fi
    
    # Update the URL and hash
    sed -i -E "s|url = \"https://.*\";|url = \"$DOWNLOAD_URL\";|" flake.nix
    sed -i -E "s|sha256 = \"sha256-[^\"]*\";|sha256 = \"$SRI_HASH\";|" flake.nix

    if [ "$VERSION_TO_USE" = "$LATEST_VERSION" ]; then
      echo "Successfully updated flake.nix to use the latest Cursor version ($LATEST_VERSION)"
    else  
      echo "Successfully updated flake.nix to Cursor $VERSION_TO_USE"
    fi
    
    echo "Run 'nix flake update' to update the lockfile"
  fi
'' 