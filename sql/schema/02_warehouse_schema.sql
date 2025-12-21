-- =============================================================================
-- E-COMMERCE DATA WAREHOUSE: STAR SCHEMA
-- =============================================================================
-- Production data warehouse schema with dimensional modeling
-- Date Created: December 2025
-- Author: Samarth Maske
-- =============================================================================

-- Create warehouse schema
CREATE SCHEMA IF NOT EXISTS warehouse;

-- =============================================================================
-- DIMENSION TABLES
-- =============================================================================

-- Dimension: Date (Time Dimension)
CREATE TABLE warehouse.dim_date (
    date_id SERIAL PRIMARY KEY,
    date DATE UNIQUE NOT NULL,
    year INT,
    quarter INT,
    month INT,
    week INT,
    day_of_week INT,
    day_name VARCHAR(20),
    is_weekend BOOLEAN,
    is_holiday BOOLEAN DEFAULT FALSE,
    holiday_name VARCHAR(100),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dimension: Customers
CREATE TABLE warehouse.dim_customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    postal_code VARCHAR(20),
    customer_segment VARCHAR(50),
    registration_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    last_purchase_date DATE,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dimension: Products
CREATE TABLE warehouse.dim_products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    sku VARCHAR(50),
    category VARCHAR(100),
    subcategory VARCHAR(100),
    brand VARCHAR(100),
    unit_cost DECIMAL(10, 2),
    list_price DECIMAL(10, 2),
    margin_percent DECIMAL(5, 2),
    is_active BOOLEAN DEFAULT TRUE,
    created_date DATE,
    discontinue_date DATE,
    warehouse_created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dimension: Geography
CREATE TABLE warehouse.dim_geography (
    geography_id SERIAL PRIMARY KEY,
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    region VARCHAR(100),
    postal_code VARCHAR(20),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    population INT,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dimension: Salesperson
CREATE TABLE warehouse.dim_salesperson (
    salesperson_id INT PRIMARY KEY,
    salesperson_name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20),
    department VARCHAR(100),
    region VARCHAR(100),
    manager_id INT,
    hire_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- FACT TABLES
-- =============================================================================

-- Fact: Sales Transactions
CREATE TABLE warehouse.fact_sales (
    sale_id INT PRIMARY KEY,
    customer_id INT NOT NULL,
    product_id INT NOT NULL,
    salesperson_id INT,
    date_id INT NOT NULL,
    geography_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2),
    discount_amount DECIMAL(10, 2) DEFAULT 0,
    discount_percent DECIMAL(5, 2) DEFAULT 0,
    subtotal DECIMAL(12, 2),
    tax_amount DECIMAL(10, 2),
    total_amount DECIMAL(12, 2),
    cogs DECIMAL(12, 2),
    profit DECIMAL(12, 2),
    delivery_date DATE,
    delivery_days INT,
    is_returned BOOLEAN DEFAULT FALSE,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_fact_sales_customer FOREIGN KEY (customer_id) REFERENCES warehouse.dim_customers(customer_id),
    CONSTRAINT fk_fact_sales_product FOREIGN KEY (product_id) REFERENCES warehouse.dim_products(product_id),
    CONSTRAINT fk_fact_sales_salesperson FOREIGN KEY (salesperson_id) REFERENCES warehouse.dim_salesperson(salesperson_id),
    CONSTRAINT fk_fact_sales_date FOREIGN KEY (date_id) REFERENCES warehouse.dim_date(date_id),
    CONSTRAINT fk_fact_sales_geography FOREIGN KEY (geography_id) REFERENCES warehouse.dim_geography(geography_id)
);

-- Fact: Inventory Movement
CREATE TABLE warehouse.fact_inventory_movement (
    movement_id SERIAL PRIMARY KEY,
    product_id INT NOT NULL,
    warehouse_id VARCHAR(20),
    date_id INT NOT NULL,
    quantity_in INT DEFAULT 0,
    quantity_out INT DEFAULT 0,
    quantity_on_hand INT NOT NULL,
    quantity_reserved INT DEFAULT 0,
    quantity_available INT,
    reorder_point INT,
    unit_cost DECIMAL(10, 2),
    inventory_value DECIMAL(15, 2),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_inventory_product FOREIGN KEY (product_id) REFERENCES warehouse.dim_products(product_id),
    CONSTRAINT fk_inventory_date FOREIGN KEY (date_id) REFERENCES warehouse.dim_date(date_id)
);

-- =============================================================================
-- PERFORMANCE INDEXES
-- =============================================================================

-- Fact Sales Indexes
CREATE INDEX idx_fact_sales_customer ON warehouse.fact_sales(customer_id);
CREATE INDEX idx_fact_sales_product ON warehouse.fact_sales(product_id);
CREATE INDEX idx_fact_sales_salesperson ON warehouse.fact_sales(salesperson_id);
CREATE INDEX idx_fact_sales_date ON warehouse.fact_sales(date_id);
CREATE INDEX idx_fact_sales_geography ON warehouse.fact_sales(geography_id);
CREATE INDEX idx_fact_sales_total_amount ON warehouse.fact_sales(total_amount);
CREATE INDEX idx_fact_sales_profit ON warehouse.fact_sales(profit);
CREATE INDEX idx_fact_sales_created_date ON warehouse.fact_sales(created_date);

-- Dimension Indexes
CREATE INDEX idx_dim_date_date ON warehouse.dim_date(date);
CREATE INDEX idx_dim_date_year_month ON warehouse.dim_date(year, month);
CREATE INDEX idx_dim_customers_segment ON warehouse.dim_customers(customer_segment);
CREATE INDEX idx_dim_customers_country ON warehouse.dim_customers(country);
CREATE INDEX idx_dim_products_category ON warehouse.dim_products(category);
CREATE INDEX idx_dim_products_brand ON warehouse.dim_products(brand);
CREATE INDEX idx_dim_geography_country ON warehouse.dim_geography(country);
CREATE INDEX idx_dim_geography_state ON warehouse.dim_geography(state);

-- Inventory Indexes
CREATE INDEX idx_fact_inventory_product ON warehouse.fact_inventory_movement(product_id);
CREATE INDEX idx_fact_inventory_date ON warehouse.fact_inventory_movement(date_id);
CREATE INDEX idx_fact_inventory_warehouse ON warehouse.fact_inventory_movement(warehouse_id);

-- =============================================================================
-- MATERIALIZED VIEWS FOR REPORTING (Optional)
-- =============================================================================

-- Summary: Daily Sales by Product
CREATE MATERIALIZED VIEW warehouse.mv_daily_sales_by_product AS
SELECT 
    dd.date,
    dd.year,
    dd.month,
    dp.product_id,
    dp.product_name,
    dp.category,
    COUNT(DISTINCT fs.sale_id) as number_of_transactions,
    SUM(fs.quantity) as total_quantity,
    SUM(fs.total_amount) as total_sales,
    SUM(fs.profit) as total_profit,
    AVG(fs.total_amount) as avg_transaction_value
FROM warehouse.fact_sales fs
JOIN warehouse.dim_date dd ON fs.date_id = dd.date_id
JOIN warehouse.dim_products dp ON fs.product_id = dp.product_id
GROUP BY dd.date, dd.year, dd.month, dp.product_id, dp.product_name, dp.category;

-- Summary: Monthly Sales by Customer
CREATE MATERIALIZED VIEW warehouse.mv_monthly_sales_by_customer AS
SELECT 
    dd.year,
    dd.month,
    dc.customer_id,
    dc.customer_name,
    dc.customer_segment,
    COUNT(DISTINCT fs.sale_id) as number_of_orders,
    SUM(fs.quantity) as total_quantity,
    SUM(fs.total_amount) as total_sales,
    SUM(fs.profit) as total_profit
FROM warehouse.fact_sales fs
JOIN warehouse.dim_date dd ON fs.date_id = dd.date_id
JOIN warehouse.dim_customers dc ON fs.customer_id = dc.customer_id
GROUP BY dd.year, dd.month, dc.customer_id, dc.customer_name, dc.customer_segment;

-- =============================================================================
-- SCHEMA COMMENTS
-- =============================================================================

COMMENT ON SCHEMA warehouse IS 'Production data warehouse with star schema design';
COMMENT ON TABLE warehouse.fact_sales IS 'Core fact table containing all sales transactions';
COMMENT ON TABLE warehouse.fact_inventory_movement IS 'Fact table tracking inventory movements across warehouses';
COMMENT ON TABLE warehouse.dim_date IS 'Time dimension with date attributes and holiday markers';
COMMENT ON TABLE warehouse.dim_customers IS 'Customer master dimension with demographics';
COMMENT ON TABLE warehouse.dim_products IS 'Product catalog dimension';
COMMENT ON TABLE warehouse.dim_geography IS 'Geography dimension for location-based analysis';
COMMENT ON TABLE warehouse.dim_salesperson IS 'Salesperson dimension with organizational hierarchy';
