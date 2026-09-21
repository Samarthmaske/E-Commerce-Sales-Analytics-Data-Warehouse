"""
E-Commerce Data Warehouse: Configuration Module
Database connection and environment settings
Author: Samarth Maske
"""

import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# AWS RDS Configuration
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'your-rds-endpoint.rds.amazonaws.com'),
    'port': int(os.getenv('DB_PORT', 3306)),
    'database': os.getenv('DB_NAME', 'ecommerce_dw'),
    'user': os.getenv('DB_USER', 'mysql_user'),
    'password': os.getenv('DB_PASSWORD', 'your_password'),
    'connect_timeout': 10,
    'ssl_verify_cert': True,
    'ssl_verify_identity': True
}

# Data Files Configuration
DATA_PATHS = {
    'customers': 'data/sample_data/customers.csv',
    'products': 'data/sample_data/products.csv',
    'sales': 'data/sample_data/sales.csv',
    'inventory': 'data/sample_data/inventory.csv',
    'salesperson': 'data/sample_data/salesperson.csv'
}

# ETL Configuration
ETL_CONFIG = {
    'batch_size': 1000,
    'log_level': 'INFO',
    'enable_data_quality_checks': True,
    'enable_backup': True,
    'backup_path': 'backups/'
}

# Data Quality Thresholds
DATA_QUALITY = {
    'null_threshold': 0.05,  # 5% null threshold
    'duplicate_threshold': 0.01,  # 1% duplicate threshold
    'outlier_std_dev': 3  # Standard deviations for outlier detection
}

# Logging Configuration
LOG_CONFIG = {
    'log_file': 'logs/etl_pipeline.log',
    'log_format': '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    'log_level': 'INFO'
}

# Date Range for Historical Data
DATA_RANGE = {
    'start_date': '2020-01-01',
    'end_date': '2025-12-31'
}

# AWS Configuration
AWS_CONFIG = {
    'region': os.getenv('AWS_REGION', 'us-east-1'),
    's3_bucket': os.getenv('S3_BUCKET_NAME', 'ecommerce-dw-data'),
    'kms_key_id': os.getenv('KMS_KEY_ID', None)
}

# Retry Configuration
RETRY_CONFIG = {
    'max_retries': 3,
    'retry_delay': 5,  # seconds
    'backoff_factor': 2
}

def get_db_connection_string():
    """Generate MySQL connection string"""
    return (
        f"mysql+pymysql://{DB_CONFIG['user']}:{DB_CONFIG['password']}"
        f"@{DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['database']}"
    )

def validate_config():
    """Validate configuration settings"""
    required_keys = ['host', 'database', 'user', 'password']
    for key in required_keys:
        if not DB_CONFIG.get(key):
            raise ValueError(f"Missing required configuration: {key}")
    return True

if __name__ == '__main__':
    # Test configuration
    try:
        validate_config()
        print("Configuration validation successful!")
        print(f"Database: {DB_CONFIG['database']}")
        print(f"Host: {DB_CONFIG['host']}")
    except ValueError as e:
        print(f"Configuration error: {e}")
