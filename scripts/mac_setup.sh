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
	echo "--> homebrew is not installed. Let's try and install it..."
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

	# add brew to PATH
	if [[ -f "/opt/homebrew/bin/brew" ]]; then
    	eval "$(/opt/homebrew/bin/brew shellenv)"
	elif [[ -f "/usr/local/bin/brew" ]]; then
    	eval "$(/usr/local/bin/brew shellenv)"
	fi
else
	echo "--> homebrew is already installed."
fi


# ------------------------
# apps for installation
# ------------------------
APPS=(
	awscli
	aws-cdk
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

echo "--> installing apps..."
for app in "${APPS[@]}"; do
	echo "--> installing $app..."
	if brew install --cask "$app" &> /dev/null || brew install "$app" &> /dev/null; then
		echo "	installed"
	else
		echo "	failed to install $app"
		FAILED_APPS+=("$app")
	fi
done


# ---------------------------------------------------
# PATH refresh for nvm to make sure system finds it.
# Then install node via nvm.
# ---------------------------------------------------
# Source the appropriate shell profile to refresh PATH
if [[ -f ~/.zshrc ]]; then
    source ~/.zshrc
elif [[ -f ~/.bash_profile ]]; then
    source ~/.bash_profile
elif [[ -f ~/.bashrc ]]; then
    source ~/.bashrc
fi

# wait a moment to ensure PATH is updated
sleep 2

# Then check if nvm is available, and source directly if not
if ! command -v nvm &> /dev/null; then
    if [ -s "$HOME/.nvm/nvm.sh" ]; then
        source "$HOME/.nvm/nvm.sh"
    elif [ -s "/opt/homebrew/opt/nvm/nvm.sh" ]; then
        source "/opt/homebrew/opt/nvm/nvm.sh"
    fi
fi

echo "--> installing node via nvm, if nvm was installed..."
if command -v nvm &> /dev/null; then
    nvm install node
    nvm use node
fi


# ------------------------
# Global NPM packages
# ------------------------
NPM_PACKAGES=(
	typescript
	ts-node
	@anthropic-ai/claude-code
)

FAILED_NPM_PACKAGES=()

if command -v npm &> /dev/null; then
	echo "--> installing global npm packages..."
	for package in "${NPM_PACKAGES[@]}"; do
		echo "--> installing $package..."
		if npm install -g "$package" &> /dev/null; then
			echo "	installed"
		else
			echo "	failed to install $package"
			FAILED_NPM_PACKAGES+=("$package")
		fi
	done
else
	echo "--> npm is not available. Skipping npm package installation."
	echo "    (npm packages will need to be installed manually after Node.js is set up)"
fi


# ------------------------
# VS Code settings
# ------------------------
VSCODE_SETTINGS="$HOME/Library/Application Support/Code/User/settings.json"

if [ -d "/Applications/Visual Studio Code.app" ] || [ -d "$HOME/Applications/Visual Studio Code.app" ] || command -v code &> /dev/null; then
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
	echo "--> could not update VS Code settings. Is it installed?"
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
		echo "--> ERROR: iTerm theme file not found ($THEME_FILE)"
		FAILED_APPS+=("(iTerm2 theme file is missing)")
	fi
else
	echo "---> iTerm is not installed"
	FAILED_APPS+=("(could not find iTerm2)")
fi


# ------------------------------------
# Add customizations to shell profile
# ------------------------------------
SHELL_PROFILE="$HOME/.zshrc"

if [[ $SHELL == *"bash"* ]]; then
	SHELL_PROFILE="$HOME/.bash_profile"
fi

if command -v nvm &> /dev/null; then
	if ! grep -q "nvm.sh" "$SHELL_PROFILE" 2>/dev/null; then
        echo "--> adding nvm to shell profile for future sessions..."

		echo '#--------------------------------' >> "$SHELL_PROFILE"
		echo '# NVM setup' >> "$SHELL_PROFILE"
		echo '#--------------------------------' >> "$SHELL_PROFILE"
        echo 'export NVM_DIR="$HOME/.nvm"' >> "$SHELL_PROFILE"
        echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> "$SHELL_PROFILE"
        echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> "$SHELL_PROFILE"

		echo "	nvm setup added to $SHELL_PROFILE"
    fi
fi

# prompt customizations (if not already present)
# Important: these are specific to how I want my prompt to look. Modify as needed or simply remove the section.
if ! grep -q "# Custom prompt" "$SHELL_PROFILE" 2>/dev/null; then
	echo "--> adding custom prompt to shell profile..."

	echo '' >> "$SHELL_PROFILE"
	echo '#--------------------------------' >> "$SHELL_PROFILE"
	echo '# Custom prompt' >> "$SHELL_PROFILE"
	echo '#--------------------------------' >> "$SHELL_PROFILE"
	echo '# load version control info' >> "$SHELL_PROFILE"
	echo 'autoload -Uz vcs_info' >> "$SHELL_PROFILE"
	echo 'precmd() { vcs_info }' >> "$SHELL_PROFILE"
	echo '# format the text of the prompt' >> "$SHELL_PROFILE"
	echo 'zstyle ":vcs_info:git:*" formats "%F{201}<%b>%f"' >> "$SHELL_PROFILE"
	echo '# add git branch name to the prompt' >> "$SHELL_PROFILE"
	echo 'setopt PROMPT_SUBST' >> "$SHELL_PROFILE"
	echo 'PROMPT="%n@%m %F{255}%2~/%f${vcs_info_msg_0_}: "' >> "$SHELL_PROFILE"

	echo "	custom prompt added"
fi

# my aliases (if they are not already present)
# Important: again, these are specific to how I work. Modify as needed or simply remove the section.
if ! grep -q "# Custom Aliases" "$SHELL_PROFILE" 2>/dev/null; then
	echo "--> adding custom aliases to shell profile..."

	echo '' >> "$SHELL_PROFILE"
	echo '#--------------------------------' >> "$SHELL_PROFILE"
	echo '# Custom Aliases' >> "$SHELL_PROFILE"
	echo '#--------------------------------' >> "$SHELL_PROFILE"
	echo 'alias lsa="ls -alG"' >> "$SHELL_PROFILE"
	echo 'alias ll="ls -lG"' >> "$SHELL_PROFILE"
	echo 'alias cd..="cd .."' >> "$SHELL_PROFILE"
	echo 'alias cd...="cd ../.."' >> "$SHELL_PROFILE"
	echo 'alias cd....="cd ../../.."' >> "$SHELL_PROFILE"
	echo 'alias showhosts="cat /etc/hosts"' >> "$SHELL_PROFILE"
	echo 'alias updatehosts="sudo nano /etc/hosts"' >> "$SHELL_PROFILE"
	echo 'alias showip="ifconfig | grep inet | grep -v inet6 | awk \''{print $2}\''"' >> "$SHELL_PROFILE"
	echo 'alias showip6="ifconfig | grep inet6 | awk \''{print $2}\''"' >> "$SHELL_PROFILE"
	echo 'alias path="echo -e ${PATH//:/\\n}"' >> "$SHELL_PROFILE"
	echo 'alias f="open -a Finder ./"' >> "$SHELL_PROFILE"
	echo 'alias reload="source ~/.zshrc"' >> "$SHELL_PROFILE"
	echo 'alias cls="clear"' >> "$SHELL_PROFILE"
	echo 'alias gits="git status"' >> "$SHELL_PROFILE"
	echo 'alias gita="git add ."' >> "$SHELL_PROFILE"
	echo 'alias gitaa="git add -A"' >> "$SHELL_PROFILE"
	echo 'alias gitc="git commit -m"' >> "$SHELL_PROFILE"
	echo 'alias gitp="git push"' >> "$SHELL_PROFILE"
	echo 'alias gitpl="git pull"' >> "$SHELL_PROFILE"
	echo 'alias gitco="git checkout"' >> "$SHELL_PROFILE"
	echo 'alias gitbr="git branch"' >> "$SHELL_PROFILE"
	echo 'alias gitcl="git clone"' >> "$SHELL_PROFILE"
	echo 'alias gitdiff="git diff"' >> "$SHELL_PROFILE"
	echo 'alias gitlg="git log --oneline --graph --decorate --all"' >> "$SHELL_PROFILE"

	echo "	custom aliases added"
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

if [ ${#FAILED_NPM_PACKAGES[@]} -ne 0 ]; then
	echo
	echo "--> the following npm packages failed to install:"
	for package in "${FAILED_NPM_PACKAGES[@]}"; do
		echo "		- $package"
	done
else
	echo
	echo "--> all npm packages installed successfully"
fi

echo
echo "--> finished"
echo "--> you may need to restart your terminal for all changes to take effect"
echo "--> please run the git setup script next to finish setting up git"
echo " "
