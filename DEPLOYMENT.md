# Deployment Guide

This project is fully containerized with Docker, making it easy to run the ETL pipeline across various environments, from a local machine to cloud services like AWS ECS or Kubernetes.

## Prerequisites
- **Docker** and **Docker Compose** installed on your system.

## 1. Local Testing with Docker Compose

You can spin up both a local PostgreSQL database and the ETL pipeline using Docker Compose. This is ideal for testing the pipeline end-to-end before deploying to production.

```bash
# 1. Create your environment variables file
cp .env.example .env

# 2. Start the local database in the background
docker-compose up -d db

# 3. Wait a moment for the DB to initialize, then run the ETL pipeline
docker-compose up etl
```

The ETL container will run, execute the pipeline (loading data from `data/sample_data/` into the `db` container), and then exit. You can check the logs from `logs/etl_pipeline.log` on your host machine, since the `logs` directory is mounted into the container.

## 2. Production Deployment

In a production scenario, your database will likely be hosted on AWS RDS (as described in `docs/SETUP_GUIDE.md`), and you will only run the ETL container.

### Step 1: Configure Environment Variables

Create a `.env` file or set the environment variables in your deployment environment (e.g., AWS Parameter Store, ECS Task Definition secrets) with your RDS credentials:

```ini
DB_HOST=your-production-db.cluster-xxxxxx.us-east-1.rds.amazonaws.com
DB_PORT=5432
DB_NAME=ecommerce_dw
DB_USER=production_user
DB_PASSWORD=your_secure_password
```

### Step 2: Build and Push the Docker Image

Build the Docker image and push it to a container registry such as AWS ECR:

```bash
# Build the image
docker build -t ecommerce-etl:latest .

# Tag the image for ECR (replace with your AWS account ID and region)
docker tag ecommerce-etl:latest 123456789012.dkr.ecr.us-east-1.amazonaws.com/ecommerce-etl:latest

# Push to ECR
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/ecommerce-etl:latest
```

### Step 3: Run the Container

You can now run this container image on any container orchestration platform:

- **AWS ECS / Fargate**: Create a Task Definition using this image and your environment variables. Trigger the task manually, via AWS EventBridge (for scheduled runs), or via AWS Step Functions.
- **Kubernetes (EKS)**: Deploy it as a `CronJob` or a one-off `Job`.
- **EC2 / Standalone Docker**: Run the container directly:
  ```bash
  docker run --env-file .env ecommerce-etl:latest
  ```

## 3. Scheduling and Orchestration

Since this is an ETL process, it is typically scheduled to run at regular intervals. 

- **Cron**: For simple deployments on a VM (like EC2), you can use the system `cron` to run the `docker run` command daily.
- **AWS EventBridge**: If deploying on AWS ECS, use EventBridge to trigger your ECS task on a schedule (e.g., `cron(0 2 * * ? *)` for 2 AM daily).
- **Apache Airflow**: For complex workflows, you can trigger this Docker container using Airflow's `DockerOperator` or `ECSOperator`.
