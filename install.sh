#!/usr/bin/env bash

set -e

APP_NAME="easymesh"
SOURCE_FILE="./easymesh"
INSTALL_DIR="/opt/behify-easymesh"
COMMAND_PATH="/usr/local/bin/easymesh"

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root:"
  echo "sudo bash install.sh"
  exit 1
fi

if [[ ! -f "$SOURCE_FILE" ]]; then
  echo "Error: $SOURCE_FILE not found."
  exit 1
fi

install -d "$INSTALL_DIR"
cp "$SOURCE_FILE" "$INSTALL_DIR/easymesh"
cp -a core "$INSTALL_DIR/"
cp README.md README_FA.md LICENSE NOTICE "$INSTALL_DIR/"

if [[ -d docs ]]; then
  cp -a docs "$INSTALL_DIR/"
fi

chmod +x "$INSTALL_DIR/easymesh"

rm -f "$COMMAND_PATH"
ln -s "$INSTALL_DIR/easymesh" "$COMMAND_PATH"

echo "Behify EasyMesh installed successfully."
echo "Installed path: $INSTALL_DIR"
echo "Command path: $COMMAND_PATH -> $INSTALL_DIR/easymesh"
echo
echo "Run:"
echo "sudo easymesh"
echo "sudo easymesh 2.6.4"
echo
echo "Strict offline:"
echo "sudo EASYMESH_OFFLINE=1 easymesh"
echo "sudo EASYMESH_OFFLINE=1 easymesh 2.6.4"
