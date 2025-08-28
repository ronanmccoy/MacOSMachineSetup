#!/bin/bash

# ----------------------------------------------------------------
#	README
#	This script will install Homebrew, if it's not already 
#	installed, and then install a list of apps defined below.
#	It will then update VS Code with some basic settings, and 
#	add a custom theme to iTerm.
#	This script WILL NOT however install VS Code extensions.
#	For not VS Code extensions will be installed manually.
#
#	IMPORTANT NOTE: the iTerm theme file, iTerm-Ronans-Theme.json
#	should be in the same directory as this script.
# ----------------------------------------------------------------


# ------------------------
# check for homebrew
# ------------------------
if ! command -v brew &> /dev/null; then
	echo "--> Homebrew is not installed. Let's try and install it..."
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

	# add brew to PATH
	if [[ -f "/opt/homebrew/bin/brew" ]]; then
    	eval "$(/opt/homebrew/bin/brew shellenv)"
	elif [[ -f "/usr/local/bin/brew" ]]; then
    	eval "$(/usr/local/bin/brew shellenv)"
	fi
else
	echo "--> Homebrew is already installed."
fi


# ------------------------
# apps for installation
# ------------------------
APPS=(
	awscli
	curl
	darktable
	discord
	dropbox
	gimp
	git
	git-flow
	gh
	google-chrome
	google-earth-pro
	iterm2
	kdiff3
	keepassx
	mongodb-compass
	ngrok
	node
	nvm
	opera
	pgadmin4
	postman
	shotcut
	slack
	spotify
	stellarium
	telnet
	vlc
	watchman
	wget
	wireshark
	yarn
	android-studio
	cursor
	sublime-text
	visual-studio-code	
)

FAILED_APPS=()

echo "Installing apps..."
for app in "${APPS[@]}"; do
	echo "--> installing $app..."
	if brew install --cask "$app" &> /dev/null || brew install "$app" &> /dev/null; then
		echo "	installed"
	else
		echo "	failed to install $app"
		FAILED_APPS+=("$app")
	fi
done


# ------------------------
# VS Code settings
# ------------------------
VSCODE_SETTINGS="$HOME/Library/Application Support/Code/User/settings.json"

if [ -d "$HOME/Applications/Visual Studio Code.app" ] || command -v code &> /dev/null; then
	echo "--> updating VS Code settings..."
	mkdir -p "$(dirname "$VSCODE_SETTINGS")"
	cat > "$VSCODE_SETTINGS" <<EOL
{
	"editor.fontSize": 13,
	"editor.formatOnSave": true,
	"files.autoSave": "afterDelay",
	"editor.defaultFormatter": "esbenp.prettier-vscode",
	"editor.wordWrap": "on",
	"workbench.colorTheme": "Visual Studio Dark",
	"workbench.iconTheme": "vscode-icons",
	"editor.tabSize": 4
}
EOL

	echo "--> VS Code settings updated"
else
	echo "--> Could not update VS Code settings. Is it installed?"
fi


# ------------------------
# Set iTerm theme
# ------------------------
THEME_FILE="$(pwd)/iTerm-Ronans-Theme.json"
PROFILE_DIR="$HOME/Library/Application Support/iTerm2/DynamicProfiles"

if [ -d "/Applications/iTerm.app" ]; then
	if [ -f "$THEME_FILE" ]; then
		mkdir -p "$PROFILE_DIR"
		cp "$THEME_FILE" "$PROFILE_DIR/"
		echo "--> imported iTerm theme file. You can select it in Settings -> Profiles"
	else
		echo "--> Error: iTerm theme file not found ($THEME_FILE)"
		FAILED_APPS+=("(iTerm2 theme file is missing)")
	fi
else
	echo "---> iTerm is not installed"
	FAILED_APPS+=("(could not find iTerm2)")
fi


# --------------------------------
# list apps that failed to install
# --------------------------------
if [ ${#FAILED_APPS[@]} -ne 0 ]; then
	echo
	echo "--> the following apps failed to install:"
	for app in "${FAILED_APPS[@]}"; do
		echo "		- $app"
	done
else
	echo
	echo "--> all apps installed successfully"
fi

echo "--> finished"

