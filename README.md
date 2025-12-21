# E-Commerce Sales Analytics Data Warehouse

A scalable, production-ready SQL-based data warehouse for storing and analyzing e-commerce sales, customer, and inventory data. Built on AWS with star schema design for optimal analytical query performance.

## 🎯 Project Overview

This project demonstrates enterprise-grade data warehousing practices for e-commerce platforms. It consolidates data from multiple sources (Sales, Customers, Inventory) into a centralized warehouse optimized for business intelligence and analytics.

### Key Features
- **Star Schema Design**: Optimized dimensional modeling for fast analytical queries
- **AWS Integration**: RDS PostgreSQL for scalable cloud-based storage
- **ETL Pipelines**: Python-based data extraction, transformation, and loading
- **Data Quality**: Comprehensive validation and cleaning procedures
- **SQL Analytics**: Pre-built queries for business insights
- **Documentation**: Complete setup and usage guides

## 📊 Architecture

```
Data Sources (CSV/APIs)
        ↓
    ETL Pipeline
        ↓
Staging Database (Raw Data)
        ↓
Data Transformation Layer
        ↓
Data Warehouse (Star Schema)
        ├── Fact Tables
        │   ├── fact_sales
        │   └── fact_inventory_movement
        └── Dimension Tables
            ├── dim_customers
            ├── dim_products
            ├── dim_date
            ├── dim_geography
            └── dim_salesperson
```

## 📁 Project Structure

```
e-commerce-dw/
├── README.md                          # Project overview
├── docs/
│   ├── SETUP_GUIDE.md                # AWS RDS & PostgreSQL setup
│   ├── DATA_DICTIONARY.md            # Schema documentation
│   ├── ARCHITECTURE.md               # System design & architecture
│   └── QUERIES_GUIDE.md              # Sample analytics queries
├── sql/
│   ├── schema/
│   │   ├── 01_staging_schema.sql     # Staging layer tables
│   │   ├── 02_warehouse_schema.sql   # Star schema tables
│   │   └── 03_indexes.sql            # Performance indexes
│   ├── etl/
│   │   ├── 01_load_raw_data.sql      # Raw data loading
│   │   ├── 02_data_cleaning.sql      # Data quality checks
│   │   └── 03_load_warehouse.sql     # Populate star schema
│   └── analytics/
│       ├── sales_analysis.sql        # Sales insights
│       ├── customer_analysis.sql     # Customer behavior
│       ├── inventory_analysis.sql    # Inventory metrics
│       └── product_performance.sql   # Product insights
├── python/
│   ├── requirements.txt               # Python dependencies
│   ├── config.py                     # Configuration settings
│   ├── etl_pipeline.py               # Main ETL orchestration
│   ├── data_loader.py                # Database operations
│   └── data_validator.py             # Quality checks
├── data/
│   ├── sample_data/
│   │   ├── customers.csv
│   │   ├── products.csv
│   │   ├── sales.csv
│   │   └── inventory.csv
│   └── README.md                     # Data format documentation
├── tests/
│   ├── test_etl.py                  # ETL pipeline tests
│   └── test_data_quality.py         # Quality validation tests
├── scripts/
│   ├── setup_aws_rds.sh             # AWS RDS provisioning
│   └── run_pipeline.sh              # Pipeline execution script
└── .gitignore                        # Git ignore rules
```

## 🚀 Quick Start

### Prerequisites
- AWS Account with RDS access
- PostgreSQL 13+
- Python 3.8+
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/e-commerce-dw.git
   cd e-commerce-dw
   ```

2. **Set up AWS RDS PostgreSQL**
   ```bash
   bash scripts/setup_aws_rds.sh
   ```

3. **Install Python dependencies**
   ```bash
   pip install -r python/requirements.txt
   ```

4. **Configure database connection**
   ```bash
   cp python/config.py.example python/config.py
   # Edit python/config.py with your AWS RDS credentials
   ```

5. **Load sample data and build warehouse**
   ```bash
   bash scripts/run_pipeline.sh
   ```

## 📊 Data Model

### Fact Tables

**fact_sales**: Core transactional data
- sale_id (PK)
- customer_id (FK)
- product_id (FK)
- salesperson_id (FK)
- date_id (FK)
- geography_id (FK)
- quantity, unit_price, discount, total_amount, profit

**fact_inventory_movement**: Inventory transactions
- movement_id (PK)
- product_id (FK)
- warehouse_id
- date_id (FK)
- quantity_in, quantity_out, quantity_on_hand

### Dimension Tables

**dim_customers**: Customer master data
- customer_id (PK)
- customer_name, email, phone
- city, state, country, postal_code
- customer_segment, registration_date

**dim_products**: Product catalog
- product_id (PK)
- product_name, sku
- category, subcategory, brand
- unit_cost, list_price
- active_status

**dim_date**: Time dimension
- date_id (PK)
- date, year, quarter, month, week, day_of_week
- is_weekend, is_holiday

**dim_geography**: Location master
- geography_id (PK)
- city, state, country, region, postal_code
- latitude, longitude

**dim_salesperson**: Sales team
- salesperson_id (PK)
- salesperson_name, email
- department, region, manager_id

## 🔧 Technologies

| Component | Technology |
|-----------|-----------|
| **Database** | PostgreSQL 13+ on AWS RDS |
| **Data Modeling** | Star Schema (Kimball) |
| **ETL** | Python with psycopg2 |
| **Data Quality** | Great Expectations |
| **Version Control** | Git |
| **Documentation** | Markdown |

## 📈 Analytics Capabilities

### Available Reports

1. **Sales Analysis**
   - Revenue trends by time period
   - Top products and customers
   - Sales by geography and salesperson
   - Year-over-year growth metrics

2. **Customer Analytics**
   - Customer segmentation
   - Purchase frequency and value
   - Customer lifetime value
   - Churn analysis

3. **Inventory Management**
   - Stock levels by warehouse
   - Movement velocity
   - Reorder point analysis
   - Turnover metrics

4. **Product Performance**
   - Sales volume by product
   - Profit margin analysis
   - Product affinity (co-purchases)
   - Seasonal trends

## 📚 Documentation

- **[SETUP_GUIDE.md](docs/SETUP_GUIDE.md)**: Complete AWS RDS setup and PostgreSQL configuration
- **[DATA_DICTIONARY.md](docs/DATA_DICTIONARY.md)**: Detailed schema and table documentation
- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)**: System design, scalability, and best practices
- **[QUERIES_GUIDE.md](docs/QUERIES_GUIDE.md)**: Sample analytics queries and use cases

## 🔒 Security Best Practices

- ✅ AWS RDS encryption at rest and in transit
- ✅ VPC isolation for database access
- ✅ IAM role-based access control
- ✅ Parameterized queries to prevent SQL injection
- ✅ Secure credential management via environment variables
- ✅ Regular backups and point-in-time recovery

## 📊 Performance Optimization

- Star schema reduces join complexity
- Proper indexing on foreign keys and filter columns
- Partitioning strategy for large fact tables
- Query optimization using EXPLAIN ANALYZE
- Connection pooling for efficient resource utilization

## 🧪 Testing

Run the test suite:
```bash
pytest tests/ -v
```

Tests include:
- ETL pipeline validation
- Data quality checks
- Schema integrity tests
- Query performance benchmarks

## 📝 SQL Queries Examples

### Top 10 Customers by Revenue
```sql
SELECT 
    c.customer_id,
    c.customer_name,
    SUM(fs.total_amount) as total_revenue,
    COUNT(DISTINCT fs.sale_id) as number_of_orders
FROM fact_sales fs
JOIN dim_customers c ON fs.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_revenue DESC
LIMIT 10;
```

### Monthly Sales Trend
```sql
SELECT 
    CONCAT(dd.year, '-', LPAD(dd.month::text, 2, '0')) as year_month,
    SUM(fs.total_amount) as total_sales,
    SUM(fs.profit) as total_profit,
    COUNT(DISTINCT fs.sale_id) as number_of_orders
FROM fact_sales fs
JOIN dim_date dd ON fs.date_id = dd.date_id
GROUP BY dd.year, dd.month
ORDER BY dd.year, dd.month;
```

More examples in [docs/QUERIES_GUIDE.md](docs/QUERIES_GUIDE.md)

## 🤝 Contributing

Contributions are welcome! Please follow these steps:
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see LICENSE file for details.

## 👨‍💼 Author

**Samarth Maske**
- GitHub: [github.com/Samarthmaske](https://github.com/Samarthmaske)
- LinkedIn: [linkedin.com/in/samarth-maske-86a904340](https://linkedin.com/in/samarth-maske-86a904340)

## 🙏 Acknowledgments

- Star schema design based on Ralph Kimball's data warehouse principles
- AWS RDS best practices documentation
- PostgreSQL community resources

## 📞 Support

For issues, questions, or suggestions:
1. Open a GitHub Issue
2. Check existing documentation
3. Review sample queries in the analytics folder

---

**Last Updated**: December 2025
**Status**: Production Ready ✅
