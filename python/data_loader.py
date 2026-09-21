import logging
import pandas as pd
import numpy as np

logger = logging.getLogger(__name__)

class DataLoader:
    """Handles bulk loading of data into the database."""

    def load_to_staging(self, cursor, df: pd.DataFrame, table_name: str) -> None:
        """
        Loads a pandas DataFrame into a staging table using PyMySQL executemany.
        Uses INSERT IGNORE to gracefully handle duplicates during bulk loads.
        """
        if df.empty:
            logger.warning(f"No data to load for table {table_name}.")
            return
            
        # Replace pandas NaN/NaT with None so PyMySQL inserts SQL NULL
        df = df.replace({np.nan: None})

        columns = list(df.columns)
        columns_str = ", ".join(columns)
        # Create placeholders e.g., %s, %s, %s
        placeholders = ", ".join(["%s"] * len(columns))

        # We use INSERT IGNORE for MySQL instead of ON CONFLICT DO NOTHING
        insert_query = f"INSERT IGNORE INTO staging.{table_name} ({columns_str}) VALUES ({placeholders})"
        
        # Convert DataFrame to a list of tuples for executemany
        data_tuples = [tuple(x) for x in df.to_numpy()]

        try:
            logger.info(f"Loading {len(data_tuples)} rows into {table_name}...")
            cursor.executemany(insert_query, data_tuples)
            logger.debug(f"Successfully executed batch insert for {table_name}.")
        except Exception as e:
            logger.error(f"Failed to load data into {table_name}: {e}")
            raise
