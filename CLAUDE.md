# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a macOS machine setup automation repository containing bash scripts for setting up a development environment on a new Mac. The scripts handle installation and configuration of development tools, applications, and environment customizations.

## Project Structure

- `scripts/` - Contains all setup scripts
  - `mac_setup.sh` - Main setup script for apps, tools, and environment
  - `git_setup.sh` - Git configuration and SSH key generation
  - `aws_setup.sh` - AWS CLI configuration (SSO or Access Keys)
  - `iTerm-Ronans-Theme.json` - Custom iTerm2 theme file

## Common Commands

### Running Setup Scripts
Execute scripts from the `scripts` directory:
```bash
cd scripts
sh mac_setup.sh    # Install apps and configure environment
sh git_setup.sh    # Configure git and generate SSH keys
sh aws_setup.sh    # Configure AWS CLI
```

### Testing Scripts
No automated tests exist. Manual verification involves:
- Running scripts on clean macOS system
- Checking app installations: `brew list --cask`
- Verifying git config: `git config --list | grep -E "user.name|user.email"`
- Testing AWS CLI: `aws sts get-caller-identity --profile [profile-name]`

## Architecture and Key Components

### mac_setup.sh
- **Homebrew Management**: Checks/installs Homebrew, handles both Intel and Apple Silicon paths
- **App Installation Array**: Uses `APPS` array for batch installation via `brew install --cask` and `brew install`
- **NVM Integration**: Complex PATH handling and shell profile sourcing to ensure NVM availability
- **NPM Global Packages**: Installs TypeScript, ts-node, and Claude Code CLI
- **VS Code Configuration**: Creates/updates settings.json with opinionated defaults
- **iTerm Theme**: Copies theme file to DynamicProfiles directory
- **Shell Customization**: Adds custom prompt, aliases, and NVM setup to shell profile (.zshrc/.bash_profile)
- **Error Tracking**: Maintains `FAILED_APPS` and `FAILED_NPM_PACKAGES` arrays for reporting

### git_setup.sh
- **Interactive Setup**: Prompts for user name and email
- **Global Configuration**: Sets user info and default branch to 'main'
- **Global Gitignore**: Creates comprehensive `.gitignore_global` with common patterns
- **SSH Key Generation**: Creates ed25519 SSH key for GitHub, adds to ssh-agent

### aws_setup.sh
- **Dual Configuration**: Supports both SSO and Access Key authentication
- **Profile Management**: Creates named AWS profiles
- **Credential Validation**: Tests configuration with `aws sts get-caller-identity`

## Development Notes

- Scripts include extensive user feedback and error handling
- All scripts check for existing installations before proceeding
- Shell profile modifications are idempotent (won't duplicate entries)
- Scripts are designed for macOS-specific paths and conventions
- Custom aliases and prompt are author-specific preferences

## Important Files

- `README.md` - User-facing documentation and installation instructions
- `scripts/iTerm-Ronans-Theme.json` - Required theme file (must be in same directory as mac_setup.sh)
- Generated files after running scripts:
  - `~/.gitignore_global` - Global git ignore rules
  - `~/.ssh/id_ed25519*` - Generated SSH keys
  - VS Code settings at `~/Library/Application Support/Code/User/settings.json`