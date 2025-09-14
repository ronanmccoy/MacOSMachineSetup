# -------------------------------------------------------------
#	README
#	Run this PowerShell script as Administrator on Windows.
#	This will check if git is installed, and if it is will 
#	update git config, set global git ignore, and generate a
#	new SSH key for Github.com if one doesn't already exist.
# -------------------------------------------------------------

# Function to check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check if running as administrator (needed for some SSH operations)
if (-not (Test-Administrator)) {
    Write-Host "--> Note: Some SSH operations may require Administrator privileges." -ForegroundColor Yellow
    Write-Host "--> If you encounter issues, please restart PowerShell as Administrator." -ForegroundColor Yellow
    Write-Host ""
}

# ------------------------
# Check for git
# ------------------------
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR!!" -ForegroundColor Red
    Write-Host "Git is not installed. Please install git before running this script." -ForegroundColor Red
    Write-Host "You can install it via Chocolatey with: choco install git" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "--> Git found: $(git --version)" -ForegroundColor Green

# ------------------------
# User info
# ------------------------
$GIT_USER_NAME = Read-Host "Enter your name to use with git"
$GIT_USER_EMAIL = Read-Host "Enter your email to use with git"
$SSH_KEY_COMMENT = $GIT_USER_EMAIL

# ------------------------
# Git config
# ------------------------
Write-Host ""
Write-Host "--> Setting up git global config..." -ForegroundColor Cyan

try {
    git config --global user.name "$GIT_USER_NAME"
    git config --global user.email "$GIT_USER_EMAIL"
    git config --global init.defaultBranch main
    
    # Additional Windows-specific git configurations
    git config --global core.autocrlf true
    git config --global core.filemode false
    git config --global core.ignorecase true
    
    Write-Host "    Git config updated successfully" -ForegroundColor Green
} catch {
    Write-Host "    Error setting git config: $_" -ForegroundColor Red
    Read-Host "Press Enter to continue anyway"
}

# ------------------------
# Git global ignore
# ------------------------
Write-Host ""
Write-Host "--> Setting up global ignore for git..." -ForegroundColor Cyan

$GLOBAL_GITIGNORE = Join-Path $env:USERPROFILE ".gitignore_global"

# Create the global gitignore file
$gitignoreContent = @"
# OS
.DS_Store
Thumbs.db
Desktop.ini
`$RECYCLE.BIN/
*.tmp

# Windows
*.lnk
*.ini
ehthumbs.db
ehthumbs_vista.db

# Editors
.vscode/
*.code-workspace
*.sublime-workspace
*.sublime-project
.idea/
*.swp
*.swo

# Logs
*.log
npm-debug.log*
yarn-debug.log*
pnpm-debug.log*
lerna-debug.log*

# Environment
.env
.env.local
.env.*.local
.env.development
.env.test
.env.production

# Node
node_modules/
dist/
build/
out/
*.tsbuildinfo
.npm
.eslintcache
.nyc_output

# PHP
vendor/
.phpunit.result.cache

# Python
__pycache__/
*.py[cod]
*`$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Dart/Flutter
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
build/
flutter_*.png

# Misc
*.ronan
*.ronan.*
devnotes.*
notes.*
TODO.md
TEMP/
temp/

"@

try {
    $gitignoreContent | Out-File -FilePath $GLOBAL_GITIGNORE -Encoding utf8
    git config --global core.excludesfile "$GLOBAL_GITIGNORE"
    Write-Host "    Created global gitignore at $GLOBAL_GITIGNORE" -ForegroundColor Green
} catch {
    Write-Host "    Error creating global gitignore: $_" -ForegroundColor Red
}

# ------------------------
# SSH key for GitHub
# ------------------------
Write-Host ""
Write-Host "--> Setting up SSH key for GitHub..." -ForegroundColor Cyan

$SSH_DIR = Join-Path $env:USERPROFILE ".ssh"
$SSH_KEY_PATH = Join-Path $SSH_DIR "id_ed25519"

# Create .ssh directory if it doesn't exist
if (-not (Test-Path $SSH_DIR)) {
    New-Item -ItemType Directory -Path $SSH_DIR -Force | Out-Null
    # Set appropriate permissions for .ssh directory on Windows
    icacls $SSH_DIR /inheritance:d | Out-Null
    icacls $SSH_DIR /grant:r "$($env:USERNAME):F" | Out-Null
    icacls $SSH_DIR /remove "Users" | Out-Null
}

if (Test-Path $SSH_KEY_PATH) {
    Write-Host "    SSH key already exists at $SSH_KEY_PATH" -ForegroundColor Yellow
} else {
    Write-Host "    Generating new SSH key..." -ForegroundColor Cyan
    
    try {
        # Generate SSH key
        ssh-keygen -t ed25519 -C "$SSH_KEY_COMMENT" -f "$SSH_KEY_PATH" -N '""'
        
        # Set proper permissions on SSH key files
        icacls "$SSH_KEY_PATH" /inheritance:d | Out-Null
        icacls "$SSH_KEY_PATH" /grant:r "$($env:USERNAME):F" | Out-Null
        icacls "$SSH_KEY_PATH" /remove "Users" | Out-Null
        
        icacls "$SSH_KEY_PATH.pub" /inheritance:d | Out-Null
        icacls "$SSH_KEY_PATH.pub" /grant:r "$($env:USERNAME):F" | Out-Null
        icacls "$SSH_KEY_PATH.pub" /remove "Users" | Out-Null
        
        Write-Host "    SSH key generated successfully" -ForegroundColor Green
        
        # Try to start ssh-agent and add key
        try {
            # Start ssh-agent if not running
            $sshAgentStatus = Get-Service ssh-agent -ErrorAction SilentlyContinue
            if ($sshAgentStatus -and $sshAgentStatus.Status -ne 'Running') {
                Start-Service ssh-agent
                Write-Host "    Started SSH agent service" -ForegroundColor Green
            }
            
            # Add key to ssh-agent
            ssh-add "$SSH_KEY_PATH" 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "    SSH key added to ssh-agent" -ForegroundColor Green
            } else {
                Write-Host "    Could not add SSH key to ssh-agent (this is usually fine)" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "    Could not manage ssh-agent (this is usually fine)" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "    Error generating SSH key: $_" -ForegroundColor Red
        Write-Host "    You may need to install OpenSSH client via Windows Features or run as Administrator" -ForegroundColor Yellow
    }
}

# Display the public key
Write-Host ""
if (Test-Path "$SSH_KEY_PATH.pub") {
    Write-Host "--> Copy the following SSH key and add it to GitHub.com (https://github.com/settings/keys):" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "--- BEGIN SSH KEY ---" -ForegroundColor Green
    Get-Content "$SSH_KEY_PATH.pub"
    Write-Host "--- END SSH KEY ---" -ForegroundColor Green
    Write-Host ""
    
    # Copy to clipboard if possible
    try {
        if (Get-Command Set-Clipboard -ErrorAction SilentlyContinue) {
            Get-Content "$SSH_KEY_PATH.pub" | Set-Clipboard
            Write-Host "    SSH key has been copied to your clipboard!" -ForegroundColor Cyan
        } else {
            Write-Host "    (Set-Clipboard not available - please copy the key manually)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "    (Could not copy to clipboard - please copy the key manually)" -ForegroundColor Yellow
    }
} else {
    Write-Host "    Could not find the generated SSH public key" -ForegroundColor Red
}

# ------------------------
# Summary
# ------------------------
Write-Host ""
Write-Host "--> Setup completed" -ForegroundColor Green
Write-Host "--> Global git config:" -ForegroundColor Cyan

try {
    $gitConfig = git config --list | Where-Object { $_ -match "user\.name|user\.email|core\.excludesfile" }
    foreach ($config in $gitConfig) {
        Write-Host "    $config" -ForegroundColor White
    }
} catch {
    Write-Host "    Could not retrieve git config" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "After adding the SSH key to GitHub, test SSH connection to GitHub with:" -ForegroundColor Yellow
Write-Host "ssh -T git@github.com" -ForegroundColor White
Write-Host ""

# Additional Windows-specific information
Write-Host "Windows-specific notes:" -ForegroundColor Cyan
Write-Host "  - Line endings set to 'autocrlf=true' for proper Windows handling" -ForegroundColor White
Write-Host "  - File mode checking disabled (filemode=false)" -ForegroundColor White
Write-Host "  - Case sensitivity handled appropriately (ignorecase=true)" -ForegroundColor White
Write-Host ""

Write-Host "--> Done! 👋" -ForegroundColor Green

# Keep window open
Read-Host "Press Enter to exit"
