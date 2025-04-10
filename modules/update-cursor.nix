{ pkgs, ... }:

pkgs.writeScriptBin "update-cursor" ''
  #!/usr/bin/env bash
  set -e

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
  LATEST_VERSION=$(echo "$VERSION_JSON" | grep -o '"version": *"[^"]*"' | head -1 | cut -d'"' -f4)
  
  if [ -z "$LATEST_VERSION" ]; then
    echo "Failed to determine latest version"
    exit 1
  fi
  
  echo "Latest version: $LATEST_VERSION"

  # Get current version from flake.nix
  CURRENT_VERSION=$(grep -o 'version = "[^"]*' flake.nix | head -1 | cut -d'"' -f2)
  echo "Current version: $CURRENT_VERSION"

  if [ "$LATEST_VERSION" = "$CURRENT_VERSION" ]; then
    echo "Already using the latest version ($CURRENT_VERSION). No changes needed."
    exit 0
  fi

  # Extract the direct URL from the version history if available
  echo "Checking for direct URL in version history for linux-$ARCH..."
  if [[ "$ARCH" == "x64" ]]; then
    DIRECT_URL=$(echo "$VERSION_JSON" | grep -o '"linux-x64": *"[^"]*"' | head -1 | cut -d'"' -f4)
  else
    DIRECT_URL=$(echo "$VERSION_JSON" | grep -o '"linux-arm64": *"[^"]*"' | head -1 | cut -d'"' -f4)
  fi

  if [ ! -z "$DIRECT_URL" ]; then
    echo "Found direct URL in version history: $DIRECT_URL"
    DOWNLOAD_URL="$DIRECT_URL"
  else
    # Fallback to README.md parsing if direct URL not found
    echo "Direct URL not found, searching README.md..."
    echo "Finding download URL for Cursor $LATEST_VERSION for linux-$ARCH..."
    DOWNLOAD_PAGE=$(curl -s "https://raw.githubusercontent.com/oslook/cursor-ai-downloads/main/README.md")
    DOWNLOAD_URL=$(echo "$DOWNLOAD_PAGE" | 
      grep -o "https://[^)]*linux/appImage/$ARCH[^)]*" | 
      head -1)
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

  # Update the flake.nix file
  echo "Updating flake.nix..."
  sed -i -E "s|version = \"[^\"]*\";|version = \"$LATEST_VERSION\";|" flake.nix
  sed -i -E "s|url = \"https://.*\";|url = \"$DOWNLOAD_URL\";|" flake.nix
  sed -i -E "s|sha256 = \"sha256-[^\"]*\";|sha256 = \"sha256-$(echo $SHA256 | cut -d- -f2)\";|" flake.nix

  echo "Successfully updated flake.nix to Cursor $LATEST_VERSION"
  echo "Run 'nix flake update' to update the lockfile"
'' 