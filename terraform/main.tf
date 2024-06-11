provider "azurerm" {
  features {
    
  }
}

resource "azurerm_resource_group" "rg" {
  name = "monitoring-rg"
  location = "East US"
}

resource "azurerm_virtual_network" "vnet" {
  name = "monitoring-vnet"
  address_space = ["10.0.0.0/16"]
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  depends_on = [ azurerm_resource_group.rg ]
}

resource "azurerm_subnet" "subnet" {
  name = "monitoring-subnet"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.0.1.0/24"]

  depends_on = [ azurerm_virtual_network.vnet ]
}

resource "azurerm_network_interface" "nic" {
  name = "monitoring-nic"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name = "internal"
    subnet_id = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [ azurerm_subnet.subnet ]
}

resource "azurerm_linux_virtual_machine" "vm" {
  name = "monitoring-vm"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size = "Standard_B1s"
  admin_username = "azureuser"
  network_interface_ids = [azurerm_network_interface.nic]
  admin_ssh_key {
    username = "azureuser"
    public_key = file("~/.shh/id_rsa.pub")
  }

  os_disk {
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "18.04-LTS"
    version = "latest"
  }

  depends_on = [ azurerm_network_interface.nic ]
}

resource "azurerm_log_analytics_workspace" "log_analytics" {
  name = "monitoring-law"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku = "PerGB2018"
  retention_in_days = 30

  depends_on = [ azurerm_resource_group.rg ]
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.log_analytics.id
}

output "log_analytics_primary_shared_key" {
  value = azurerm_log_analytics_workspace.log_analytics.primary_shared_key
}