# ----------------------------------------------------------------
#	README
#	This script will install Chocolatey, if it's not already 
#	installed, and then install a list of apps defined in external files.
#	It will then 
#	    - update VS Code with some basic settings, and
#		- configure Windows Terminal with a custom theme.
#
#	This script WILL NOT however install VS Code extensions.
#	VS Code extensions will need to be installed manually.
#
#	When complete, it will list any apps or npm packages that 
#	failed to install, if any. Or it will confirm that all
#	apps and packages were installed successfully.
#
#	IMPORTANT NOTE: the Windows Terminal theme file, WindowsTerminal-Theme.json
#	is expected to be in a folder called `themes` that's one level
#	above where this script is.
# ----------------------------------------------------------------

# Get script directory
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Definition
$APP_LIST_FILE = Join-Path $SCRIPT_DIR "apps.txt"
$NPM_PACKAGES_FILE = Join-Path $SCRIPT_DIR "..\data\packages\packages.txt"
$TERMINAL_THEME_FILE = Join-Path $SCRIPT_DIR "..\data\themes\WindowsTerminal-Ronans-Theme.json"

# Function to check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check if running as administrator
if (-not (Test-Administrator)) {
    Write-Host "--> This script needs to be run as Administrator. Please restart PowerShell as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Set execution policy for the session
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force

# ------------------------
# Check for Chocolatey
# ------------------------
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "--> Chocolatey is not installed. Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    
    # Refresh environment variables
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
} else {
    Write-Host "--> Chocolatey is already installed."
}

# ------------------------
# Apps for installation
# ------------------------
$APPS = @()
$FAILED_APPS = @()

# Get apps list from file
Write-Host "--> Reading apps list from $APP_LIST_FILE"
if (-not (Test-Path $APP_LIST_FILE)) {
    Write-Host "ERROR: apps.txt file not found at $APP_LIST_FILE" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$appLines = Get-Content $APP_LIST_FILE | Where-Object { 
    $_.Trim() -ne "" -and -not $_.Trim().StartsWith("#") 
}

foreach ($line in $appLines) {
    $trimmedLine = $line.Trim()
    if ($trimmedLine -ne "") {
        $APPS += $trimmedLine
    }
}

Write-Host "--> Installing apps via Chocolatey..."
foreach ($app in $APPS) {
    Write-Host "--> Installing $app..."
    try {
        $result = choco install $app -y --no-progress 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    installed" -ForegroundColor Green
        } else {
            Write-Host "    failed to install $app" -ForegroundColor Red
            $FAILED_APPS += $app
        }
    } catch {
        Write-Host "    failed to install $app" -ForegroundColor Red
        $FAILED_APPS += $app
    }
}

# ---------------------------------------------------
# Refresh environment and install Node via nvm-windows
# ---------------------------------------------------
# Refresh environment variables to pick up newly installed tools
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Wait a moment to ensure PATH is updated
Start-Sleep -Seconds 4

Write-Host "--> Setting up Node.js via nvm-windows (if installed)..."
if (Get-Command nvm -ErrorAction SilentlyContinue) {
    try {
        nvm install latest
        nvm use (nvm list | Select-String "latest" | ForEach-Object { $_.ToString().Trim() })
        Write-Host "    Node.js installed via nvm" -ForegroundColor Green
    } catch {
        Write-Host "    Failed to install Node.js via nvm" -ForegroundColor Yellow
    }
} else {
    Write-Host "    nvm-windows not found. Node.js will need to be installed separately if not already installed."
}

# ------------------------
# Global NPM packages
# ------------------------
$NPM_PACKAGES = @()
$FAILED_NPM_PACKAGES = @()

# Get npm packages list from file
Write-Host "--> Reading npm packages list from $NPM_PACKAGES_FILE"
if (-not (Test-Path $NPM_PACKAGES_FILE)) {
    Write-Host "ERROR: packages.txt file not found at $NPM_PACKAGES_FILE" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$packageLines = Get-Content $NPM_PACKAGES_FILE | Where-Object { 
    $_.Trim() -ne "" -and -not $_.Trim().StartsWith("#") -and -not ($_.Trim() -match "---\s*IGNORE\s*---")
}

foreach ($line in $packageLines) {
    $trimmedLine = $line.Trim()
    if ($trimmedLine -ne "") {
        $NPM_PACKAGES += $trimmedLine
    }
}

if (Get-Command npm -ErrorAction SilentlyContinue) {
    Write-Host "--> Installing global npm packages..."
    foreach ($package in $NPM_PACKAGES) {
        Write-Host "--> Installing $package..."
        try {
            $result = npm install -g $package 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "    installed" -ForegroundColor Green
            } else {
                Write-Host "    failed to install $package" -ForegroundColor Red
                $FAILED_NPM_PACKAGES += $package
            }
        } catch {
            Write-Host "    failed to install $package" -ForegroundColor Red
            $FAILED_NPM_PACKAGES += $package
        }
    }
} else {
    Write-Host "--> npm is not available. Skipping npm package installation."
    Write-Host "    (npm packages will need to be installed manually after Node.js is set up)"
}

# ------------------------
# VS Code settings
# ------------------------
$VSCODE_SETTINGS_DIR = Join-Path $env:APPDATA "Code\User"
$VSCODE_SETTINGS_FILE = Join-Path $VSCODE_SETTINGS_DIR "settings.json"

if ((Get-Command code -ErrorAction SilentlyContinue) -or (Test-Path "${env:ProgramFiles}\Microsoft VS Code\Code.exe") -or (Test-Path "${env:LOCALAPPDATA}\Programs\Microsoft VS Code\Code.exe")) {
    Write-Host "--> Updating VS Code settings..."
    
    # Create directory if it doesn't exist
    if (-not (Test-Path $VSCODE_SETTINGS_DIR)) {
        New-Item -ItemType Directory -Path $VSCODE_SETTINGS_DIR -Force | Out-Null
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
    
    $vsCodeSettings | ConvertTo-Json -Depth 10 | Out-File -FilePath $VSCODE_SETTINGS_FILE -Encoding utf8
    Write-Host "    VS Code settings updated" -ForegroundColor Green
} else {
    Write-Host "--> Could not update VS Code settings. Is it installed?" -ForegroundColor Yellow
}

# ------------------------
# Set Windows Terminal theme
# ------------------------
$TERMINAL_SETTINGS_PATH = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

if (Test-Path $TERMINAL_SETTINGS_PATH) {
    if (Test-Path $TERMINAL_THEME_FILE) {
        Write-Host "--> Applying Windows Terminal theme..."
        try {
            # Read the existing settings
            $terminalSettings = Get-Content $TERMINAL_SETTINGS_PATH -Raw | ConvertFrom-Json
            
            # Read the theme file
            $themeData = Get-Content $TERMINAL_THEME_FILE -Raw | ConvertFrom-Json
            
            # Add or update the theme in schemes if it exists in the theme file
            if ($themeData.schemes) {
                if (-not $terminalSettings.schemes) {
                    $terminalSettings | Add-Member -Type NoteProperty -Name "schemes" -Value @()
                }
                
                foreach ($scheme in $themeData.schemes) {
                    # Remove existing scheme with same name if it exists
                    $terminalSettings.schemes = $terminalSettings.schemes | Where-Object { $_.name -ne $scheme.name }
                    # Add the new scheme
                    $terminalSettings.schemes += $scheme
                }
            }
            
            # Save the updated settings
            $terminalSettings | ConvertTo-Json -Depth 10 | Out-File -FilePath $TERMINAL_SETTINGS_PATH -Encoding utf8
            Write-Host "    Windows Terminal theme applied. You can select it in Terminal Settings -> Appearance" -ForegroundColor Green
        } catch {
            Write-Host "    Failed to apply Windows Terminal theme: $_" -ForegroundColor Red
            $FAILED_APPS += "(Windows Terminal theme application failed)"
        }
    } else {
        Write-Host "--> ERROR: Windows Terminal theme file not found ($TERMINAL_THEME_FILE)" -ForegroundColor Red
        $FAILED_APPS += "(Windows Terminal theme file is missing)"
    }
} else {
    Write-Host "--> Windows Terminal is not installed or settings file not found" -ForegroundColor Yellow
    $FAILED_APPS += "(could not find Windows Terminal)"
}

# ------------------------------------
# Add customizations to PowerShell profile
# ------------------------------------
$PROFILE_PATH = $PROFILE

Write-Host "--> Adding customizations to PowerShell profile..."

# Create profile if it doesn't exist
if (-not (Test-Path $PROFILE_PATH)) {
    New-Item -ItemType File -Path $PROFILE_PATH -Force | Out-Null
}

$profileContent = ""
if (Test-Path $PROFILE_PATH) {
    $profileContent = Get-Content $PROFILE_PATH -Raw
}

# Add custom aliases if not already present
if ($profileContent -notmatch "# Custom Aliases") {
    Write-Host "    Adding custom aliases to PowerShell profile..."
    
    $aliasesContent = @"

#--------------------------------
# Custom Aliases
#--------------------------------
function ll { Get-ChildItem -Force }
function lsa { Get-ChildItem -Force }
function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }
function gits { git status }
function gita { git add . }
function gitaa { git add -A }
function gitc { param(`$message) git commit -m "`$message" }
function gitp { git push }
function gitpl { git pull }
function gitco { param(`$branch) git checkout `$branch }
function gitbr { git branch }
function gitcl { param(`$repo) git clone `$repo }
function gitdiff { git diff }
function gitlg { git log --oneline --graph --decorate --all }
function showip { (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { `$_.IPAddress -ne "127.0.0.1" }).IPAddress }
function path { `$env:Path -split ";" }
function reload { & `$profile }
function cls-real { Clear-Host }

# Git aliases
Set-Alias -Name "f" -Value "explorer.exe"

"@
    
    Add-Content -Path $PROFILE_PATH -Value $aliasesContent
    Write-Host "    Custom aliases added" -ForegroundColor Green
}

# --------------------------------
# List apps that failed to install
# --------------------------------
Write-Host ""
if ($FAILED_APPS.Count -gt 0) {
    Write-Host "--> The following apps failed to install:" -ForegroundColor Red
    foreach ($app in $FAILED_APPS) {
        Write-Host "        - $app" -ForegroundColor Red
    }
} else {
    Write-Host "--> All apps installed successfully" -ForegroundColor Green
}

Write-Host ""
if ($FAILED_NPM_PACKAGES.Count -gt 0) {
    Write-Host "--> The following npm packages failed to install:" -ForegroundColor Red
    foreach ($package in $FAILED_NPM_PACKAGES) {
        Write-Host "        - $package" -ForegroundColor Red
    }
} else {
    Write-Host "--> All npm packages installed successfully" -ForegroundColor Green
}

Write-Host ""
Write-Host "--> Finished" -ForegroundColor Green
Write-Host "--> You will need to restart your terminal for all changes to take effect."
Write-Host "--> Please run the git setup script next to finish setting up git"
Write-Host " "

# Keep the window open
Read-Host "Press Enter to exit"
