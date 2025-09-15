#!/bin/bash

# ----------------------------------------------------------------
#	README
#	This script will uninstall apps that were installed via 
#	Homebrew. It reads from the same apps.txt file used by 
#	the installation script.
#	
#	The script will:
#	    - Remove all apps listed in apps.txt
#	    - Remove global npm packages listed in packages.txt
#	    - Clean up VS Code settings (optional)
#	    - Remove iTerm theme (optional)
#	    - Clean up shell profile customizations (optional)
#
#	IMPORTANT: This script will ask for confirmation before 
#	removing each category of items.
# ----------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_LIST_FILE="$SCRIPT_DIR/apps.txt"
NPM_PACKAGES_FILE="$SCRIPT_DIR/../data/packages/packages.txt"
ITERM_THEME_FILE="$SCRIPT_DIR/../data/themes/iTerm-Ronans-Theme.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to ask for confirmation
confirm() {
    local prompt="$1"
    local response
    
    while true; do
        echo -en "${YELLOW}$prompt (y/n): ${NC}"
        read -r response
        case $response in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# ------------------------
# Check if Homebrew exists
# ------------------------
if ! command -v brew &> /dev/null; then
    echo -e "${RED}ERROR: Homebrew is not installed. Nothing to uninstall.${NC}"
    exit 1
fi

echo -e "${GREEN}Homebrew Uninstaller${NC}"
echo "This script will help you remove apps and configurations installed by the setup script."
echo ""

# ------------------------
# Uninstall Homebrew apps
# ------------------------
if [ -f "$APP_LIST_FILE" ]; then
    APPS=()
    
    # Read apps from file
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ -n "$line" && ! "$line" =~ ^[[:space:]]*# ]]; then
            line=$(echo "$line" | xargs)
            if [[ -n "$line" ]]; then
                APPS+=("$line")
            fi
        fi
    done < "$APP_LIST_FILE"
    
    if [ ${#APPS[@]} -gt 0 ]; then
        echo "Found ${#APPS[@]} apps in $APP_LIST_FILE"
        
        if confirm "Do you want to uninstall all Homebrew apps from the list?"; then
            echo -e "${GREEN}--> Uninstalling Homebrew apps...${NC}"
            
            FAILED_UNINSTALLS=()
            
            for app in "${APPS[@]}"; do
                echo "--> Uninstalling $app..."
                
                # Try to uninstall as cask first, then as formula
                if brew uninstall --cask "$app" &> /dev/null; then
                    echo -e "    ${GREEN}uninstalled (cask)${NC}"
                elif brew uninstall "$app" &> /dev/null; then
                    echo -e "    ${GREEN}uninstalled (formula)${NC}"
                else
                    echo -e "    ${YELLOW}not found or failed to uninstall${NC}"
                    FAILED_UNINSTALLS+=("$app")
                fi
            done
            
            # Report results
            if [ ${#FAILED_UNINSTALLS[@]} -eq 0 ]; then
                echo -e "${GREEN}--> All apps uninstalled successfully${NC}"
            else
                echo -e "${YELLOW}--> The following apps could not be uninstalled:${NC}"
                for app in "${FAILED_UNINSTALLS[@]}"; do
                    echo "    - $app"
                done
            fi
        else
            echo "Skipping app uninstallation."
        fi
    fi
else
    echo -e "${YELLOW}WARNING: $APP_LIST_FILE not found. Skipping app uninstallation.${NC}"
fi

echo ""

# ------------------------
# Uninstall npm packages
# ------------------------
if [ -f "$NPM_PACKAGES_FILE" ] && command -v npm &> /dev/null; then
    NPM_PACKAGES=()
    
    # Read npm packages from file
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ -n "$line" && ! "$line" =~ ^[[:space:]]*# ]]; then
            line=$(echo "$line" | xargs)
            if [[ -n "$line" && ! "$line" =~ ---[[:space::]]*IGNORE[[:space:]]*--- ]]; then
                NPM_PACKAGES+=("$line")
            fi
        fi
    done < "$NPM_PACKAGES_FILE"
    
    if [ ${#NPM_PACKAGES[@]} -gt 0 ]; then
        echo "Found ${#NPM_PACKAGES[@]} npm packages in $NPM_PACKAGES_FILE"
        
        if confirm "Do you want to uninstall global npm packages?"; then
            echo -e "${GREEN}--> Uninstalling global npm packages...${NC}"
            
            for package in "${NPM_PACKAGES[@]}"; do
                echo "--> Uninstalling $package..."
                if npm uninstall -g "$package" &> /dev/null; then
                    echo -e "    ${GREEN}uninstalled${NC}"
                else
                    echo -e "    ${YELLOW}not found or failed to uninstall${NC}"
                fi
            done
        else
            echo "Skipping npm package uninstallation."
        fi
    fi
elif [ ! -f "$NPM_PACKAGES_FILE" ]; then
    echo -e "${YELLOW}WARNING: $NPM_PACKAGES_FILE not found. Skipping npm package uninstallation.${NC}"
elif ! command -v npm &> /dev/null; then
    echo -e "${YELLOW}WARNING: npm not found. Skipping npm package uninstallation.${NC}"
fi

echo ""

# ------------------------
# Remove VS Code settings
# ------------------------
VSCODE_SETTINGS="$HOME/Library/Application Support/Code/User/settings.json"

if [ -f "$VSCODE_SETTINGS" ]; then
    if confirm "Do you want to remove VS Code settings?"; then
        if rm "$VSCODE_SETTINGS" 2>/dev/null; then
            echo -e "${GREEN}--> VS Code settings removed${NC}"
        else
            echo -e "${RED}--> Failed to remove VS Code settings${NC}"
        fi
    else
        echo "Keeping VS Code settings."
    fi
else
    echo "VS Code settings file not found."
fi

echo ""

# ------------------------
# Remove iTerm theme
# ------------------------
PROFILE_DIR="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
THEME_NAME="iTerm-Ronans-Theme.json"

if [ -f "$PROFILE_DIR/$THEME_NAME" ]; then
    if confirm "Do you want to remove the iTerm theme?"; then
        if rm "$PROFILE_DIR/$THEME_NAME" 2>/dev/null; then
            echo -e "${GREEN}--> iTerm theme removed${NC}"
        else
            echo -e "${RED}--> Failed to remove iTerm theme${NC}"
        fi
    else
        echo "Keeping iTerm theme."
    fi
else
    echo "iTerm theme not found in DynamicProfiles."
fi

echo ""

# ------------------------
# Clean up shell profile
# ------------------------
SHELL_PROFILE="$HOME/.zshrc"

if [[ $SHELL == *"bash"* ]]; then
    SHELL_PROFILE="$HOME/.bash_profile"
fi

if [ -f "$SHELL_PROFILE" ]; then
    MODIFICATIONS_FOUND=false
    
    # Check for our modifications
    if grep -q "# NVM setup" "$SHELL_PROFILE" 2>/dev/null; then
        MODIFICATIONS_FOUND=true
    fi
    if grep -q "# Custom prompt" "$SHELL_PROFILE" 2>/dev/null; then
        MODIFICATIONS_FOUND=true
    fi
    if grep -q "# Custom Aliases" "$SHELL_PROFILE" 2>/dev/null; then
        MODIFICATIONS_FOUND=true
    fi
    
    if [ "$MODIFICATIONS_FOUND" = true ]; then
        echo "Found shell profile modifications in $SHELL_PROFILE"
        if confirm "Do you want to remove custom shell profile modifications (NVM setup, custom prompt, aliases)?"; then
            # Create a backup first
            cp "$SHELL_PROFILE" "$SHELL_PROFILE.backup.$(date +%Y%m%d_%H%M%S)"
            echo -e "${GREEN}--> Created backup: $SHELL_PROFILE.backup.$(date +%Y%m%d_%H%M%S)${NC}"
            
            # Remove our sections
            sed -i '' '/^#--------------------------------$/,/^#--------------------------------$/d' "$SHELL_PROFILE"
            sed -i '' '/^# NVM setup$/,/^$/d' "$SHELL_PROFILE"
            sed -i '' '/^# Custom prompt$/,/^$/d' "$SHELL_PROFILE"
            sed -i '' '/^# Custom Aliases$/,/^$/d' "$SHELL_PROFILE"
            
            echo -e "${GREEN}--> Shell profile modifications removed${NC}"
            echo -e "${YELLOW}--> Note: You may need to restart your terminal or run 'source $SHELL_PROFILE'${NC}"
        else
            echo "Keeping shell profile modifications."
        fi
    else
        echo "No shell profile modifications found."
    fi
fi

echo ""

# ------------------------
# Optional: Clean Homebrew
# ------------------------
if confirm "Do you want to run Homebrew cleanup to remove old versions and caches?"; then
    echo -e "${GREEN}--> Running Homebrew cleanup...${NC}"
    if brew cleanup; then
        echo -e "${GREEN}--> Homebrew cleanup complete${NC}"
    else
        echo -e "${RED}--> Homebrew cleanup failed${NC}"
    fi
else
    echo "Skipping Homebrew cleanup."
fi

echo ""

# ------------------------
# Optional: Uninstall Homebrew completely
# ------------------------
echo -e "${RED}WARNING: The next option will completely remove Homebrew itself!${NC}"
if confirm "Do you want to completely uninstall Homebrew? (This will remove ALL Homebrew packages)"; then
    echo -e "${YELLOW}--> Downloading and running Homebrew uninstall script...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
    echo -e "${GREEN}--> Homebrew uninstallation complete${NC}"
else
    echo "Keeping Homebrew installed."
fi

echo ""
echo -e "${GREEN}--> Uninstallation process complete!${NC}"
echo -e "${YELLOW}--> You may want to restart your terminal for all changes to take effect.${NC}"
