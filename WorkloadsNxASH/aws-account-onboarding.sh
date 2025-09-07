#!/bin/bash

# AWS Account Onboarding Script
# This script sets up a new AWS account with required resources for GitHub Actions and Terraform

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default parameters (can be overridden via command line arguments)
ACM_DOMAIN="${1:-*.nvisionx.ai}"
TF_STATE_BUCKET="${2:-tfstate-ash-nx}"
TF_DYNAMODB_TABLE="${3:-tflocks-ash-nx}"
GITHUB_ORG="${4:-Nvision-x}"
OIDC_ROLE_NAME="${5:-NxGitHubActionsRole}"
AWS_REGION="${AWS_REGION:-us-east-1}"

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}AWS Account Onboarding Script${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""

# Function to check if AWS CLI is installed and configured
check_aws_cli() {
    echo -e "${YELLOW}Checking AWS CLI configuration...${NC}"
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}AWS CLI is not installed. Please install it first.${NC}"
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}AWS CLI is not configured. Please run 'aws configure' first.${NC}"
        exit 1
    fi
    
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    echo -e "${GREEN}✓ AWS CLI configured for account: $ACCOUNT_ID${NC}"
    echo ""
}

# Function to create ACM certificate
create_acm_certificate() {
    echo -e "${YELLOW}Creating ACM Certificate...${NC}"
    echo "Domain: $ACM_DOMAIN"
    
    # Check if certificate already exists
    EXISTING_CERT=$(aws acm list-certificates --region $AWS_REGION \
        --query "CertificateSummaryList[?DomainName=='$ACM_DOMAIN'].CertificateArn" \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$EXISTING_CERT" ]; then
        echo -e "${YELLOW}Certificate already exists: $EXISTING_CERT${NC}"
        CERT_ARN=$EXISTING_CERT
    else
        CERT_ARN=$(aws acm request-certificate \
            --domain-name "$ACM_DOMAIN" \
            --validation-method DNS \
            --region $AWS_REGION \
            --query CertificateArn \
            --output text)
        echo -e "${GREEN}✓ Certificate requested: $CERT_ARN${NC}"
        echo -e "${YELLOW}Note: You need to validate the certificate by adding the DNS records provided in ACM console${NC}"
    fi
    echo ""
}

# Function to create S3 bucket for Terraform state
create_terraform_backend_bucket() {
    echo -e "${YELLOW}Creating S3 bucket for Terraform backend...${NC}"
    echo "Bucket name: $TF_STATE_BUCKET"
    
    # Check if bucket exists
    if aws s3api head-bucket --bucket "$TF_STATE_BUCKET" 2>/dev/null; then
        echo -e "${YELLOW}Bucket already exists: $TF_STATE_BUCKET${NC}"
    else
        # Create bucket
        if [ "$AWS_REGION" = "us-east-1" ]; then
            aws s3api create-bucket --bucket "$TF_STATE_BUCKET" --region $AWS_REGION
        else
            aws s3api create-bucket --bucket "$TF_STATE_BUCKET" \
                --region $AWS_REGION \
                --create-bucket-configuration LocationConstraint=$AWS_REGION
        fi
        
        # Enable versioning
        aws s3api put-bucket-versioning \
            --bucket "$TF_STATE_BUCKET" \
            --versioning-configuration Status=Enabled
        
        # Enable encryption
        aws s3api put-bucket-encryption \
            --bucket "$TF_STATE_BUCKET" \
            --server-side-encryption-configuration '{
                "Rules": [
                    {
                        "ApplyServerSideEncryptionByDefault": {
                            "SSEAlgorithm": "AES256"
                        }
                    }
                ]
            }'
        
        # Block public access
        aws s3api put-public-access-block \
            --bucket "$TF_STATE_BUCKET" \
            --public-access-block-configuration \
                "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
        
        echo -e "${GREEN}✓ S3 bucket created and configured: $TF_STATE_BUCKET${NC}"
    fi
    echo ""
}

# Function to create DynamoDB table for Terraform state locking
create_terraform_lock_table() {
    echo -e "${YELLOW}Creating DynamoDB table for Terraform state locking...${NC}"
    echo "Table name: $TF_DYNAMODB_TABLE"
    
    # Check if table exists
    if aws dynamodb describe-table --table-name "$TF_DYNAMODB_TABLE" --region $AWS_REGION &>/dev/null; then
        echo -e "${YELLOW}DynamoDB table already exists: $TF_DYNAMODB_TABLE${NC}"
    else
        aws dynamodb create-table \
            --table-name "$TF_DYNAMODB_TABLE" \
            --attribute-definitions AttributeName=LockID,AttributeType=S \
            --key-schema AttributeName=LockID,KeyType=HASH \
            --billing-mode PAY_PER_REQUEST \
            --region $AWS_REGION
        
        # Wait for table to be active
        echo "Waiting for table to become active..."
        aws dynamodb wait table-exists --table-name "$TF_DYNAMODB_TABLE" --region $AWS_REGION
        
        echo -e "${GREEN}✓ DynamoDB table created: $TF_DYNAMODB_TABLE${NC}"
    fi
    echo ""
}

# Function to create GitHub Actions OIDC provider
create_github_oidc_provider() {
    echo -e "${YELLOW}Setting up GitHub Actions OIDC provider...${NC}"
    
    OIDC_PROVIDER_ARN="arn:aws:iam::$ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
    
    # Check if OIDC provider exists
    if aws iam get-open-id-connect-provider --open-id-connect-provider-arn "$OIDC_PROVIDER_ARN" &>/dev/null; then
        echo -e "${YELLOW}OIDC provider already exists${NC}"
    else
        # Get GitHub's thumbprint
        THUMBPRINT=$(openssl s_client -servername token.actions.githubusercontent.com \
            -showcerts -connect token.actions.githubusercontent.com:443 </dev/null 2>/dev/null \
            | openssl x509 -fingerprint -sha1 -noout \
            | cut -d'=' -f2 | tr -d ':' | tr '[:upper:]' '[:lower:]')
        
        # If thumbprint retrieval fails, use known GitHub thumbprint
        if [ -z "$THUMBPRINT" ]; then
            THUMBPRINT="6938fd4d98bab03faadb97b34396831e3780aea1"
        fi
        
        # Create OIDC provider
        aws iam create-open-id-connect-provider \
            --url "https://token.actions.githubusercontent.com" \
            --client-id-list "sts.amazonaws.com" \
            --thumbprint-list "$THUMBPRINT"
        
        echo -e "${GREEN}✓ GitHub Actions OIDC provider created${NC}"
    fi
    echo ""
}

# Function to create IAM role for GitHub Actions
create_github_actions_role() {
    echo -e "${YELLOW}Creating IAM role for GitHub Actions...${NC}"
    echo "Role name: $OIDC_ROLE_NAME"
    echo "GitHub organization: $GITHUB_ORG"
    
    # Create trust policy
    TRUST_POLICY=$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::$ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:$GITHUB_ORG/*:*"
                }
            }
        }
    ]
}
EOF
)
    
    # Check if role exists
    if aws iam get-role --role-name "$OIDC_ROLE_NAME" &>/dev/null; then
        echo -e "${YELLOW}Role already exists: $OIDC_ROLE_NAME${NC}"
        # Update trust policy
        aws iam update-assume-role-policy \
            --role-name "$OIDC_ROLE_NAME" \
            --policy-document "$TRUST_POLICY"
        echo "Trust policy updated"
    else
        # Create role
        aws iam create-role \
            --role-name "$OIDC_ROLE_NAME" \
            --assume-role-policy-document "$TRUST_POLICY" \
            --description "IAM role for GitHub Actions OIDC"
        echo -e "${GREEN}✓ IAM role created: $OIDC_ROLE_NAME${NC}"
    fi
    
    # Create and attach permissions policy
    PERMISSIONS_POLICY=$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:*",
                "ec2:*",
                "secretsmanager:*",
                "rds:*",
                "es:*",
                "kms:*",
                "logs:*",
                "s3:*",
                "dynamodb:*",
                "sts:GetCallerIdentity",
                "cloudwatch:*",
                "iam:*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
)
    
    POLICY_NAME="${OIDC_ROLE_NAME}Policy"
    
    # Check if policy exists and update/create accordingly
    POLICY_ARN="arn:aws:iam::$ACCOUNT_ID:policy/$POLICY_NAME"
    
    if aws iam get-policy --policy-arn "$POLICY_ARN" &>/dev/null; then
        echo "Updating existing policy..."
        # Create new policy version
        aws iam create-policy-version \
            --policy-arn "$POLICY_ARN" \
            --policy-document "$PERMISSIONS_POLICY" \
            --set-as-default
    else
        # Create policy
        aws iam create-policy \
            --policy-name "$POLICY_NAME" \
            --policy-document "$PERMISSIONS_POLICY" \
            --description "Permissions policy for GitHub Actions"
        echo -e "${GREEN}✓ IAM policy created: $POLICY_NAME${NC}"
    fi
    
    # Attach policy to role
    aws iam attach-role-policy \
        --role-name "$OIDC_ROLE_NAME" \
        --policy-arn "$POLICY_ARN"
    
    echo -e "${GREEN}✓ Policy attached to role${NC}"
    
    ROLE_ARN="arn:aws:iam::$ACCOUNT_ID:role/$OIDC_ROLE_NAME"
    echo ""
}

# Function to print summary
print_summary() {
    echo -e "${GREEN}=====================================${NC}"
    echo -e "${GREEN}Onboarding Complete!${NC}"
    echo -e "${GREEN}=====================================${NC}"
    echo ""
    echo "Summary of created resources:"
    echo "------------------------------"
    echo "AWS Account ID: $ACCOUNT_ID"
    echo "Region: $AWS_REGION"
    echo ""
    echo "ACM Certificate:"
    echo "  Domain: $ACM_DOMAIN"
    if [ -n "$CERT_ARN" ]; then
        echo "  ARN: $CERT_ARN"
    fi
    echo ""
    echo "Terraform Backend:"
    echo "  S3 Bucket: $TF_STATE_BUCKET"
    echo "  DynamoDB Table: $TF_DYNAMODB_TABLE"
    echo ""
    echo "GitHub Actions OIDC:"
    echo "  Provider ARN: arn:aws:iam::$ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
    echo "  Role Name: $OIDC_ROLE_NAME"
    echo "  Role ARN: arn:aws:iam::$ACCOUNT_ID:role/$OIDC_ROLE_NAME"
    echo ""
    echo -e "${YELLOW}Terraform Backend Configuration:${NC}"
    cat <<EOF

terraform {
  backend "s3" {
    bucket         = "$TF_STATE_BUCKET"
    key            = "terraform.tfstate"
    region         = "$AWS_REGION"
    dynamodb_table = "$TF_DYNAMODB_TABLE"
    encrypt        = true
  }
}
EOF
    echo ""
    echo -e "${YELLOW}GitHub Actions Workflow Configuration:${NC}"
    cat <<EOF

- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::$ACCOUNT_ID:role/$OIDC_ROLE_NAME
    aws-region: $AWS_REGION
EOF
    echo ""
}

# Main execution
main() {
    echo "Parameters:"
    echo "  ACM Domain: $ACM_DOMAIN"
    echo "  Terraform State Bucket: $TF_STATE_BUCKET"
    echo "  Terraform Lock Table: $TF_DYNAMODB_TABLE"
    echo "  GitHub Organization: $GITHUB_ORG"
    echo "  OIDC Role Name: $OIDC_ROLE_NAME"
    echo "  AWS Region: $AWS_REGION"
    echo ""
    echo "Press Enter to continue or Ctrl+C to cancel..."
    read
    
    check_aws_cli
    create_acm_certificate
    create_terraform_backend_bucket
    create_terraform_lock_table
    create_github_oidc_provider
    create_github_actions_role
    print_summary
}

# Show usage if --help is passed
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Usage: $0 [ACM_DOMAIN] [TF_STATE_BUCKET] [TF_DYNAMODB_TABLE] [GITHUB_ORG] [OIDC_ROLE_NAME]"
    echo ""
    echo "Parameters (all optional, defaults shown):"
    echo "  ACM_DOMAIN        - Domain for ACM certificate (default: *.internal.nvisionx.ai)"
    echo "  TF_STATE_BUCKET   - S3 bucket for Terraform state (default: nx-terraform-state-<timestamp>)"
    echo "  TF_DYNAMODB_TABLE - DynamoDB table for state locking (default: nx-terraform-locks)"
    echo "  GITHUB_ORG        - GitHub organization name (default: Nvision-x)"
    echo "  OIDC_ROLE_NAME    - IAM role name for GitHub Actions (default: NxGitHubActionsRole)"
    echo ""
    echo "Environment variables:"
    echo "  AWS_REGION        - AWS region to use (default: us-east-1)"
    exit 0
fi

# Run main function
main