terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}
terraform {
  backend "azurerm" {
    resource_group_name =
   "StorageAccount-ResourceGroup"
     storage_account_name = "abcd1234"
     container_name = "tfstate"
    key = "prod.terraform.tfstate"
  }
}
# Create a resource group

resource "azurerm_resource_group" "project4RG" {
  name     = "project4RG"
  location = "East US 2"
}

# Create a virtual network within the resource group

resource "azurerm_virtual_network" "project4VN" {
  name                = "project4VN"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.project4RG.location
  resource_group_name = azurerm_resource_group.project4RG.name
}

#Create Subnet to hold the VM

resource "azurerm_subnet" "project4SNet" {
  name                 = "project4SNet"
  resource_group_name  = azurerm_resource_group.project4RG.name
  virtual_network_name = azurerm_virtual_network.project4VN.name
  address_prefixes     = ["10.0.2.0/24"]
}

#Create vNIC for the VM and assign to the VM

resource "azurerm_network_interface" "project4vNIC" {
  name                = "project4vNIC"
  location            = azurerm_resource_group.project4RG.location
  resource_group_name = azurerm_resource_group.project4RG.name

  ip_configuration {
    name                          = "project4IP"
    subnet_id                     = azurerm_subnet.project4SNet.id
    private_ip_address_allocation = "Dynamic"
  }
}

#Create the Virtual Machine 

resource "azurerm_windows_virtual_machine" "example" {
  name                = "project4VM"
  resource_group_name = azurerm_resource_group.project4RG.name
  location            = azurerm_resource_group.project4RG.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd5678!"
  network_interface_ids = [
    azurerm_network_interface.project4vNIC.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}
