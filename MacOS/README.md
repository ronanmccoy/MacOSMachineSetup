# MacOS Setup

## Intro

Scripts to do the initial setup on MacOs.

## Instructions

1. Review `apps.txt`.
2. Run `sh mac_setup.sh`.
3. (Optional) Run `sh git_setup.sh`.
4. (Optional) Run `sh aws_setup.sh`.

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

## To do

- [ ] add some prompt asking if the aliases should be set up or skipped.
- [ ] add a prompt asking if the iTerms theme should be installed or skipped.
- [ ] add a prompt asking if the settings update to VS Code should be done.
- [ ] add a prompt asking if the shell prompt should be set up to show git branch information.
