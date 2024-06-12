# azure-infrastructure-monitoring-and-logging
Implement a monitoring and logging solution for Azure infrastructure using Azure Monitor, Log Analytics, Docker, Terraform, and Ansible. This project will provision Azure resources, set up monitoring and logging, and ensure consistent configuration and alerting across all resources.

Technologies: Azure Monitor, Azure Log Analytics, Docker, Terraform, Ansible, Python

# Detailed Step-by-Step Process

## Prerequisites
- Azure Subscription
- Installed and configured Terraform
- Installed and configured Ansible
- Installed Docker
- Python environment (if scripting is needed)
- Installed Azure CLI

## Step 1: Infrastructure as Code with Terraform
### 1. Install Terraform
```bash
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform
```
### 2. Create Terraform Configuration File:
Create a file named 'main.tf' with the following content:
``` hcl 
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "monitoring-rg"
  location = "East US"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "monitoring-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "monitoring-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "nic" {
  name                = "monitoring-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "vm" {
  name                  = "monitoring-vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = "Standard_DS1_v2"

  storage_os_disk {
    name              = "osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = "azureuser"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}
```
### 3. Initialize and Apply Terraform Configuration
```bash
terraform init
terraform plan
terraform apply
```
## Step 2: Monitoring Setup
### 1. Create Log Analytics Workspace:
```hcl
resource "azurerm_log_analytics_workspace" "log_analytics" {
  name                = "monitoring-logs"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.log_analytics.id
}
```
### 2. Configure Azure Monitor
```hcl
resource "azurerm_monitor_diagnostic_setting" "monitor" {
  name               = "diag-setting"
  target_resource_id = azurerm_virtual_machine.vm.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics.id

  metric {
    category = "AllMetrics"
    enabled  = true
  }

  log {
    category = "AuditEvent"
    enabled  = true
  }
}
```
### 3. Apply Terraform Configuration for Monitoring
``` bash
terraform apply 
```
## Step 3: Containerization with Docker
### 1. Install Docker on VM:
SSH into your VM and run:
```bash
sudo apt-get update
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
```
### 2. Deploy Monitoring Agent Using Docker:
Create a docker-compose.yml file:
```yaml
version: '3'
services:
  monitoring-agent:
    image: your-monitoring-agent-image
    ports:
      - "8080:8080"
    environment:
      - LOG_ANALYTICS_WORKSPACE_ID=${log_analytics_workspace_id}
      - LOG_ANALYTICS_SHARED_KEY=${log_analytics_shared_key}
```
### 3. Run Docker Container
```bash
docker-compose up -d
```
## Step 4: Configuration Management with Ansible
### 1. Install Ansible
```bash
sudo apt-get update
sudo apt-get install -y ansible
```
### 2.Create Ansible Playbook:
Create a file named playbook.yml
```yaml
- hosts: all
  become: yes
  tasks:
    - name: Ensure Docker is installed
      apt:
        name: docker.io
        state: present

    - name: Start Docker service
      service:
        name: docker
        state: started
        enabled: yes

    - name: Deploy monitoring agent container
      docker_container:
        name: monitoring-agent
        image: your-monitoring-agent-image
        state: started
        restart_policy: always
        ports:
          - "8080:8080"
        env:
          LOG_ANALYTICS_WORKSPACE_ID: "{{ log_analytics_workspace_id }}"
          LOG_ANALYTICS_SHARED_KEY: "{{ log_analytics_shared_key }}"
```
### 3. Run Ansible Playbook:
```bash
ansible-playbook -i 'your-vm-ip,' -u azureuser --private-key=your-key.pem playbook.yml
```
## Step 5: Up Alerting Mechanisms
### 1. Configure Alerts in Azure Monitor
```hcl 
resource "azurerm_monitor_metric_alert" "metric_alert" {
  name                = "example-metric-alert"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_virtual_machine.vm.id]
  description         = "An example metric alert"
  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }
  action {
    action_group_id = azurerm_monitor_action_group.action_group.id
  }
}

resource "azurerm_monitor_action_group" "action_group" {
  name                = "example-action-group"
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "example-action"

  email_receiver {
    name          = "admin"
    email_address = "admin@example.com"
  }
}
```
### 2. Apply Terraform Configuration for Alerting:
```bash 
terraform apply
```











































