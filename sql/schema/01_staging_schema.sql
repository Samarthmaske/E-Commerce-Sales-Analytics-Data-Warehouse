-- =============================================================================
-- E-COMMERCE DATA WAREHOUSE: STAGING SCHEMA
-- =============================================================================
-- This file creates the staging layer for raw data ingestion
-- Date Created: December 2025
-- Author: Samarth Maske
-- =============================================================================

-- Create staging schema
CREATE SCHEMA IF NOT EXISTS staging;

-- =============================================================================
-- STAGING TABLES - Raw data from source systems
-- =============================================================================

-- Staging table for customers
CREATE TABLE IF NOT EXISTS staging.stg_customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20),
    address VARCHAR(500),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    postal_code VARCHAR(20),
    customer_segment VARCHAR(50),
    registration_date DATE,
    load_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Staging table for products
CREATE TABLE IF NOT EXISTS staging.stg_products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    sku VARCHAR(50) UNIQUE,
    category VARCHAR(100),
    subcategory VARCHAR(100),
    brand VARCHAR(100),
    unit_cost DECIMAL(10, 2),
    list_price DECIMAL(10, 2),
    active_status BOOLEAN DEFAULT TRUE,
    created_date DATE,
    load_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Staging table for sales orders
CREATE TABLE IF NOT EXISTS staging.stg_sales (
    sale_id INT PRIMARY KEY,
    customer_id INT NOT NULL,
    product_id INT NOT NULL,
    salesperson_id INT,
    order_date DATE NOT NULL,
    delivery_date DATE,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2),
    discount_percent DECIMAL(5, 2) DEFAULT 0,
    total_amount DECIMAL(12, 2),
    profit DECIMAL(12, 2),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    load_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Staging table for inventory
CREATE TABLE IF NOT EXISTS staging.stg_inventory (
    inventory_id INT PRIMARY KEY,
    product_id INT NOT NULL,
    warehouse_id VARCHAR(20),
    quantity_on_hand INT,
    quantity_reserved INT,
    quantity_available INT,
    reorder_point INT,
    last_stock_date DATE,
    load_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Staging table for salespersons
CREATE TABLE IF NOT EXISTS staging.stg_salesperson (
    salesperson_id INT PRIMARY KEY,
    salesperson_name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20),
    department VARCHAR(100),
    region VARCHAR(100),
    manager_id INT,
    hire_date DATE,
    load_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- STAGING INDEXES - Improve data loading performance
-- =============================================================================

CREATE INDEX idx_stg_customers_email ON staging.stg_customers(email);
CREATE INDEX idx_stg_customers_city ON staging.stg_customers(city);
CREATE INDEX idx_stg_products_sku ON staging.stg_products(sku);
CREATE INDEX idx_stg_products_category ON staging.stg_products(category);
CREATE INDEX idx_stg_sales_customer ON staging.stg_sales(customer_id);
CREATE INDEX idx_stg_sales_product ON staging.stg_sales(product_id);
CREATE INDEX idx_stg_sales_date ON staging.stg_sales(order_date);
CREATE INDEX idx_stg_inventory_product ON staging.stg_inventory(product_id);

-- =============================================================================
-- AUDIT TABLE - Track data quality issues
-- =============================================================================

CREATE TABLE IF NOT EXISTS staging.data_quality_audit (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(100),
    issue_type VARCHAR(100),
    issue_description TEXT,
    row_count INT,
    affected_records INT,
    audit_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- End of file
