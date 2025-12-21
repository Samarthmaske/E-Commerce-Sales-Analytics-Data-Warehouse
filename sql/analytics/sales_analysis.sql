-- =============================================================================
-- E-COMMERCE DATA WAREHOUSE: ANALYTICS QUERIES
-- =============================================================================
-- Production queries for business intelligence and reporting
-- Date Created: December 2025
-- Author: Samarth Maske
-- =============================================================================

-- ============================================================================
-- 1. SALES ANALYSIS QUERIES
-- ============================================================================

-- Query 1.1: Top 10 Customers by Revenue
-- Identify high-value customers for retention and loyalty programs
SELECT 
    c.customer_id,
    c.customer_name,
    c.customer_segment,
    c.city,
    c.country,
    COUNT(DISTINCT fs.sale_id) as total_orders,
    SUM(fs.quantity) as total_items_purchased,
    SUM(fs.total_amount) as total_revenue,
    SUM(fs.profit) as total_profit,
    AVG(fs.total_amount) as avg_order_value,
    MAX(fs.created_date) as last_purchase_date
FROM warehouse.fact_sales fs
JOIN warehouse.dim_customers c ON fs.customer_id = c.customer_id
WHERE fs.created_date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY c.customer_id, c.customer_name, c.customer_segment, c.city, c.country
ORDER BY total_revenue DESC
LIMIT 10;

-- Query 1.2: Monthly Sales Trend Analysis
-- Track sales performance over time with profit margins
SELECT 
    EXTRACT(YEAR FROM dd.date) as year,
    EXTRACT(MONTH FROM dd.date) as month,
    dd.month as month_name,
    COUNT(DISTINCT fs.sale_id) as number_of_transactions,
    SUM(fs.quantity) as total_quantity_sold,
    SUM(fs.total_amount) as total_sales,
    SUM(fs.profit) as total_profit,
    ROUND(SUM(fs.profit) / SUM(fs.total_amount) * 100, 2) as profit_margin_percent,
    AVG(fs.total_amount) as avg_transaction_value
FROM warehouse.fact_sales fs
JOIN warehouse.dim_date dd ON fs.date_id = dd.date_id
WHERE fs.created_date >= CURRENT_DATE - INTERVAL '2 years'
GROUP BY EXTRACT(YEAR FROM dd.date), EXTRACT(MONTH FROM dd.date), dd.month
ORDER BY year DESC, month DESC;

-- Query 1.3: Sales Performance by Geography
-- Analyze sales distribution across regions and countries
SELECT 
    dg.country,
    dg.state,
    dg.city,
    COUNT(DISTINCT fs.sale_id) as transaction_count,
    COUNT(DISTINCT fs.customer_id) as unique_customers,
    SUM(fs.total_amount) as total_sales,
    SUM(fs.profit) as total_profit,
    ROUND(SUM(fs.profit) / SUM(fs.total_amount) * 100, 2) as profit_margin,
    ROUND(SUM(fs.total_amount) / COUNT(DISTINCT fs.sale_id), 2) as avg_order_value
FROM warehouse.fact_sales fs
JOIN warehouse.dim_geography dg ON fs.geography_id = dg.geography_id
GROUP BY dg.country, dg.state, dg.city
ORDER BY total_sales DESC;

-- Query 1.4: Top 20 Products by Revenue
-- Identify best-performing products
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    p.subcategory,
    p.brand,
    p.list_price,
    p.unit_cost,
    COUNT(DISTINCT fs.sale_id) as sales_count,
    SUM(fs.quantity) as quantity_sold,
    SUM(fs.total_amount) as total_revenue,
    SUM(fs.profit) as total_profit,
    ROUND(SUM(fs.profit) / SUM(fs.total_amount) * 100, 2) as profit_margin,
    ROUND(AVG(fs.total_amount), 2) as avg_sale_value
FROM warehouse.fact_sales fs
JOIN warehouse.dim_products p ON fs.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category, p.subcategory, 
         p.brand, p.list_price, p.unit_cost
ORDER BY total_revenue DESC
LIMIT 20;

-- Query 1.5: Sales by Category and Subcategory
-- Category-level performance metrics
SELECT 
    p.category,
    p.subcategory,
    COUNT(DISTINCT fs.sale_id) as number_of_orders,
    COUNT(DISTINCT fs.customer_id) as unique_customers,
    SUM(fs.quantity) as total_quantity,
    SUM(fs.total_amount) as total_sales,
    SUM(fs.profit) as total_profit,
    ROUND(SUM(fs.profit) / SUM(fs.total_amount) * 100, 2) as profit_margin_percent,
    AVG(fs.discount_percent) as avg_discount_percent
FROM warehouse.fact_sales fs
JOIN warehouse.dim_products p ON fs.product_id = p.product_id
GROUP BY p.category, p.subcategory
ORDER BY total_sales DESC;

-- ============================================================================
-- 2. CUSTOMER ANALYSIS QUERIES
-- ============================================================================

-- Query 2.1: Customer Segmentation Analysis
-- Analyze customers by segment with metrics
SELECT 
    c.customer_segment,
    COUNT(DISTINCT c.customer_id) as number_of_customers,
    COUNT(DISTINCT fs.sale_id) as total_orders,
    SUM(fs.total_amount) as segment_revenue,
    ROUND(AVG(fs.total_amount), 2) as avg_order_value,
    ROUND(SUM(fs.total_amount) / COUNT(DISTINCT c.customer_id), 2) as customer_lifetime_value,
    SUM(fs.profit) as total_profit,
    ROUND(COUNT(DISTINCT fs.sale_id) / COUNT(DISTINCT c.customer_id), 2) as avg_orders_per_customer
FROM warehouse.fact_sales fs
JOIN warehouse.dim_customers c ON fs.customer_id = c.customer_id
GROUP BY c.customer_segment
ORDER BY segment_revenue DESC;

-- Query 2.2: Customer Lifetime Value (CLV) Analysis
-- Calculate CLV for customer retention strategies
SELECT 
    c.customer_id,
    c.customer_name,
    c.customer_segment,
    c.registration_date,
    COUNT(DISTINCT fs.sale_id) as lifetime_orders,
    SUM(fs.total_amount) as lifetime_revenue,
    SUM(fs.profit) as lifetime_profit,
    ROUND(SUM(fs.total_amount) / COUNT(DISTINCT fs.sale_id), 2) as avg_order_value,
    ROUND(DATEDIFF(day, c.registration_date, MAX(fs.created_date)) / 365.0, 1) as years_as_customer,
    ROUND(SUM(fs.total_amount) / NULLIF(DATEDIFF(day, c.registration_date, MAX(fs.created_date)), 0), 2) as revenue_per_day,
    MAX(fs.created_date) as last_purchase_date,
    DATEDIFF(day, MAX(fs.created_date), CURRENT_DATE) as days_since_last_purchase
FROM warehouse.fact_sales fs
JOIN warehouse.dim_customers c ON fs.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name, c.customer_segment, c.registration_date
ORDER BY lifetime_revenue DESC;

-- Query 2.3: Customer Purchase Frequency
-- Identify repeat customers and purchase patterns
SELECT 
    c.customer_id,
    c.customer_name,
    c.country,
    COUNT(DISTINCT CAST(fs.created_date AS DATE)) as purchase_days,
    COUNT(DISTINCT fs.sale_id) as total_purchases,
    MIN(fs.created_date) as first_purchase_date,
    MAX(fs.created_date) as last_purchase_date,
    DATEDIFF(day, MIN(fs.created_date), MAX(fs.created_date)) as customer_age_days,
    ROUND(COUNT(DISTINCT fs.sale_id) * 365.0 / DATEDIFF(day, MIN(fs.created_date), MAX(fs.created_date)), 2) as annual_purchase_frequency,
    SUM(fs.total_amount) as total_spent,
    ROUND(AVG(fs.total_amount), 2) as avg_order_value
FROM warehouse.fact_sales fs
JOIN warehouse.dim_customers c ON fs.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name, c.country
HAVING COUNT(DISTINCT fs.sale_id) >= 2
ORDER BY total_purchases DESC;

-- Query 2.4: Geographic Customer Distribution
-- Analyze customer base distribution
SELECT 
    dg.country,
    dg.state,
    COUNT(DISTINCT fs.customer_id) as unique_customers,
    COUNT(DISTINCT fs.sale_id) as total_orders,
    SUM(fs.total_amount) as total_sales,
    SUM(fs.profit) as total_profit,
    ROUND(SUM(fs.total_amount) / COUNT(DISTINCT fs.customer_id), 2) as revenue_per_customer,
    ROUND(AVG(fs.total_amount), 2) as avg_order_value
FROM warehouse.fact_sales fs
JOIN warehouse.dim_geography dg ON fs.geography_id = dg.geography_id
GROUP BY dg.country, dg.state
ORDER BY total_sales DESC;

-- ============================================================================
-- 3. INVENTORY ANALYSIS QUERIES
-- ============================================================================

-- Query 3.1: Current Inventory Status by Warehouse
-- Monitor stock levels across warehouses
SELECT 
    fim.warehouse_id,
    p.product_id,
    p.product_name,
    p.category,
    fim.quantity_on_hand,
    fim.quantity_reserved,
    fim.quantity_available,
    fim.reorder_point,
    CASE 
        WHEN fim.quantity_available <= fim.reorder_point THEN 'Reorder Required'
        WHEN fim.quantity_available <= fim.reorder_point * 1.5 THEN 'Low Stock'
        ELSE 'Adequate'
    END as stock_status,
    fim.unit_cost,
    fim.inventory_value,
    fim.created_date
FROM warehouse.fact_inventory_movement fim
JOIN warehouse.dim_products p ON fim.product_id = p.product_id
WHERE fim.created_date = (SELECT MAX(created_date) FROM warehouse.fact_inventory_movement)
ORDER BY fim.warehouse_id, stock_status DESC;

-- Query 3.2: Inventory Turnover Analysis
-- Measure how quickly inventory is sold
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    p.unit_cost,
    SUM(fs.quantity) as total_quantity_sold,
    AVG(fim.quantity_on_hand) as avg_inventory_level,
    ROUND(SUM(fs.quantity) / NULLIF(AVG(fim.quantity_on_hand), 0), 2) as inventory_turnover_ratio,
    ROUND(365 / NULLIF(SUM(fs.quantity) / NULLIF(AVG(fim.quantity_on_hand), 0), 0), 0) as days_inventory_outstanding
FROM warehouse.fact_sales fs
JOIN warehouse.dim_products p ON fs.product_id = p.product_id
JOIN warehouse.fact_inventory_movement fim ON p.product_id = fim.product_id
GROUP BY p.product_id, p.product_name, p.category, p.unit_cost
ORDER BY inventory_turnover_ratio DESC;

-- Query 3.3: Low Stock Alert Report
-- Products requiring reorder
SELECT 
    fim.warehouse_id,
    p.product_id,
    p.product_name,
    p.category,
    p.brand,
    fim.quantity_on_hand,
    fim.reorder_point,
    fim.quantity_available,
    (fim.reorder_point - fim.quantity_available) as units_below_reorder_point,
    p.list_price,
    (fim.reorder_point - fim.quantity_available) * p.unit_cost as estimated_reorder_cost
FROM warehouse.fact_inventory_movement fim
JOIN warehouse.dim_products p ON fim.product_id = p.product_id
WHERE fim.quantity_available <= fim.reorder_point
AND fim.created_date = (SELECT MAX(created_date) FROM warehouse.fact_inventory_movement)
ORDER BY units_below_reorder_point DESC;

-- ============================================================================
-- 4. SALES PERFORMANCE BY SALESPERSON
-- ============================================================================

-- Query 4.1: Salesperson Performance Metrics
-- Individual and team sales metrics
SELECT 
    sp.salesperson_id,
    sp.salesperson_name,
    sp.department,
    sp.region,
    COUNT(DISTINCT fs.sale_id) as number_of_sales,
    COUNT(DISTINCT fs.customer_id) as unique_customers,
    SUM(fs.total_amount) as total_sales,
    SUM(fs.profit) as total_profit,
    ROUND(SUM(fs.profit) / SUM(fs.total_amount) * 100, 2) as profit_margin_percent,
    ROUND(AVG(fs.total_amount), 2) as avg_sale_value,
    ROUND(AVG(fs.discount_percent), 2) as avg_discount_given
FROM warehouse.fact_sales fs
JOIN warehouse.dim_salesperson sp ON fs.salesperson_id = sp.salesperson_id
GROUP BY sp.salesperson_id, sp.salesperson_name, sp.department, sp.region
ORDER BY total_sales DESC;

-- ============================================================================
-- 5. PROFITABILITY ANALYSIS
-- ============================================================================

-- Query 5.1: Product Profitability Matrix
-- Analyze profit contribution by product
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    COUNT(DISTINCT fs.sale_id) as sales_count,
    SUM(fs.quantity) as quantity_sold,
    SUM(fs.total_amount) as revenue,
    SUM(fs.cogs) as total_cogs,
    SUM(fs.profit) as total_profit,
    ROUND(SUM(fs.profit) / SUM(fs.total_amount) * 100, 2) as profit_margin_percent,
    ROUND(SUM(fs.profit) / SUM(fs.quantity), 2) as profit_per_unit,
    ROUND(SUM(fs.discount_amount) / SUM(fs.total_amount) * 100, 2) as discount_impact_percent
FROM warehouse.fact_sales fs
JOIN warehouse.dim_products p ON fs.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY total_profit DESC
LIMIT 25;

-- Query 5.2: Discount Impact Analysis
-- Understand effect of discounts on profitability
SELECT 
    CASE 
        WHEN fs.discount_percent = 0 THEN 'No Discount'
        WHEN fs.discount_percent <= 5 THEN '1-5%'
        WHEN fs.discount_percent <= 10 THEN '6-10%'
        WHEN fs.discount_percent <= 20 THEN '11-20%'
        ELSE 'Above 20%'
    END as discount_range,
    COUNT(DISTINCT fs.sale_id) as number_of_orders,
    SUM(fs.total_amount) as total_revenue,
    AVG(fs.total_amount) as avg_order_value,
    SUM(fs.profit) as total_profit,
    ROUND(AVG(fs.profit), 2) as avg_profit_per_order,
    ROUND(SUM(fs.profit) / SUM(fs.total_amount) * 100, 2) as profit_margin_percent
FROM warehouse.fact_sales fs
GROUP BY CASE 
    WHEN fs.discount_percent = 0 THEN 'No Discount'
    WHEN fs.discount_percent <= 5 THEN '1-5%'
    WHEN fs.discount_percent <= 10 THEN '6-10%'
    WHEN fs.discount_percent <= 20 THEN '11-20%'
    ELSE 'Above 20%'
END
ORDER BY discount_range;
