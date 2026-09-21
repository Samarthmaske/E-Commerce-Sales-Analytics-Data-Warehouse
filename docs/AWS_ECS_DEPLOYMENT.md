# Deploying ETL Pipeline with AWS ECS Fargate & EventBridge

This guide covers how to deploy the E-Commerce Data Warehouse ETL pipeline as a serverless container on AWS. This architecture ensures you only pay for compute resources while the ETL pipeline is actually running, making it highly cost-effective and scalable.

## Architecture Overview
1. **AWS ECR**: Stores your Docker image.
2. **AWS ECS (Fargate)**: Runs your container serverlessly.
3. **Amazon EventBridge**: Triggers the ECS task on a schedule (e.g., daily).

---

## Step 1: Push Docker Image to Amazon ECR

First, we need to upload your Dockerized application to AWS Elastic Container Registry (ECR).

1. Go to the AWS Console and navigate to **Elastic Container Registry**.
2. Click **Create repository**.
   - Name it `ecommerce-etl`.
   - Leave other settings as default and click **Create**.
3. Select your new repository and click **View push commands**. Follow the AWS-provided instructions for your OS to authenticate, build, tag, and push your image. It will look something like this:
   ```bash
   # Authenticate Docker to your AWS account
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com

   # Build the image locally
   docker build -t ecommerce-etl .

   # Tag the image for ECR
   docker tag ecommerce-etl:latest 123456789012.dkr.ecr.us-east-1.amazonaws.com/ecommerce-etl:latest

   # Push the image to AWS
   docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/ecommerce-etl:latest
   ```

---

## Step 2: Create an ECS Task Definition

A Task Definition is a blueprint for your application. It tells ECS which Docker image to use and what environment variables to inject.

1. Navigate to **Amazon ECS** in the AWS Console.
2. On the left sidebar, click **Task definitions**, then **Create new task definition**.
3. **Task definition family**: Enter `ecommerce-etl-task`.
4. **Infrastructure requirements**:
   - Select **AWS Fargate**.
   - Set **Operating system/Architecture** to `Linux/X86_64`.
   - Set **Task size** to `1 vCPU` and `2 GB` of memory (adjust if your ETL needs more power).
5. **Container - 1**:
   - **Name**: `etl-container`
   - **Image URI**: Paste the ECR URI you pushed to in Step 1 (e.g., `123456789012.dkr.ecr.us-east-1.amazonaws.com/ecommerce-etl:latest`).
6. **Environment variables**:
   Add the variables your app needs to connect to the RDS database:
   - `DB_HOST`: your-rds-endpoint.amazonaws.com
   - `DB_PORT`: 5432
   - `DB_NAME`: ecommerce_dw
   - `DB_USER`: postgres
   - `DB_PASSWORD`: your_password *(Note: In a production environment, it's safer to use AWS Secrets Manager for the password by selecting "ValueFrom" instead of "Value")*.
7. Click **Create**.

---

## Step 3: Create an ECS Cluster

1. In the ECS Console, go to **Clusters** and click **Create cluster**.
2. **Cluster name**: `ecommerce-etl-cluster`.
3. Under **Infrastructure**, ensure **AWS Fargate (serverless)** is selected.
4. Click **Create**.

> **Note**: Since this is a batch ETL job, we will NOT create an ECS "Service" (which is meant for long-running web servers). Instead, we will run the Task Definition directly via EventBridge.

---

## Step 4: Schedule the Job with Amazon EventBridge

Now we will create a cron rule to trigger the ECS task automatically.

1. Navigate to **Amazon EventBridge** in the AWS Console.
2. Go to **Rules** and click **Create rule**.
3. **Name**: `Daily-Ecommerce-ETL`.
4. **Rule type**: Select **Schedule**. Click Next.
5. Define your schedule. For example, to run every day at 2:00 AM UTC:
   - Select **A fine-grained schedule**.
   - Cron expression: `0 2 * * ? *`
   - Click Next.
6. **Select Target**:
   - **Target types**: `AWS service`
   - **Select a target**: `ECS task`
   - **Cluster**: Select `ecommerce-etl-cluster`.
   - **Task Definition**: Select `ecommerce-etl-task`.
   - **Compute options**: Select **Fargate**.
7. **Network Configuration**:
   - You must specify the **Subnets** and a **Security Group**.
   - Ensure the selected Subnets and Security Group allow outbound internet access (to download updates) and have network access to your RDS database.
   - **Auto-assign public IP**: `ENABLED` (required for Fargate to pull the image from ECR unless you have a NAT Gateway).
8. Create a new IAM role for this execution if prompted.
9. Click **Next** until you **Create rule**.

---

## Conclusion & Verification

Your serverless ETL architecture is complete! 

**To test it immediately:**
You don't have to wait for the schedule. You can manually run the task to test it:
1. Go to your ECS Cluster (`ecommerce-etl-cluster`).
2. Click the **Tasks** tab, then **Run new task**.
3. Select your `ecommerce-etl-task` definition, configure the networking, and click **Create**.
4. You can click on the running task and view the **Logs** tab to see your ETL pipeline executing live in the cloud.
