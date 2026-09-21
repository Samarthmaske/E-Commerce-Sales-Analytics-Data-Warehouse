"""
E-Commerce Data Warehouse: ETL Pipeline Orchestration
Main ETL orchestration module for data loading and transformation
Author: Samarth Maske
"""

import logging
import sys
from datetime import datetime
import pymysql

import pandas as pd
from config import DB_CONFIG, DATA_PATHS, ETL_CONFIG, LOG_CONFIG
from data_loader import DataLoader
from data_validator import DataValidator

import os

# Create logs directory if it doesn't exist
log_file_path = LOG_CONFIG['log_file']
os.makedirs(os.path.dirname(log_file_path), exist_ok=True)

# Configure logging
logging.basicConfig(
    level=LOG_CONFIG['log_level'],
    format=LOG_CONFIG['log_format'],
    handlers=[
        logging.FileHandler(LOG_CONFIG['log_file']),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

class ETLPipeline:
    """Main ETL Pipeline Orchestration Class"""
    
    def __init__(self):
        """Initialize ETL Pipeline"""
        self.conn = None
        self.cursor = None
        self.data_loader = DataLoader()
        self.validator = DataValidator()
        self.start_time = None
        self.end_time = None
        
    def connect_database(self):
        """Establish database connection"""
        try:
            self.conn = pymysql.connect(**DB_CONFIG)
            self.cursor = self.conn.cursor()
            logger.info("Successfully connected to MySQL database")
            return True
        except pymysql.Error as e:
            logger.error(f"Database connection error: {e}")
            return False
    
    def disconnect_database(self):
        """Close database connection"""
        if self.cursor:
            self.cursor.close()
        if self.conn:
            self.conn.close()
            logger.info("Database connection closed")
    
    def run_sql_script(self, script_path):
        """Execute SQL script"""
        try:
            with open(script_path, 'r') as f:
                sql_script = f.read()
            
            # Split the script by semicolon to execute statements individually
            # This avoids the "multi-statement capability disabled" error in TiDB/MySQL
            statements = [s.strip() for s in sql_script.split(';') if s.strip()]
            for statement in statements:
                try:
                    self.cursor.execute(statement)
                except Exception as e:
                    # 1061: Duplicate key name (Index already exists)
                    if hasattr(e, 'args') and e.args[0] == 1061:
                        logger.debug("Index already exists, skipping.")
                    else:
                        raise e
                
            self.conn.commit()
            logger.info(f"Successfully executed script: {script_path}")
            return True
        except Exception as e:
            logger.error(f"Error executing script {script_path}: {e}")
            self.conn.rollback()
            return False
    
    def load_staging_data(self):
        """Load raw data into staging tables"""
        logger.info("Starting staging data load...")
        
        try:
            # Load customers
            customers_df = pd.read_csv(DATA_PATHS['customers'])
            self.validator.validate_data(customers_df, 'customers')
            self.data_loader.load_to_staging(self.cursor, customers_df, 'stg_customers')
            logger.info(f"Loaded {len(customers_df)} customer records")
            
            # Load products
            products_df = pd.read_csv(DATA_PATHS['products'])
            self.validator.validate_data(products_df, 'products')
            self.data_loader.load_to_staging(self.cursor, products_df, 'stg_products')
            logger.info(f"Loaded {len(products_df)} product records")
            
            # Load sales
            sales_df = pd.read_csv(DATA_PATHS['sales'])
            self.validator.validate_data(sales_df, 'sales')
            self.data_loader.load_to_staging(self.cursor, sales_df, 'stg_sales')
            logger.info(f"Loaded {len(sales_df)} sales records")
            
            # Load inventory
            inventory_df = pd.read_csv(DATA_PATHS['inventory'])
            self.validator.validate_data(inventory_df, 'inventory')
            self.data_loader.load_to_staging(self.cursor, inventory_df, 'stg_inventory')
            logger.info(f"Loaded {len(inventory_df)} inventory records")
            
            # Load salesperson
            salesperson_df = pd.read_csv(DATA_PATHS['salesperson'])
            self.validator.validate_data(salesperson_df, 'salesperson')
            self.data_loader.load_to_staging(self.cursor, salesperson_df, 'stg_salesperson')
            logger.info(f"Loaded {len(salesperson_df)} salesperson records")
            
            self.conn.commit()
            logger.info("Staging data load completed successfully")
            return True
            
        except Exception as e:
            logger.error(f"Error during staging data load: {e}")
            self.conn.rollback()
            return False
    
    def create_warehouse_schema(self):
        """Create star schema tables"""
        logger.info("Creating warehouse schema...")
        
        script_path = 'sql/schema/02_warehouse_schema.sql'
        return self.run_sql_script(script_path)
    
    def populate_warehouse(self):
        """Populate warehouse from staging tables"""
        logger.info("Populating warehouse tables...")
        
        try:
            # Populate dimensions
            self._populate_dim_date()
            self._populate_dim_customers()
            self._populate_dim_products()
            self._populate_dim_geography()
            self._populate_dim_salesperson()
            
            # Populate facts
            self._populate_fact_sales()
            self._populate_fact_inventory()
            
            self.conn.commit()
            logger.info("Warehouse population completed successfully")
            return True
            
        except Exception as e:
            logger.error(f"Error populating warehouse: {e}")
            self.conn.rollback()
            return False
    
    def _populate_dim_date(self):
        """Populate date dimension"""
        sql = """
        INSERT IGNORE INTO warehouse.dim_date 
        (date, year, quarter, month, week, day_of_week, day_name, is_weekend)
        SELECT DISTINCT 
            order_date,
            EXTRACT(YEAR FROM order_date),
            EXTRACT(QUARTER FROM order_date),
            EXTRACT(MONTH FROM order_date),
            EXTRACT(WEEK FROM order_date),
            DAYOFWEEK(order_date),
            DAYNAME(order_date),
            DAYOFWEEK(order_date) IN (1, 7)
        FROM staging.stg_sales
        
        """
        self.cursor.execute(sql)
        logger.info("Populated dim_date")
    
    def _populate_dim_customers(self):
        """Populate customer dimension"""
        sql = """
        INSERT IGNORE INTO warehouse.dim_customers 
        (customer_id, customer_name, email, phone, city, state, country, 
         postal_code, customer_segment, registration_date)
        SELECT 
            customer_id, customer_name, email, phone, city, state, country,
            postal_code, customer_segment, registration_date
        FROM staging.stg_customers
        
        """
        self.cursor.execute(sql)
        logger.info("Populated dim_customers")
    
    def _populate_dim_products(self):
        """Populate product dimension"""
        sql = """
        INSERT IGNORE INTO warehouse.dim_products 
        (product_id, product_name, sku, category, subcategory, brand, 
         unit_cost, list_price)
        SELECT 
            product_id, product_name, sku, category, subcategory, brand,
            unit_cost, list_price
        FROM staging.stg_products
        
        """
        self.cursor.execute(sql)
        logger.info("Populated dim_products")
    
    def _populate_dim_geography(self):
        """Populate geography dimension"""
        sql = """
        INSERT IGNORE INTO warehouse.dim_geography (city, state, country)
        SELECT DISTINCT city, state, country
        FROM staging.stg_sales
        WHERE city IS NOT NULL
        
        """
        self.cursor.execute(sql)
        logger.info("Populated dim_geography")
    
    def _populate_dim_salesperson(self):
        """Populate salesperson dimension"""
        sql = """
        INSERT IGNORE INTO warehouse.dim_salesperson 
        (salesperson_id, salesperson_name, email, department, region)
        SELECT 
            salesperson_id, salesperson_name, email, department, region
        FROM staging.stg_salesperson
        
        """
        self.cursor.execute(sql)
        logger.info("Populated dim_salesperson")
    
    def _populate_fact_sales(self):
        """Populate sales fact table"""
        sql = """
        INSERT IGNORE INTO warehouse.fact_sales
        (sale_id, customer_id, product_id, salesperson_id, date_id, 
         geography_id, quantity, unit_price, discount_percent, total_amount, profit)
        SELECT 
            s.sale_id,
            s.customer_id,
            s.product_id,
            s.salesperson_id,
            d.date_id,
            g.geography_id,
            s.quantity,
            s.unit_price,
            COALESCE(s.discount_percent, 0),
            s.total_amount,
            s.profit
        FROM staging.stg_sales s
        JOIN warehouse.dim_date d ON DATE(s.order_date) = d.date
        LEFT JOIN warehouse.dim_geography g ON s.city = g.city 
            AND s.state = g.state AND s.country = g.country
        
        """
        self.cursor.execute(sql)
        logger.info("Populated fact_sales")
    
    def _populate_fact_inventory(self):
        """Populate inventory fact table"""
        sql = """
        INSERT IGNORE INTO warehouse.fact_inventory_movement
        (product_id, warehouse_id, date_id, quantity_on_hand)
        SELECT DISTINCT
            i.product_id,
            i.warehouse_id,
            d.date_id,
            i.quantity_on_hand
        FROM staging.stg_inventory i
        CROSS JOIN warehouse.dim_date d
        WHERE d.date <= CURRENT_DATE
        
        """
        self.cursor.execute(sql)
        logger.info("Populated fact_inventory")
    
    def create_indexes(self):
        """Create performance indexes"""
        logger.info("Creating performance indexes...")
        script_path = 'sql/schema/03_indexes.sql'
        if not os.path.exists(script_path):
            logger.info(f"Index script {script_path} not found. Skipping.")
            return True
        return self.run_sql_script(script_path)
    
    def run_quality_checks(self):
        """Execute data quality validations"""
        logger.info("Running data quality checks...")
        
        checks = [
            ("Fact Sales Row Count", "SELECT COUNT(*) FROM warehouse.fact_sales"),
            ("Dim Customers Row Count", "SELECT COUNT(*) FROM warehouse.dim_customers"),
            ("Dim Products Row Count", "SELECT COUNT(*) FROM warehouse.dim_products"),
            ("NULL Values in fact_sales", 
             "SELECT COUNT(*) FROM warehouse.fact_sales WHERE sale_id IS NULL"),
            ("Referential Integrity - Sales to Customers",
             "SELECT COUNT(*) FROM warehouse.fact_sales WHERE customer_id NOT IN "
             "(SELECT customer_id FROM warehouse.dim_customers)")
        ]
        
        for check_name, query in checks:
            try:
                self.cursor.execute(query)
                result = self.cursor.fetchone()[0]
                logger.info(f"Quality Check - {check_name}: {result}")
            except Exception as e:
                logger.error(f"Quality check '{check_name}' failed: {e}")
    
    def generate_report(self):
        """Generate execution report"""
        duration = (self.end_time - self.start_time).total_seconds()
        
        report = f"""
        ====================================================
        ETL PIPELINE EXECUTION REPORT
        ====================================================
        Start Time: {self.start_time}
        End Time: {self.end_time}
        Duration: {duration:.2f} seconds
        Status: COMPLETED
        
        Database: {DB_CONFIG['database']}
        Batch Size: {ETL_CONFIG['batch_size']}
        ====================================================
        """
        
        logger.info(report)
        return report
    
    def execute(self):
        """Execute complete ETL pipeline"""
        logger.info("=" * 60)
        logger.info("E-COMMERCE DATA WAREHOUSE ETL PIPELINE STARTED")
        logger.info("=" * 60)
        
        self.start_time = datetime.now()
        
        try:
            # Connect to database
            if not self.connect_database():
                return False
            
            # Create staging schema
            logger.info("Creating staging schema...")
            if not self.run_sql_script('sql/schema/01_staging_schema.sql'):
                return False
            
            # Load staging data
            if not self.load_staging_data():
                return False
            
            # Create warehouse schema
            if not self.create_warehouse_schema():
                return False
            
            # Populate warehouse
            if not self.populate_warehouse():
                return False
            
            # Create indexes
            if not self.create_indexes():
                return False
            
            # Run quality checks
            self.run_quality_checks()
            
            logger.info("ETL PIPELINE COMPLETED SUCCESSFULLY!")
            
        except Exception as e:
            logger.error(f"Pipeline execution failed: {e}")
            return False
        
        finally:
            self.end_time = datetime.now()
            self.generate_report()
            self.disconnect_database()
        
        return True

if __name__ == '__main__':
    pipeline = ETLPipeline()
    success = pipeline.execute()
    sys.exit(0 if success else 1)
