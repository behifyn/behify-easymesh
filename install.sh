#!/usr/bin/env bash

set -e

APP_NAME="easymesh"
SOURCE_FILE="./easymesh"
TARGET_FILE="/usr/local/bin/easymesh"

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root:"
  echo "sudo bash install.sh"
  exit 1
fi

if [[ ! -f "$SOURCE_FILE" ]]; then
  echo "Error: $SOURCE_FILE not found."
  exit 1
fi

cp "$SOURCE_FILE" "$TARGET_FILE"
chmod +x "$TARGET_FILE"

echo "Behify EasyMesh installed successfully."
echo "Run it with:"
echo "sudo easymesh"