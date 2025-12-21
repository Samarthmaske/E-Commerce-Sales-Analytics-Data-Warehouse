#!/bin/bash
# E-Commerce Data Warehouse: Run ETL Pipeline
# Main execution script for the ETL pipeline
# Author: Samarth Maske

set -e

echo "======================================================"
echo "E-Commerce Data Warehouse: ETL Pipeline Execution"
echo "======================================================"

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "Python 3 is not installed. Please install Python 3.8 or higher."
    exit 1
fi

# Check if .env file exists
if [ ! -f .env ]; then
    echo "Error: .env file not found!"
    echo "Please run setup_aws_rds.sh first or create .env with database credentials"
    exit 1
fi

# Load environment variables
export $(cat .env | xargs)

# Create necessary directories
mkdir -p logs backups data/sample_data

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Install/update dependencies
echo "Installing dependencies..."
pip install -q --upgrade pip
pip install -q -r requirements.txt

# Run ETL Pipeline
echo ""
echo "======================================================"
echo "Starting ETL Pipeline..."
echo "======================================================"
echo ""

python3 python/etl_pipeline.py

# Capture exit status
ETL_STATUS=$?

if [ $ETL_STATUS -eq 0 ]; then
    echo ""
    echo "======================================================"
    echo "✓ ETL Pipeline completed successfully!"
    echo "======================================================"
    echo ""
    echo "Data warehouse is now ready for analytics."
    echo "You can now run queries from the sql/analytics folder."
else
    echo ""
    echo "======================================================"
    echo "✗ ETL Pipeline failed with exit code $ETL_STATUS"
    echo "======================================================"
    echo "Check logs/etl_pipeline.log for details."
    exit 1
fi

# Optional: Run quality checks
read -p "Do you want to run additional quality checks? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Running data quality checks..."
    python3 -m pytest tests/ -v
fi

echo "======================================================"
echo "Setup complete!"
echo "======================================================"
