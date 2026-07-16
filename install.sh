#!/usr/bin/env bash

set -euo pipefail

APP_NAME="easymesh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_FILE="$SCRIPT_DIR/easymesh"
RELAY_MANAGER_FILE="$SCRIPT_DIR/relay-manager"
INSTALL_DIR="/opt/behify-easymesh"
COMMAND_PATH="/usr/local/bin/easymesh"

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root:"
  echo "sudo bash install.sh"
  exit 1
fi

if [[ ! -f "$SOURCE_FILE" || ! -f "$RELAY_MANAGER_FILE" ]]; then
  echo "Error: $SOURCE_FILE or $RELAY_MANAGER_FILE not found."
  exit 1
fi

install -d "$INSTALL_DIR"
cp "$SOURCE_FILE" "$INSTALL_DIR/easymesh"
cp -a "$SCRIPT_DIR/core" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/README.md" "$SCRIPT_DIR/README_FA.md" \
  "$SCRIPT_DIR/LICENSE" "$SCRIPT_DIR/NOTICE" "$INSTALL_DIR/"

install -d "$INSTALL_DIR/relay"
install -m 0755 "$RELAY_MANAGER_FILE" "$INSTALL_DIR/relay/relay-manager"

if [[ -d "$SCRIPT_DIR/docs" ]]; then
  cp -a "$SCRIPT_DIR/docs" "$INSTALL_DIR/"
fi

chmod +x "$INSTALL_DIR/easymesh"

rm -f "$COMMAND_PATH"
ln -s "$INSTALL_DIR/easymesh" "$COMMAND_PATH"

echo "Behify EasyMesh installed successfully."
echo "Installed path: $INSTALL_DIR"
echo "Command path: $COMMAND_PATH -> $INSTALL_DIR/easymesh"
echo "Existing relay definitions, isolated Xray files, and service state were preserved."
echo
echo "Run:"
echo "sudo easymesh"
echo "sudo easymesh 2.6.4"
echo
echo "Strict offline:"
echo "sudo EASYMESH_OFFLINE=1 easymesh"
echo "sudo EASYMESH_OFFLINE=1 easymesh 2.6.4"
