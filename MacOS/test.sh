#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# get apps list
APP_LIST_FILE="$SCRIPT_DIR/../data/apps/apps.txt"
NPM_PACKAGES_FILE="$SCRIPT_DIR/../data/apps/packages.txt"

echo "--> reading apps list from $APP_LIST_FILE"
if [ ! -f "$APP_LIST_FILE" ]; then
    echo "ERROR: apps.txt file not found at $APP_LIST_FILE"
    exit 1
fi
APPS=()
while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines and lines starting with #
    if [[ -n "$line" && ! "$line" =~ ^[[:space:]]*# ]]; then
        # Trim whitespace
        line=$(echo "$line" | xargs)
        if [[ -n "$line" ]]; then
            APPS+=("$line")
        fi
    fi
done < "$APP_LIST_FILE"
echo "--> loaded ${#APPS[@]} apps from $APP_LIST_FILE"

# echo the apps that were loaded into the array
for app in "${APPS[@]}"; do
    echo "  $app"
done

echo "--------"
echo "--------"

echo "--> reading npm packages list from $NPM_PACKAGES_FILE"
if [ ! -f "$NPM_PACKAGES_FILE" ]; then
    echo "ERROR: packages.txt file not found at $NPM_PACKAGES_FILE"
    exit 1
fi
NPM_PACKAGES=()
while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines and lines starting with #
    if [[ -n "$line" && ! "$line" =~ ^[[:space:]]*# ]]; then
        # Trim whitespace
        line=$(echo "$line" | xargs)
        if [[ -n "$line" && ! "$line" =~ ---[[:space::]]*IGNORE[[:space:]]*--- ]]; then
            NPM_PACKAGES+=("$line")
        fi
    fi
done < "$NPM_PACKAGES_FILE"
echo "--> loaded ${#NPM_PACKAGES[@]} npm packages from $NPM_PACKAGES_FILE"
# echo the npm packages that were loaded into the array
for package in "${NPM_PACKAGES[@]}"; do
    echo "  $package"
done
echo "--------"
echo "--------"

echo "--> done"