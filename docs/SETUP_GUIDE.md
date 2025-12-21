# SETUP GUIDE - E-Commerce Data Warehouse on AWS RDS

## Prerequisites

Before starting, ensure you have:

1. **AWS Account** with appropriate IAM permissions
2. **AWS CLI** installed and configured
3. **Python 3.8+** installed
4. **PostgreSQL 13+** (for local development)
5. **Git** for version control

### Verify Prerequisites

```bash
# Check Python
python3 --version

# Check AWS CLI
aws --version

# Check Git
git --version
```

---

## Part 1: AWS RDS Setup

### Step 1: Configure AWS Credentials

```bash
# Configure AWS CLI with your credentials
aws configure

# Enter:
# AWS Access Key ID
# AWS Secret Access Key
# Default region (e.g., us-east-1)
# Default output format (e.g., json)
```

### Step 2: Run RDS Setup Script

```bash
# Make script executable
chmod +x scripts/setup_aws_rds.sh

# Run the setup script
./scripts/setup_aws_rds.sh
```

This script will:
- Create a security group for PostgreSQL access
- Provision an RDS PostgreSQL instance (db.t3.micro)
- Generate secure credentials
- Create a `.env` configuration file

### Step 3: Verify RDS Connection

```bash
# Test connection (requires psql installed)
psql -h <your-rds-endpoint> -U postgres -d ecommerce_dw

# Or use Python
python3 -c "
import psycopg2
from python.config import DB_CONFIG
conn = psycopg2.connect(**DB_CONFIG)
print('✓ Database connection successful!')
conn.close()
"
```

---

## Part 2: Local Environment Setup

### Step 1: Clone Repository

```bash
git clone https://github.com/Samarthmaske/e-commerce-dw.git
cd e-commerce-dw
```

### Step 2: Create Python Virtual Environment

```bash
# Create virtual environment
python3 -m venv venv

# Activate virtual environment
# On macOS/Linux:
source venv/bin/activate

# On Windows:
venv\Scripts\activate
```

### Step 3: Install Dependencies

```bash
# Upgrade pip
pip install --upgrade pip

# Install project dependencies
pip install -r requirements.txt
```

### Step 4: Configure Environment Variables

```bash
# Copy example env file
cp python/config.py.example python/config.py

# Edit with your AWS RDS credentials
# Update these values:
# - DB_HOST: Your RDS endpoint
# - DB_USER: Database username
# - DB_PASSWORD: Database password
# - DB_NAME: Database name
# - AWS_REGION: Your AWS region
```

Alternatively, if using .env file:

```bash
cat > .env << 'EOF'
DB_HOST=your-rds-endpoint.rds.amazonaws.com
DB_PORT=5432
DB_NAME=ecommerce_dw
DB_USER=postgres
DB_PASSWORD=your_secure_password
AWS_REGION=us-east-1
EOF
```

---

## Part 3: ETL Pipeline Execution

### Option A: Automated Execution (Recommended)

```bash
# Make script executable
chmod +x scripts/run_pipeline.sh

# Run the complete pipeline
./scripts/run_pipeline.sh
```

### Option B: Manual Step-by-Step Execution

```bash
# Step 1: Create staging schema
psql -h $DB_HOST -U postgres -d ecommerce_dw -f sql/schema/01_staging_schema.sql

# Step 2: Run ETL pipeline
python3 python/etl_pipeline.py

# Step 3: Verify warehouse
python3 << 'EOF'
from python.etl_pipeline import ETLPipeline
pipeline = ETLPipeline()
pipeline.connect_database()
pipeline.cursor.execute("SELECT COUNT(*) FROM warehouse.fact_sales")
print(f"Sales Records: {pipeline.cursor.fetchone()[0]}")
EOF
```

### Step 4: Verify Data Load

```sql
-- Connect to database
psql -h $DB_HOST -U postgres -d ecommerce_dw

-- Check row counts
SELECT 'fact_sales' as table_name, COUNT(*) as row_count FROM warehouse.fact_sales
UNION ALL
SELECT 'dim_customers', COUNT(*) FROM warehouse.dim_customers
UNION ALL
SELECT 'dim_products', COUNT(*) FROM warehouse.dim_products
UNION ALL
SELECT 'dim_date', COUNT(*) FROM warehouse.dim_date;
```

---

## Part 4: Performance Optimization

### Create Indexes

```bash
psql -h $DB_HOST -U postgres -d ecommerce_dw -f sql/schema/03_indexes.sql
```

### Enable Query Optimization

```sql
-- Check slow queries
SELECT * FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;

-- Analyze table statistics
ANALYZE warehouse.fact_sales;
ANALYZE warehouse.dim_customers;
```

### Configure RDS Parameters

In AWS Console:
1. Go to RDS > Databases > Your Instance
2. Click "Parameter Groups"
3. Edit parameters:
   - `shared_buffers`: 25% of available RAM
   - `effective_cache_size`: 75% of available RAM
   - `work_mem`: 10-20 MB per connection
   - `max_connections`: 100-200

---

## Part 5: Data Quality Validation

### Run Quality Checks

```bash
# Install test dependencies
pip install pytest pytest-cov

# Run all tests
pytest tests/ -v

# Run with coverage
pytest tests/ --cov=python --cov-report=html
```

### Manual Quality Checks

```sql
-- Check for NULL values in key columns
SELECT COUNT(*) FROM warehouse.fact_sales 
WHERE customer_id IS NULL 
OR product_id IS NULL 
OR sale_id IS NULL;

-- Verify referential integrity
SELECT COUNT(*) FROM warehouse.fact_sales fs
WHERE NOT EXISTS (SELECT 1 FROM warehouse.dim_customers c WHERE c.customer_id = fs.customer_id);

-- Check data completeness
SELECT 
    'fact_sales' as table_name,
    COUNT(*) as total_rows,
    COUNT(customer_id) as non_null_customers,
    ROUND(COUNT(customer_id)::numeric / COUNT(*) * 100, 2) as completeness_percent
FROM warehouse.fact_sales;
```

---

## Part 6: Monitoring and Maintenance

### Set Up Automated Backups

```bash
# AWS RDS handles daily backups automatically
# Configure backup retention in AWS Console:
# RDS > Databases > Your Instance > Modify
# Backup Retention Period: 7-30 days
```

### Monitor Database Performance

```bash
# Check slow query log
psql -h $DB_HOST -U postgres -d ecommerce_dw -c "
SELECT query, calls, mean_time 
FROM pg_stat_statements 
ORDER BY mean_time DESC 
LIMIT 10;"
```

### Regular Maintenance Tasks

```sql
-- Weekly: Analyze tables
ANALYZE;

-- Monthly: Vacuum tables
VACUUM ANALYZE;

-- Quarterly: Check index usage
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
ORDER BY idx_scan ASC;
```

---

## Part 7: Troubleshooting

### Issue: Connection Timeout

**Solution:**
```bash
# 1. Verify security group allows port 5432
aws ec2 describe-security-groups --group-ids $SECURITY_GROUP

# 2. Test with increased timeout
psql -h $DB_HOST -U postgres --connect-timeout=30 -d ecommerce_dw

# 3. Check RDS instance status
aws rds describe-db-instances --db-instance-identifier ecommerce-dw-postgres
```

### Issue: Out of Disk Space

**Solution:**
```bash
# Check current storage
aws rds describe-db-instances --db-instance-identifier ecommerce-dw-postgres \
    --query 'DBInstances[0].AllocatedStorage'

# Increase storage (in AWS Console or CLI)
aws rds modify-db-instance \
    --db-instance-identifier ecommerce-dw-postgres \
    --allocated-storage 100 \
    --apply-immediately
```

### Issue: Slow Queries

**Solution:**
```bash
# 1. Enable query logging
# In parameter group: log_min_duration_statement = 1000

# 2. Analyze query plan
EXPLAIN ANALYZE SELECT * FROM warehouse.fact_sales LIMIT 1000;

# 3. Check missing indexes
SELECT * FROM pg_stat_user_tables WHERE schemaname = 'warehouse'
ORDER BY seq_scan DESC;
```

---

## Part 8: Scaling and Cost Optimization

### Vertical Scaling (Upgrade Instance)

```bash
aws rds modify-db-instance \
    --db-instance-identifier ecommerce-dw-postgres \
    --db-instance-class db.t3.small \
    --apply-immediately
```

### Enable CloudWatch Monitoring

```bash
# Already enabled by setup script
# Monitor in AWS Console:
# CloudWatch > RDS > DB Instances > Your Instance
```

### Cost Optimization Tips

1. **Use Reserved Instances** for production (40-60% savings)
2. **Enable Automated Minor Backups**
3. **Schedule Non-Production Instance Shutdown**
4. **Partition Large Tables** by time period
5. **Archive Old Data** to S3

---

## Part 9: Production Deployment Checklist

- [ ] Security group configured with least privilege
- [ ] Database encryption enabled (at-rest and in-transit)
- [ ] Automated backups configured (7-30 days retention)
- [ ] CloudWatch alarms set up
- [ ] Database parameter tuning completed
- [ ] Performance baselines established
- [ ] Disaster recovery plan documented
- [ ] Access control and IAM roles configured
- [ ] VPC endpoint configured (if in VPC)
- [ ] SSL/TLS connections enforced

---

## Additional Resources

- [AWS RDS PostgreSQL Documentation](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html)
- [PostgreSQL Official Documentation](https://www.postgresql.org/docs/)
- [Data Warehouse Design Best Practices](https://docs.aws.amazon.com/redshift/latest/dg/best-practices.html)

## Support

For issues or questions:
1. Check logs in `logs/etl_pipeline.log`
2. Review this guide thoroughly
3. Open a GitHub issue with detailed error information
4. Contact: samarth.maske@example.com

---

**Last Updated**: December 2025
**Status**: Production Ready ✅
