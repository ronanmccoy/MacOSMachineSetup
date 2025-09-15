# MacOS Setup

## Intro

Scripts specific to MacOS. Uses Homebrew to install apps.

## Instructions

1. Review `apps.txt`.
2. Run `sh mac_setup.sh` (might need to use `sudo`).
3. (Optional) Run `sh git_setup.sh` (might need to use `sudo`).
4. (Optional) Run `sh aws_setup.sh` (might need to use `sudo`).

### apps.txt

First update the list of apps as needed. The apps here are specific to my usecase and might not fit your needs.

### mac_setup.sh

This script will do the following:

- Install Homebrew.
- Attempt to install the apps listed in `apps.txt`.
- Install the latest version of Node via NVM (FYI, NVM is an app listed in `apps.txt`).
- Install NPM packages listed in `/data/packages/packages.txt`.
- Apply some basic settings to VS Code (set dark theme, vs code icons, font size, and tab size).
- Set Iterm theme from `/data/themes/iTerm-Ronans-Theme.json` (if the theme file does not exist, it will skip this step).
- Customize the shell prompt to show git branch information when in a git project.
- Add some aliases to the shell profile (search for "my custom aliases" in `mac_setup.sh` to modify or remove this section).
- If any apps or NPM packages failed to install, print a list of them for manual resolution.

### Prompt Aliases

The list of aliases that will be added to the shell profile is very specific to my usecase. These aliases I've been using for years and, admittedly they might not be ideal, but I'm simply used to them. For your usecase feel free to modify this list. Simply search for "my custom aliases" in the script. They can be removed from `mac_setup.sh` without any negative effects. Or one can add new aliases or modify/remove existing ones.

## Additional Steps

1. The `mac_setup.sh` script only installs a set of predefined apps and an iTerm theme. After running both scripts, open iTerm and set the new theme as the default if so desired.

2. Also, after running the scripts, you will need to install VS Code extensions as needed. For starters I install the following extensions (note this will be an ever-evolving list):

- Auto Rename Tag
- Better Comments
- Bookmarks
- Claude Code for VSCode
- ES7+React/Redux/React-Native snippets
- ESLint
- Github Copilot
- Github Copilot Chat
- Javascript and Typescript Nightly
- npm Intellisense
- Prettier - Code Formatter
- Tailwind CSS Intellisense
- Todo Tree
- vscode-icons

This list of extensions will eventually be added to the `mac_setup.sh` script.

## To do

- [ ] add some prompt asking if the aliases should be set up or skipped.
- [ ] add a prompt asking if the iTerms theme should be installed or skipped.
- [ ] add a prompt asking if the settings update to VS Code should be done.
- [ ] add a prompt asking if the shell prompt should be set up to show git branch information.
- [ ] updated script to install VS Code extensions and list the extensions in an external file.
