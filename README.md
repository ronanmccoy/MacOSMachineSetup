# My Dev Machine Setup

## Intro

A set of scripts for setting up a new dev machine. The idea here is to quickly do an initial setup including installing apps, installing NPM packages, and configurations for using Github and AWS. This is very much specific to my use case. It does not include everything a developer might need and so might not be the base setup you might want. Before using review the scripts and update the apps, NPM packages, and the themes as needed (refer to the appropriate files in the /data directory).

## Structure

- `/data` - make edits here for specific applications or NPM packages to install. Also saved here is my current iTerm theme file used when installing iTerm in the OS setup script. If you don't want the theme to be installed remove or rename the theme file.
- `/Linux` - this is a "to do".
- `/MacOS` - bash scripts to run individually.
- `/Windows` - this is a "to do".

## Requirements

- Pick your OS (currently this only works for MacOS)
- Familiarity with using your terminal.
- Familiarity with basic bash scripts.
- If setting up git for use with Github, log into your github account and keep handy the name and email address to use for your global git configuration.
- If setting up AWS CLI, have your AWS access key and secret key from your AWS user account in the IAM dashboard.

## Installation and Usage

1. Clone this repo.
2. Open terminal on your machine and `cd` to the directory where this was cloned on your system.
3. `cd` into `/data` and review the list of applications and NPM packages, making any necessary updates. Also make note of the theme file for iTerm, making updates if needed. Note that for the "txt" files for the apps and NPM packages, use a `#` to comment out an app or package that you do not want to install.
4. Then `cd` into the directory specific to your platform (currently this has only been tested on MacOS).
5. From the terminal run:
   - `sh [PLATFORM]_setup.sh` (e.g. `sh mac_setup.sh`)
   - `sh git_setup.sh` (if setting up git)
   - `sh aws_setup.sh` (if setting up AWS)
6. (Optional) delete the scripts and the directory when done.

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

## To Do

- [ ] Add [AWS-CDK](https://github.com/aws/aws-cdk?tab=readme-ov-file#getting-started).
- [ ] Add theme files for other terminal apps (e.g. Warp)
- [ ] Add scripts for setting up Windows.
- [ ] Add scripts for setting up Linux.
