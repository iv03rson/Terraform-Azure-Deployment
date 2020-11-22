provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "TerraformRG" {
  name     = var.resourceGroupName
  location = var.location
}
resource "azurerm_storage_account" "labstorage" {
  name                     = "mssastorage10"
  resource_group_name      = var.resourceGroupName
  location                 = var.location
  account_tier             = "Premium"
  access_tier              = "Hot"
  account_replication_type = "LRS"
}

resource "azurerm_public_ip" "WebappIP24" {
  name                = "WebappIP24"
  resource_group_name = var.resourceGroupName
  location            = var.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_security_group" "TestNSG1" {
  name                = "TestNSG1"
  location            = var.location
  resource_group_name = var.resourceGroupName
}

resource "azurerm_network_security_rule" "Rules" {
  name                        = "Rules"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22-3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  description                 = "Allow ports 22,80,3389"  
  resource_group_name         = var.resourceGroupName
  network_security_group_name = var.networksecurityGroupName
}
#Virtual Network Setup 
resource "azurerm_virtual_network" "WebAppVNET-TF"{
  name                = "WebAppVNET-TF"
  location            = var.location
  resource_group_name = var.resourceGroupName
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "Frontend" {
    name           = "Frontend"
    resource_group_name = var.resourceGroupName
    virtual_network_name     = "WebAppVNET-TF" 
    address_prefixes = ["10.0.1.0/24"]
}

 resource "azurerm_subnet" "Backend" {
    name           = "Backend"
    resource_group_name = var.resourceGroupName
    virtual_network_name     = "WebAppVNET-TF"
    address_prefixes = ["10.0.2.0/24"]
  }

  resource "azurerm_subnet" "Firewall" {
    name           = "Firewall"
    address_prefixes = ["10.0.3.0/24"]
    resource_group_name = var.resourceGroupName
    virtual_network_name     = "WebAppVNET-TF"
  }  

resource "azurerm_network_interface" "MyNicName" {
  name                = "MyNicName"
  location            = var.location
  resource_group_name = var.resourceGroupName
  
  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.Frontend.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "AssociatedNSG" {
  network_interface_id      = azurerm_network_interface.MyNicName.id
  network_security_group_id = azurerm_network_security_group.TestNSG1.id
}
# Virtual Machine setup
resource "azurerm_windows_virtual_machine" "OptimusPrime" {
  name                = "OptimusPrime"
  resource_group_name = var.resourceGroupName
  location            = var.location
  size                = "Standard_DS1_v2"
  admin_username      = "azureuser"
  admin_password      = "1q2w3e4r!Q@W#E$R"
  network_interface_ids = [
    azurerm_network_interface.MyNicName.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}
output name {
  value       = "*"
  sensitive   = false
  description = "output"
}
