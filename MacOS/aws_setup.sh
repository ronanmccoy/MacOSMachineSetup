#!/bin/bash

# -----------------------------
# AWS CLI Setup Script
# -----------------------------

# Check if AWS CLI is installed
if ! command -v aws &>/dev/null; then
    echo "☁️ AWS CLI not found. Installing via Homebrew..."
    brew install awscli
    if [ $? -ne 0 ]; then
        echo "❌ Failed to install AWS CLI. Exiting."
        exit 1
    fi
else
    echo "✅ AWS CLI already installed."
fi

# Ask for AWS Profile details
read -p "Enter AWS Profile name: " PROFILE

# Ask user if they want SSO or Access Keys
echo "How do you want to configure AWS CLI?"
echo "1) SSO (Single Sign-On)"
echo "2) Access Keys"
read -p "Choose [1 or 2]: " CONFIG_TYPE

if [ "$CONFIG_TYPE" == "1" ]; then
    echo "🔑 Configuring AWS CLI with SSO"
    read -p "Enter SSO Start URL: " SSO_START_URL
    read -p "Enter SSO Region (e.g. us-east-2): " SSO_REGION
    read -p "Enter AWS Account ID: " ACCOUNT_ID
    read -p "Enter AWS Role Name: " ROLE_NAME
    read -p "Enter Default AWS Region (e.g. us-east-2): " REGION

    aws configure set sso_start_url "$SSO_START_URL" --profile "$PROFILE"
    aws configure set sso_region "$SSO_REGION" --profile "$PROFILE"
    aws configure set sso_account_id "$ACCOUNT_ID" --profile "$PROFILE"
    aws configure set sso_role_name "$ROLE_NAME" --profile "$PROFILE"
    aws configure set region "$REGION" --profile "$PROFILE"
    aws configure set output json --profile "$PROFILE"

    echo "✅ AWS CLI SSO profile '$PROFILE' configured."
    echo "👉 Run 'aws sso login --profile $PROFILE' if prompted."

elif [ "$CONFIG_TYPE" == "2" ]; then
    echo "🔑 Configuring AWS CLI with Access Keys"
    read -p "Enter AWS Region (e.g. us-west-2): " REGION
    read -p "Enter AWS Access Key ID: " AWS_ACCESS_KEY_ID
    read -s -p "Enter AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
    echo

    aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID" --profile "$PROFILE"
    aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY" --profile "$PROFILE"
    aws configure set region "$REGION" --profile "$PROFILE"
    aws configure set output json --profile "$PROFILE"

    echo "✅ AWS CLI profile '$PROFILE' configured with Access Keys."
else
    echo "❌ Invalid choice. Exiting."
    exit 1
fi

# -----------------------------
# Test AWS CLI Credentials
# -----------------------------
echo "🔍 Testing AWS CLI credentials for profile '$PROFILE'..."
TEST_OUTPUT=$(aws sts get-caller-identity --profile "$PROFILE" 2>&1)

if [ $? -eq 0 ]; then
    echo "✅ AWS CLI credentials are valid!"
    echo "$TEST_OUTPUT" | jq .
else
    echo "❌ Failed to validate AWS CLI credentials."
    echo "⚠️ Error: $TEST_OUTPUT"
    if [ "$CONFIG_TYPE" == "1" ]; then
        echo "👉 Try running: aws sso login --profile $PROFILE"
    else
        echo "👉 Double-check your Access Key and Secret Key."
    fi
fi

echo
echo "--> done! 👋 "