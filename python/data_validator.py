import logging
import pandas as pd
from config import DATA_QUALITY

logger = logging.getLogger(__name__)

class DataValidator:
    """Validates raw data before loading into the staging layer."""

    def __init__(self):
        self.null_threshold = DATA_QUALITY.get('null_threshold', 0.05)
        self.duplicate_threshold = DATA_QUALITY.get('duplicate_threshold', 0.01)

    def validate_data(self, df: pd.DataFrame, dataset_name: str) -> bool:
        """
        Runs basic data quality checks on a DataFrame.
        Logs warnings or raises errors if thresholds are exceeded.
        """
        logger.info(f"Validating dataset: {dataset_name}")
        
        if df.empty:
            raise ValueError(f"Dataset {dataset_name} is empty.")

        total_rows = len(df)
        
        # 1. Null Checks
        null_counts = df.isnull().sum()
        for col, null_count in null_counts.items():
            null_ratio = null_count / total_rows
            if null_ratio > self.null_threshold:
                logger.warning(
                    f"[{dataset_name}] Column '{col}' has {null_ratio:.2%} nulls, "
                    f"exceeding threshold of {self.null_threshold:.2%}"
                )

        # 2. Duplicate Checks
        duplicate_count = df.duplicated().sum()
        duplicate_ratio = duplicate_count / total_rows
        if duplicate_ratio > self.duplicate_threshold:
            logger.warning(
                f"[{dataset_name}] Found {duplicate_ratio:.2%} duplicate rows, "
                f"exceeding threshold of {self.duplicate_threshold:.2%}"
            )
            
        logger.info(f"Validation completed for {dataset_name}.")
        return True
