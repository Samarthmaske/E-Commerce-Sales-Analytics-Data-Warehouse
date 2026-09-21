FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libpq-dev gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements file first for caching
COPY requirements.txt .

# Install python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application
COPY . .

# Set PYTHONPATH so the python module can be found
ENV PYTHONPATH=/app

# Create necessary directories
RUN mkdir -p logs backups data/sample_data

# Run the ETL pipeline as the default command
CMD ["python", "python/etl_pipeline.py"]
