# Components

- AWS CLI V2
- Terraform:
	- Virtual Networks
		○ Private (For DB) and Public Subnet
		○ NAT Gateway
	- InfluxDB
	- Web/Grafana
	- AWS Batch
	- ECR

- Docker:
    - Custom k6 image

# Design Key Features

- AWS Batch uses k6 Docker images to rapidly scale out stress/load testing of target website. AWS Batch automatically provisions the required EC2 instances within the public subnet and runs the required jobs on these instances. The jobs in this case are Docker containers that contain the K6 software and custom scripts needed to test against the website.
- A separate EC2 instance is provisioned in the private subnet. InfluxDB is installed on this instance and it receives data from the K6 jobs.
- Grafana is installed on a public-internet facing EC2 instance and connects to the Influxdb in the private subnet. SSH access to this instance is permitted from the designated `office_ip`.
- A NAT Gateway is used to provide internet connectivity for EC2 instances in the private subnet. 
- Security Groups are used to restrict ingress traffic to Graphana and Influxdb instances. 
- Docker images are stored in an a private ECR repository. AWS Batch, using the default IAM roles, will have access to this repository. 

The rough diagram below depicts the major components of the design. 

- ![Design](./images/k6-aws-batch.png "Rough Design")




# Deploying Infrastructure

```bash
cd terraform/
$IP=$(curl ifconfig.io)
terraform init
terraform plan -var "office_ip=$IP"
terraform apply -var "office_ip=$IP" --auto-approve

# SAVE ECR Repository URL
```

# Creating and Pushing Container

```powershell

# Build docker image locally and test
docker build -t testk6 k6/
docker run testk6 run script.js

# Tag and Push Docker image to ECR
$REGION=<your region>
$ACC_NUMBER=<aws account number>
$ECR_URL="$REGION.dkr.ecr.$REGION.amazonaws.com/k6test"
docker tag testk6 $ECR_URL
$pass=aws ecr get-login-password --region ap-southeast-2
docker login --username AWS --password $pass $ECR_URL
docker push $ECR_URL
```

# Submit a Job to Batch

```bash
# Get Job definitions (JSON)
aws batch describe-job-definitions

# Start a job
aws batch submit-job --job-name test1 --job-queue k6-test-batch-job-queue  --job-definition k6_test_batch_job_definition --array-properties size=10
```

# TODO

- Static Private address for DB
- Update K6_OUT variable with record from private zone
- Move Grafana to an internal only service 
- Setup a Point to Site VPN for admins


# Recommended References

- https://github.com/softrams/k6-docker - for docker-compose setup