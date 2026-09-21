# Free Deployment Guide (GitHub Actions + Neon)

If you are looking for a **100% free** way to run your ETL pipeline and host your PostgreSQL database, this guide covers the best modern combination: **GitHub Actions** (for compute) and **Neon.tech** (for the database).

## 1. The Database (Aiven or TiDB)
AWS RDS does not have a "forever free" tier (only 12 months). If you want a permanently free MySQL database:
1. Go to [Aiven.io](https://aiven.io/) (for MySQL) or [TiDB Serverless](https://en.pingcap.com/tidb-serverless/) and sign up.
2. Create a new free-tier MySQL project.
3. Copy your connection string. It will look like this: `mysql+pymysql://user:password@hostname:port/dbname`.

## 2. The Compute (GitHub Actions)
GitHub provides **2,000 free minutes per month** of compute time. Since this is an ETL pipeline that only runs once a day, it will only use about 30-60 minutes a month, keeping it completely free forever.

### Step 1: Add Secrets to GitHub
You don't want your database passwords in your public code.
1. Go to your repository on GitHub.
2. Click **Settings** > **Secrets and variables** > **Actions**.
3. Click **New repository secret** and add your variables (e.g., `DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`). If you use Neon, you can just set them based on the connection string they give you.

### Step 2: Create the Workflow File
In your repository, create a new file at `.github/workflows/etl-pipeline.yml` and add the following code:

```yaml
name: Daily ETL Pipeline

# Run at 2:00 AM UTC every day, and allow manual triggering
on:
  schedule:
    - cron: '0 2 * * *'
  workflow_dispatch:

jobs:
  run-etl:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout Code
      uses: actions/checkout@v3

    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.9'

    - name: Install Dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
        
    # Optional: If you need system dependencies for psycopg2
    - name: Install System Dependencies
      run: sudo apt-get install -y libpq-dev gcc

    - name: Run ETL Pipeline
      env:
        DB_HOST: ${{ secrets.DB_HOST }}
        DB_PORT: ${{ secrets.DB_PORT || '5432' }}
        DB_NAME: ${{ secrets.DB_NAME }}
        DB_USER: ${{ secrets.DB_USER }}
        DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
        PYTHONPATH: ${{ github.workspace }}
      run: |
        python python/etl_pipeline.py
```

### Step 3: Commit and Push
Once you commit this file to your repository, GitHub will automatically pick it up. 
- It will run on the schedule you defined.
- You can also run it manually anytime by going to the **Actions** tab on your GitHub repository, selecting "Daily ETL Pipeline", and clicking **Run workflow**.

## Conclusion
This setup guarantees you will never receive a bill. GitHub Actions handles the orchestration and scheduling, and Neon provides a fast, serverless PostgreSQL database.
