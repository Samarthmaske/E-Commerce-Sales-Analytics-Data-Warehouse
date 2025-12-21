#!/bin/bash
# E-Commerce Data Warehouse: AWS RDS Setup Script
# This script sets up AWS RDS PostgreSQL instance
# Author: Samarth Maske

set -e

echo "======================================================"
echo "E-Commerce Data Warehouse AWS RDS Setup"
echo "======================================================"

# Configuration
AWS_REGION=${AWS_REGION:-us-east-1}
DB_INSTANCE_ID=${DB_INSTANCE_ID:-ecommerce-dw-postgres}
DB_CLASS=${DB_CLASS:-db.t3.micro}
DB_NAME=${DB_NAME:-ecommerce_dw}
DB_USER=${DB_USER:-postgres}
DB_ALLOCATED_STORAGE=${DB_ALLOCATED_STORAGE:-20}
SECURITY_GROUP=${SECURITY_GROUP:-ecommerce-dw-sg}
VPC_ID=${VPC_ID:-vpc-default}

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check AWS CLI installation
if ! command -v aws &> /dev/null; then
    echo -e "${RED}AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Generate random password
generate_password() {
    openssl rand -base64 12
}

echo -e "${YELLOW}Step 1: Creating Security Group...${NC}"

# Create security group if it doesn't exist
if aws ec2 describe-security-groups \
    --region $AWS_REGION \
    --filters "Name=group-name,Values=$SECURITY_GROUP" \
    --query 'SecurityGroups[0].GroupId' \
    --output text 2>/dev/null | grep -q "sg-"; then
    echo "Security Group already exists"
    SG_ID=$(aws ec2 describe-security-groups \
        --region $AWS_REGION \
        --filters "Name=group-name,Values=$SECURITY_GROUP" \
        --query 'SecurityGroups[0].GroupId' \
        --output text)
else
    echo "Creating new security group..."
    SG_ID=$(aws ec2 create-security-group \
        --group-name $SECURITY_GROUP \
        --description "Security group for E-Commerce DW PostgreSQL" \
        --vpc-id $VPC_ID \
        --region $AWS_REGION \
        --query 'GroupId' \
        --output text)
    
    # Allow PostgreSQL traffic
    aws ec2 authorize-security-group-ingress \
        --group-id $SG_ID \
        --protocol tcp \
        --port 5432 \
        --cidr 0.0.0.0/0 \
        --region $AWS_REGION
fi

echo -e "${GREEN}Security Group ID: $SG_ID${NC}"

echo -e "${YELLOW}Step 2: Creating RDS PostgreSQL Instance...${NC}"

# Generate password
DB_PASSWORD=$(generate_password)

# Create RDS instance
aws rds create-db-instance \
    --db-instance-identifier $DB_INSTANCE_ID \
    --db-instance-class $DB_CLASS \
    --engine postgres \
    --engine-version 15.4 \
    --master-username $DB_USER \
    --master-user-password "$DB_PASSWORD" \
    --allocated-storage $DB_ALLOCATED_STORAGE \
    --db-name $DB_NAME \
    --vpc-security-group-ids $SG_ID \
    --publicly-accessible \
    --backup-retention-period 7 \
    --preferred-backup-window "03:00-04:00" \
    --preferred-maintenance-window "sun:04:00-sun:05:00" \
    --enable-cloudwatch-logs-exports postgresql \
    --storage-encrypted \
    --region $AWS_REGION 2>/dev/null || echo "Instance may already exist"

echo -e "${GREEN}RDS Instance Creation Initiated${NC}"

echo -e "${YELLOW}Step 3: Waiting for RDS Instance to be Available...${NC}"

# Wait for instance to be available (max 30 minutes)
aws rds wait db-instance-available \
    --db-instance-identifier $DB_INSTANCE_ID \
    --region $AWS_REGION

echo -e "${GREEN}RDS Instance is now available!${NC}"

echo -e "${YELLOW}Step 4: Retrieving Connection Details...${NC}"

# Get instance details
DB_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier $DB_INSTANCE_ID \
    --region $AWS_REGION \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)

DB_PORT=$(aws rds describe-db-instances \
    --db-instance-identifier $DB_INSTANCE_ID \
    --region $AWS_REGION \
    --query 'DBInstances[0].Endpoint.Port' \
    --output text)

echo -e "${YELLOW}Step 5: Creating .env Configuration File...${NC}"

# Create .env file
cat > .env << EOF
# AWS RDS Configuration
DB_HOST=$DB_ENDPOINT
DB_PORT=$DB_PORT
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
AWS_REGION=$AWS_REGION

# AWS Settings
S3_BUCKET_NAME=ecommerce-dw-data-$(date +%s)
KMS_KEY_ID=

# Database Connection
DB_POOL_SIZE=5
DB_MAX_OVERFLOW=10
EOF

echo -e "${GREEN}.env file created${NC}"

# Create example env file
cp .env .env.example

echo ""
echo "======================================================"
echo -e "${GREEN}SETUP COMPLETED SUCCESSFULLY!${NC}"
echo "======================================================"
echo ""
echo "Connection Details:"
echo "-----------------"
echo "Host: $DB_ENDPOINT"
echo "Port: $DB_PORT"
echo "Database: $DB_NAME"
echo "Username: $DB_USER"
echo "Password: (saved in .env file)"
echo ""
echo "Connection String:"
echo "postgresql://$DB_USER:****@$DB_ENDPOINT:$DB_PORT/$DB_NAME"
echo ""
echo "Next Steps:"
echo "1. Review .env file with credentials"
echo "2. Run: pip install -r requirements.txt"
echo "3. Run: python etl_pipeline.py"
echo "======================================================"
