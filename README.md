# MacOS Machine Setup

## Intro

A set of scripts for setting up a new mac for dev work. This is specific to me and is for a base setup (there certainly are additional configurations and software that a developer might need). Note that this includes a theme and custom settings that are specific to my liking. And what I like, might not be what you like!

## Requirements

If setting up AWS CLI, have available all the necessary credential information.

## Installation and Usage

1. Clone this repo.
2. Open terminal on your machine and `cd` to the directory `scripts` in the project directoru where this has been cloned to.
3. From the terminal run:
   - `sh mac_setup.sh`
   - `sh git_setup.sh`
   - `sh aws_setup.sh`
4. (Optional) delete the scripts and the directory when done.

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
