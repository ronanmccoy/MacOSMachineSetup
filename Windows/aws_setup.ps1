# -----------------------------
# AWS CLI Setup Script for Windows
# -----------------------------

# Function to check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

Write-Host "AWS CLI Setup Script for Windows" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Check if AWS CLI is installed
if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Host "AWS CLI not found. Installing via Chocolatey..." -ForegroundColor Yellow
    
    # Check if Chocolatey is available
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "Chocolatey is not installed. Please install Chocolatey first or install AWS CLI manually." -ForegroundColor Red
        Write-Host "You can:" -ForegroundColor White
        Write-Host "  1. Install Chocolatey: https://chocolatey.org/install" -ForegroundColor White
        Write-Host "  2. Install AWS CLI directly: https://aws.amazon.com/cli/" -ForegroundColor White
        Write-Host "  3. Use MSI installer: https://awscli.amazonaws.com/AWSCLIV2.msi" -ForegroundColor White
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    try {
        # Check if we need admin privileges for Chocolatey
        if (-not (Test-Administrator)) {
            Write-Host "Administrator privileges may be required for Chocolatey installation." -ForegroundColor Yellow
            Write-Host "If installation fails, please restart as Administrator." -ForegroundColor Yellow
        }
        
        choco install awscli -y
        if ($LASTEXITCODE -ne 0) {
            throw "Chocolatey installation failed"
        }
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        # Verify installation
        if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
            throw "AWS CLI not found after installation"
        }
        
        Write-Host "AWS CLI installed successfully" -ForegroundColor Green
    } catch {
        Write-Host "Failed to install AWS CLI: $_" -ForegroundColor Red
        Write-Host "Please install AWS CLI manually from: https://aws.amazon.com/cli/" -ForegroundColor Yellow
        Read-Host "Press Enter to exit"
        exit 1
    }
} else {
    Write-Host "AWS CLI already installed" -ForegroundColor Green
    $awsVersion = aws --version 2>$null
    if ($awsVersion) {
        Write-Host "Version: $awsVersion" -ForegroundColor White
    }
}

Write-Host ""

# Ask for AWS Profile details
$PROFILE = Read-Host "Enter AWS Profile name"
if ([string]::IsNullOrWhiteSpace($PROFILE)) {
    Write-Host "Profile name cannot be empty. Exiting." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Ask user if they want SSO or Access Keys
Write-Host ""
Write-Host "How do you want to configure AWS CLI?" -ForegroundColor Cyan
Write-Host "1) SSO (Single Sign-On)" -ForegroundColor White
Write-Host "2) Access Keys" -ForegroundColor White

do {
    $CONFIG_TYPE = Read-Host "Choose [1 or 2]"
} while ($CONFIG_TYPE -notin @("1", "2"))

if ($CONFIG_TYPE -eq "1") {
    Write-Host ""
    Write-Host "Configuring AWS CLI with SSO" -ForegroundColor Cyan
    
    $SSO_START_URL = Read-Host "Enter SSO Start URL"
    $SSO_REGION = Read-Host "Enter SSO Region (e.g. us-east-2)"
    $ACCOUNT_ID = Read-Host "Enter AWS Account ID"
    $ROLE_NAME = Read-Host "Enter AWS Role Name"
    $REGION = Read-Host "Enter Default AWS Region (e.g. us-east-2)"
    
    # Validate required inputs
    if ([string]::IsNullOrWhiteSpace($SSO_START_URL) -or 
        [string]::IsNullOrWhiteSpace($SSO_REGION) -or 
        [string]::IsNullOrWhiteSpace($ACCOUNT_ID) -or 
        [string]::IsNullOrWhiteSpace($ROLE_NAME) -or 
        [string]::IsNullOrWhiteSpace($REGION)) {
        Write-Host "All fields are required for SSO configuration. Exiting." -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    try {
        aws configure set sso_start_url "$SSO_START_URL" --profile "$PROFILE"
        aws configure set sso_region "$SSO_REGION" --profile "$PROFILE"
        aws configure set sso_account_id "$ACCOUNT_ID" --profile "$PROFILE"
        aws configure set sso_role_name "$ROLE_NAME" --profile "$PROFILE"
        aws configure set region "$REGION" --profile "$PROFILE"
        aws configure set output json --profile "$PROFILE"
        
        Write-Host ""
        Write-Host "AWS CLI SSO profile '$PROFILE' configured successfully" -ForegroundColor Green
        Write-Host "Run 'aws sso login --profile $PROFILE' if prompted" -ForegroundColor Yellow
    } catch {
        Write-Host "Failed to configure SSO profile: $_" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }

} elseif ($CONFIG_TYPE -eq "2") {
    Write-Host ""
    Write-Host "Configuring AWS CLI with Access Keys" -ForegroundColor Cyan
    
    $REGION = Read-Host "Enter AWS Region (e.g. us-west-2)"
    $AWS_ACCESS_KEY_ID = Read-Host "Enter AWS Access Key ID"
    
    # Secure input for secret key
    $AWS_SECRET_ACCESS_KEY = Read-Host "Enter AWS Secret Access Key" -AsSecureString
    $AWS_SECRET_ACCESS_KEY_PLAIN = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($AWS_SECRET_ACCESS_KEY))
    
    # Validate required inputs
    if ([string]::IsNullOrWhiteSpace($REGION) -or 
        [string]::IsNullOrWhiteSpace($AWS_ACCESS_KEY_ID) -or 
        [string]::IsNullOrWhiteSpace($AWS_SECRET_ACCESS_KEY_PLAIN)) {
        Write-Host "All fields are required for Access Key configuration. Exiting." -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    try {
        aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID" --profile "$PROFILE"
        aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY_PLAIN" --profile "$PROFILE"
        aws configure set region "$REGION" --profile "$PROFILE"
        aws configure set output json --profile "$PROFILE"
        
        # Clear the plain text secret from memory
        $AWS_SECRET_ACCESS_KEY_PLAIN = $null
        [System.GC]::Collect()
        
        Write-Host ""
        Write-Host "AWS CLI profile '$PROFILE' configured with Access Keys successfully" -ForegroundColor Green
    } catch {
        Write-Host "Failed to configure Access Key profile: $_" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# -----------------------------
# Test AWS CLI Credentials
# -----------------------------
Write-Host ""
Write-Host "Testing AWS CLI credentials for profile '$PROFILE'..." -ForegroundColor Cyan

try {
    # Use proper PowerShell error handling for external commands
    $result = & aws sts get-caller-identity --profile "$PROFILE" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "AWS CLI credentials are valid!" -ForegroundColor Green
        
        # Filter out any non-JSON content and parse JSON output
        $jsonLines = $result | Where-Object { $_ -match '^\s*[\{\[]' -or $_ -match '^\s*["\d]' -or $_ -match '^\s*\}' }
        $jsonString = $jsonLines -join "`n"
        
        try {
            $jsonOutput = $jsonString | ConvertFrom-Json -ErrorAction Stop
            Write-Host ""
            Write-Host "Account Details:" -ForegroundColor White
            Write-Host "  User ID: $($jsonOutput.UserId)" -ForegroundColor White
            Write-Host "  Account: $($jsonOutput.Account)" -ForegroundColor White
            Write-Host "  ARN: $($jsonOutput.Arn)" -ForegroundColor White
        } catch {
            # If JSON parsing fails, show the raw output that looks like JSON
            Write-Host "Raw output:" -ForegroundColor White
            Write-Host "$result" -ForegroundColor White
        }
    } else {
        Write-Host "Failed to validate AWS CLI credentials" -ForegroundColor Red
        
        # Show error output
        $errorOutput = $result | Where-Object { $_ -and $_.ToString().Trim() }
        if ($errorOutput) {
            Write-Host "Error details:" -ForegroundColor Red
            foreach ($line in $errorOutput) {
                Write-Host "  $line" -ForegroundColor Red
            }
        }
        
        # Provide helpful suggestions based on configuration type
        if ($CONFIG_TYPE -eq "1") {
            Write-Host "For SSO configuration, try running: aws sso login --profile $PROFILE" -ForegroundColor Yellow
        } else {
            Write-Host "For Access Key configuration:" -ForegroundColor Yellow
            Write-Host "  - Verify your Access Key and Secret Key are correct" -ForegroundColor Yellow
            Write-Host "  - Check that your AWS account has the necessary permissions" -ForegroundColor Yellow
            Write-Host "  - Ensure the region is correct" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "Error executing AWS CLI command: $_" -ForegroundColor Red
    
    if ($CONFIG_TYPE -eq "1") {
        Write-Host "For SSO, you may need to run: aws sso login --profile $PROFILE" -ForegroundColor Yellow
    } else {
        Write-Host "Please verify your AWS configuration and try again" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Setup completed!" -ForegroundColor Green

# Keep window open
Read-Host "Press Enter to exit"
