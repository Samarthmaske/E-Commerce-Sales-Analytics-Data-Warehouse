# DATA DICTIONARY - E-Commerce Data Warehouse

## Overview

This document provides comprehensive documentation for all tables, columns, and their meanings in the E-Commerce Data Warehouse.

---

## FACT TABLES

### fact_sales
**Description**: Core transactional table containing all sales records
**Grain**: One row per sales transaction
**Row Count**: ~500,000+ records (example data)

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| sale_id | INT | NO | Unique sales transaction identifier (PK) |
| customer_id | INT | NO | Reference to customer (FK) |
| product_id | INT | NO | Reference to product (FK) |
| salesperson_id | INT | YES | Reference to salesperson (FK) |
| date_id | INT | NO | Reference to date dimension (FK) |
| geography_id | INT | NO | Reference to geography dimension (FK) |
| quantity | INT | NO | Number of units sold (1+) |
| unit_price | DECIMAL(10,2) | NO | Price per unit at sale time |
| discount_amount | DECIMAL(10,2) | YES | Absolute discount in currency |
| discount_percent | DECIMAL(5,2) | YES | Discount percentage (0-100) |
| subtotal | DECIMAL(12,2) | NO | quantity × unit_price |
| tax_amount | DECIMAL(10,2) | YES | Applicable taxes |
| total_amount | DECIMAL(12,2) | NO | Final amount including tax |
| cogs | DECIMAL(12,2) | NO | Cost of goods sold |
| profit | DECIMAL(12,2) | NO | total_amount - cogs |
| delivery_date | DATE | YES | Actual delivery date |
| delivery_days | INT | YES | Days to deliver |
| is_returned | BOOLEAN | YES | Whether order was returned |
| created_date | TIMESTAMP | NO | Record creation timestamp |

**Indexes**: customer_id, product_id, date_id, total_amount, profit, created_date

**Example Queries**:
```sql
-- Monthly sales
SELECT DATE_TRUNC('month', dd.date), SUM(total_amount)
FROM fact_sales JOIN dim_date dd ON date_id = dd.date_id
GROUP BY DATE_TRUNC('month', dd.date);

-- Top customers
SELECT customer_id, SUM(total_amount) as revenue
FROM fact_sales
GROUP BY customer_id
ORDER BY revenue DESC LIMIT 10;
```

---

### fact_inventory_movement
**Description**: Inventory transactions and stock levels by warehouse and date
**Grain**: One row per product per warehouse per day
**Row Count**: ~100,000+ records (example data)

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| movement_id | SERIAL | NO | Unique movement identifier (PK) |
| product_id | INT | NO | Reference to product (FK) |
| warehouse_id | VARCHAR(20) | NO | Warehouse location code |
| date_id | INT | NO | Reference to date dimension (FK) |
| quantity_in | INT | YES | Units received (0+) |
| quantity_out | INT | YES | Units sold/shipped (0+) |
| quantity_on_hand | INT | NO | Current stock level |
| quantity_reserved | INT | YES | Units reserved for orders |
| quantity_available | INT | YES | Available for sale (on_hand - reserved) |
| reorder_point | INT | YES | Minimum stock threshold |
| unit_cost | DECIMAL(10,2) | YES | Cost per unit |
| inventory_value | DECIMAL(15,2) | YES | quantity_on_hand × unit_cost |
| created_date | TIMESTAMP | NO | Record creation timestamp |

**Indexes**: product_id, warehouse_id, date_id

---

## DIMENSION TABLES

### dim_customers
**Description**: Customer master data with demographics
**Type**: Slowly Changing Dimension (Type 2 optional)
**Row Count**: ~10,000 records (example data)

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| customer_id | INT | NO | Unique customer identifier (PK) |
| customer_name | VARCHAR(255) | NO | Full customer name |
| email | VARCHAR(255) | YES | Primary email address |
| phone | VARCHAR(20) | YES | Contact phone number |
| city | VARCHAR(100) | YES | City of residence |
| state | VARCHAR(100) | YES | State/Province |
| country | VARCHAR(100) | YES | Country code or name |
| postal_code | VARCHAR(20) | YES | Postal/ZIP code |
| customer_segment | VARCHAR(50) | YES | Segment: 'Premium', 'Standard', 'Basic' |
| registration_date | DATE | YES | Date customer registered |
| is_active | BOOLEAN | YES | Current status (TRUE/FALSE) |
| last_purchase_date | DATE | YES | Most recent transaction date |
| created_date | TIMESTAMP | NO | Record creation timestamp |
| updated_date | TIMESTAMP | NO | Last update timestamp |

**Indexes**: email, city, country, customer_segment

**Sample Values**:
- customer_segment: 'Premium', 'Standard', 'Basic'
- is_active: TRUE, FALSE

---

### dim_products
**Description**: Product catalog and attributes
**Type**: Slowly Changing Dimension (Type 1 - overwrite)
**Row Count**: ~1,500 records (example data)

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| product_id | INT | NO | Unique product identifier (PK) |
| product_name | VARCHAR(255) | NO | Full product name/description |
| sku | VARCHAR(50) | YES | Stock keeping unit (unique) |
| category | VARCHAR(100) | YES | Product category (e.g., 'Electronics') |
| subcategory | VARCHAR(100) | YES | Subcategory (e.g., 'Laptops') |
| brand | VARCHAR(100) | YES | Manufacturer/brand |
| unit_cost | DECIMAL(10,2) | YES | Manufacturing/acquisition cost |
| list_price | DECIMAL(10,2) | YES | Standard retail price |
| margin_percent | DECIMAL(5,2) | YES | (list_price - unit_cost) / list_price × 100 |
| is_active | BOOLEAN | YES | Currently available for sale |
| created_date | DATE | YES | Date product added to catalog |
| discontinue_date | DATE | YES | Date product discontinued (NULL if active) |
| warehouse_created_date | TIMESTAMP | NO | DW record creation timestamp |

**Indexes**: category, brand, sku

**Sample Categories**: Electronics, Apparel, Furniture, Books, Sports

---

### dim_date
**Description**: Time dimension for date-based analysis
**Grain**: One row per calendar day
**Row Count**: ~1,000+ records (3+ years of data)

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| date_id | SERIAL | NO | Unique date identifier (PK) |
| date | DATE | NO | Calendar date (YYYY-MM-DD) |
| year | INT | YES | Calendar year |
| quarter | INT | YES | Quarter (1-4) |
| month | INT | YES | Month number (1-12) |
| week | INT | YES | Week number (1-53) |
| day_of_week | INT | YES | Day of week (0=Sunday, 6=Saturday) |
| day_name | VARCHAR(20) | YES | 'Monday', 'Tuesday', etc. |
| is_weekend | BOOLEAN | YES | TRUE for Saturday/Sunday |
| is_holiday | BOOLEAN | YES | TRUE for public holidays |
| holiday_name | VARCHAR(100) | YES | Holiday name if applicable |
| created_date | TIMESTAMP | NO | Record creation timestamp |

**Indexes**: date, year, month

**Example Data**:
- January 1, 2023 → day_of_week=0, is_weekend=FALSE, is_holiday=TRUE, holiday_name='New Year'

---

### dim_geography
**Description**: Geographic location master data
**Row Count**: ~500 records (example data)

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| geography_id | SERIAL | NO | Unique geography identifier (PK) |
| city | VARCHAR(100) | YES | City name |
| state | VARCHAR(100) | YES | State/Province |
| country | VARCHAR(100) | YES | Country |
| region | VARCHAR(100) | YES | Geographic region (e.g., 'North America') |
| postal_code | VARCHAR(20) | YES | Postal/ZIP code |
| latitude | DECIMAL(10,8) | YES | Geographic latitude |
| longitude | DECIMAL(11,8) | YES | Geographic longitude |
| population | INT | YES | City population (optional) |
| created_date | TIMESTAMP | NO | Record creation timestamp |

**Indexes**: country, state

---

### dim_salesperson
**Description**: Sales team organizational structure
**Row Count**: ~100 records (example data)

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| salesperson_id | INT | NO | Unique salesperson identifier (PK) |
| salesperson_name | VARCHAR(255) | NO | Full name |
| email | VARCHAR(255) | YES | Business email |
| phone | VARCHAR(20) | YES | Business phone |
| department | VARCHAR(100) | YES | Department (e.g., 'Sales', 'Support') |
| region | VARCHAR(100) | YES | Geographic region assigned |
| manager_id | INT | YES | Supervisor's salesperson_id |
| hire_date | DATE | YES | Employment start date |
| is_active | BOOLEAN | YES | Currently employed |
| created_date | TIMESTAMP | NO | Record creation timestamp |

---

## STAGING TABLES

### stg_customers, stg_products, stg_sales, stg_inventory, stg_salesperson

**Purpose**: Temporary tables for raw data loading
**Retention**: Overwritten on each ETL run
**Used By**: ETL pipeline for transformation logic

---

## MATERIALIZED VIEWS

### mv_daily_sales_by_product
Pre-aggregated daily sales by product for fast reporting

```sql
SELECT 
    date, year, month, product_id, product_name, category,
    number_of_transactions, total_quantity, total_sales, total_profit
FROM warehouse.mv_daily_sales_by_product
```

### mv_monthly_sales_by_customer
Pre-aggregated monthly sales by customer for trend analysis

```sql
SELECT 
    year, month, customer_id, customer_name, customer_segment,
    number_of_orders, total_quantity, total_sales, total_profit
FROM warehouse.mv_monthly_sales_by_customer
```

---

## DATA RELATIONSHIPS

```
fact_sales
├── dim_customers (1:M)
├── dim_products (1:M)
├── dim_date (1:M)
├── dim_geography (1:M)
└── dim_salesperson (1:M)

fact_inventory_movement
├── dim_products (1:M)
└── dim_date (1:M)
```

---

## IMPORTANT NOTES

1. **Date Handling**: All dates stored as DATE or TIMESTAMP in UTC
2. **Decimals**: Currency values use DECIMAL(12,2) for precision
3. **NULL Handling**: Foreign keys (except salesperson_id) are NOT NULL
4. **Slowly Changing Dimensions**: Customers use Type 2 (track changes over time)
5. **Star Schema**: All foreign keys point to dimension tables
6. **Indexes**: Created on commonly used filter and join columns

---

## Query Performance Guidelines

| Query Type | Typical Rows | Expected Time |
|------------|-------------|---------------|
| Customer segment report | 10K | <1s |
| Monthly sales trend | 100 | <100ms |
| Product profitability | 1.5K | <500ms |
| Top 10 customers | 10 | <100ms |
| Full fact table scan | 500K | 5-10s |

---

**Last Updated**: December 2025
**Schema Version**: 1.0
