#!/bin/bash

# This script sets up the environment and deploys the infrastructure

# Ensure Azure CLI is installed
if ! command -v az &> /dev/null
then
    echo "Azure CLI could not ne found. Installing..."
    curl -sL https://aka.ms/aka.ms/InstallAzureCLIDeb | sudo bash
fi

# Login to Azure
az login

# Navigate to the terraform directory
cd ../terraform

# Initialize and apply Terraform
terraform init
terraform apply -auto-approve

# Extract values from Terraform output
LOG_ANALYTICS_WORKSPACE_ID=$(terraform output -raw log_analytics_workspace_id)
LOG_ANALYTICS_SHARED_KEY=$(terraform output -raw log_analytics_primary_shared_key)

# Navigate to the ansible directory
cd ../ansible

# Write to the extracted values to Ansible group varibles
cat <<EOL > group_vars/all.yml
log_analytics_workspace_id: $LOG_ANALYTICS_WORKSPACE_ID
log_analytics_shared_key: $LOG_ANALYTICS_SHARED_KEY
EOL

# Run the Ansible playbook
ansible-playbook -i inventory playbook.yml

# Navigate to the docker directory
cd ../docker

# Create a .env file for Docker Compose
cat <<EOL > .env
LOG_ANALYTICS_WORKSPACE_ID=$LOG_ANALYTICS_WORKSAPCE_ID
LOG_ANALYTICS_SHARED_KEY=$LOG_ANALYTICS_SHARED_KEY
EOL

# Deploy Docker containers
docker-compose up -d