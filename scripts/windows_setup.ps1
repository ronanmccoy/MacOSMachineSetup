# ----------------------------------------------------------------
#	README
#	This PowerShell script will install Chocolatey (if not already 
#	installed) and then install a list of apps defined below.
#	It will then update VS Code with some basic settings.
#	This script WILL NOT install VS Code extensions.
#	VS Code extensions will need to be installed manually.
#
#	IMPORTANT: Run this script as Administrator
#	Right-click PowerShell and "Run as Administrator"
# ----------------------------------------------------------------

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# ------------------------
# Check for Chocolatey
# ------------------------
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "--> Chocolatey is not installed. Installing..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    
    # Refresh environment variables
    refreshenv
} else {
    Write-Host "--> Chocolatey is already installed." -ForegroundColor Green
}

# ------------------------
# Apps for installation
# ------------------------
$APPS = @(
    "androidstudio",
    "awscli", 
    "aws-cdk",
    "blender",
    "curl",
    "cursor",
    "darktable", 
    "discord",
    "docker-desktop",
    "dropbox",
    "gimp",
    "git",
    "git-flow-avh",
    "gh",
    "googlechrome",
    "googleearth-pro",
    "powershell-core",      # Windows Terminal equivalent to iTerm
    "kdiff3",
    "keepass",              # KeePassX equivalent
    "mongodb-compass",
    "ngrok",
    "nvm",                  # Node Version Manager for Windows
    "opera",
    "pgadmin4",
    "postman",
    "shotcut",
    "slack",
    "spotify",
    "stellarium",
    "sublimetext3",
    "telnet",
    "vscode",
    "vlc",
    "warp",                 # Cloudflare Warp
    "watchman",
    "wget",
    "wireshark",
    "yarn",
    "zoom"
)

$FAILED_APPS = @()

Write-Host "--> Installing apps..." -ForegroundColor Cyan
foreach ($app in $APPS) {
    Write-Host "--> Installing $app..." -ForegroundColor White
    try {
        choco install $app -y --no-progress | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`tInstalled" -ForegroundColor Green
        } else {
            Write-Host "`tFailed to install $app" -ForegroundColor Red
            $FAILED_APPS += $app
        }
    } catch {
        Write-Host "`tFailed to install $app" -ForegroundColor Red
        $FAILED_APPS += $app
    }
}

# ---------------------------------------------------
# Install Node.js via NVM
# ---------------------------------------------------
Write-Host "--> Setting up Node.js via NVM..." -ForegroundColor Cyan

# Refresh environment to ensure nvm is available
refreshenv

# Check if nvm is available and install Node
if (Get-Command nvm -ErrorAction SilentlyContinue) {
    Write-Host "--> Installing latest Node.js via NVM..." -ForegroundColor White
    nvm install latest
    nvm use latest
} else {
    Write-Host "--> NVM not found, installing Node.js directly..." -ForegroundColor Yellow
    choco install nodejs -y
}

# ------------------------
# Global NPM packages
# ------------------------
$NPM_PACKAGES = @(
    "typescript",
    "ts-node",
    "@anthropic-ai/claude-code"
)

$FAILED_NPM_PACKAGES = @()

if (Get-Command npm -ErrorAction SilentlyContinue) {
    Write-Host "--> Installing global npm packages..." -ForegroundColor Cyan
    foreach ($package in $NPM_PACKAGES) {
        Write-Host "--> Installing $package..." -ForegroundColor White
        try {
            npm install -g $package | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "`tInstalled" -ForegroundColor Green
            } else {
                Write-Host "`tFailed to install $package" -ForegroundColor Red
                $FAILED_NPM_PACKAGES += $package
            }
        } catch {
            Write-Host "`tFailed to install $package" -ForegroundColor Red
            $FAILED_NPM_PACKAGES += $package
        }
    }
} else {
    Write-Host "--> npm is not available. Skipping npm package installation." -ForegroundColor Yellow
    Write-Host "    (npm packages will need to be installed manually after Node.js is set up)" -ForegroundColor Yellow
}

# ------------------------
# VS Code settings
# ------------------------
$VSCODE_SETTINGS_PATH = "$env:APPDATA\Code\User\settings.json"

if ((Get-Command code -ErrorAction SilentlyContinue) -or (Test-Path "${env:ProgramFiles}\Microsoft VS Code\Code.exe")) {
    Write-Host "--> Updating VS Code settings..." -ForegroundColor Cyan
    
    # Create directory if it doesn't exist
    $settingsDir = Split-Path $VSCODE_SETTINGS_PATH -Parent
    if (!(Test-Path $settingsDir)) {
        New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
    }
    
    $vsCodeSettings = @{
        "editor.fontSize" = 13
        "editor.formatOnSave" = $true
        "files.autoSave" = "afterDelay"
        "editor.defaultFormatter" = "esbenp.prettier-vscode"
        "editor.wordWrap" = "on"
        "workbench.colorTheme" = "Visual Studio Dark"
        "workbench.iconTheme" = "vscode-icons"
        "editor.tabSize" = 4
    }
    
    $vsCodeSettings | ConvertTo-Json -Depth 10 | Set-Content $VSCODE_SETTINGS_PATH
    Write-Host "--> VS Code settings updated" -ForegroundColor Green
} else {
    Write-Host "--> Could not update VS Code settings. Is it installed?" -ForegroundColor Red
}

# ------------------------
# PowerShell Profile Setup
# ------------------------
Write-Host "--> Setting up PowerShell profile..." -ForegroundColor Cyan

$profilePath = $PROFILE
$profileDir = Split-Path $profilePath -Parent

# Create profile directory if it doesn't exist
if (!(Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

# Create or update PowerShell profile with useful aliases
$profileContent = @"
#--------------------------------
# Custom Aliases
#--------------------------------
Set-Alias -Name ll -Value Get-ChildItem
Set-Alias -Name la -Value Get-ChildItem
function lsa { Get-ChildItem -Force }
function cd.. { Set-Location .. }
function cd... { Set-Location ../.. }
function cd.... { Set-Location ../../.. }
function which(`$command) { Get-Command `$command | Select-Object -ExpandProperty Definition }
function reload { . `$PROFILE }
function cls-clear { Clear-Host }
Set-Alias -Name cls -Value cls-clear

# Git aliases
function gits { git status }
function gita { git add . }
function gitaa { git add -A }
function gitc { git commit -m `$args }
function gitp { git push }
function gitpl { git pull }
function gitco { git checkout `$args }
function gitbr { git branch }
function gitcl { git clone `$args }
function gitdiff { git diff }
function gitlg { git log --oneline --graph --decorate --all }

# Show current directory in prompt
function prompt {
    `$location = Get-Location
    `$gitBranch = ""
    
    # Try to get git branch if in a git repository
    try {
        `$gitBranch = git rev-parse --abbrev-ref HEAD 2>`$null
        if (`$gitBranch) {
            `$gitBranch = " (`$gitBranch)"
        }
    } catch {
        `$gitBranch = ""
    }
    
    return "`$env:USERNAME@`$env:COMPUTERNAME `$location`$gitBranch> "
}

Write-Host "PowerShell profile loaded with custom aliases!" -ForegroundColor Green
"@

# Check if profile already has custom content
if (Test-Path $profilePath) {
    $existingContent = Get-Content $profilePath -Raw
    if ($existingContent -notmatch "Custom Aliases") {
        Add-Content $profilePath "`n$profileContent"
        Write-Host "--> Custom aliases added to PowerShell profile" -ForegroundColor Green
    } else {
        Write-Host "--> PowerShell profile already has custom content" -ForegroundColor Yellow
    }
} else {
    Set-Content $profilePath $profileContent
    Write-Host "--> PowerShell profile created with custom aliases" -ForegroundColor Green
}

# --------------------------------
# List apps that failed to install
# --------------------------------
if ($FAILED_APPS.Count -gt 0) {
    Write-Host "`n--> The following apps failed to install:" -ForegroundColor Red
    foreach ($app in $FAILED_APPS) {
        Write-Host "`t- $app" -ForegroundColor Red
    }
} else {
    Write-Host "`n--> All apps installed successfully!" -ForegroundColor Green
}

if ($FAILED_NPM_PACKAGES.Count -gt 0) {
    Write-Host "`n--> The following npm packages failed to install:" -ForegroundColor Red
    foreach ($package in $FAILED_NPM_PACKAGES) {
        Write-Host "`t- $package" -ForegroundColor Red
    }
} else {
    Write-Host "`n--> All npm packages installed successfully!" -ForegroundColor Green
}

Write-Host "`n--> Setup finished!" -ForegroundColor Cyan
Write-Host "--> You may need to restart your terminal for all changes to take effect" -ForegroundColor Yellow
Write-Host "--> Consider running the git setup script next to configure git" -ForegroundColor Yellow
Write-Host " "

Read-Host "Press Enter to exit"