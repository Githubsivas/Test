# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used

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

  subscription_id = "d0409fbb-c6e0-4e5a-b6de-3c98429d443b"
  client_id       = "89a72587-31e6-4d50-aa7a-4e2f80bef140"
  client_secret   = "I9J8Q~5DHqffsp5INwIwwV8PIOpZJz3yduEr3aBk"
  tenant_id       = "cd3779f6-2af9-4aee-be9a-45e131119f0b"
}

# Create respurce group

resource "azurerm_resource_group" "rg" {
  name     = "sivarg"
  location = "East US"
}

# Create Virtual Network

resource "azurerm_virtual_network" "vnet" {
  name                = "sivatestvirtualnetwork"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

# Create subnet

resource "azurerm_subnet" "subnet" {
  name                 = "sivasubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create network security group

resource "azurerm_network_security_group" "nsg" {
  name                = "sivatestnetworksecuritygroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create network security rule

resource "azurerm_network_security_rule" "rdp" {
  name                        = "sivansgrule"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_subnet_network_security_group_association" "nsg_subnet_association" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Create NIC

resource "azurerm_network_interface" "nic" {
  name                = "siva_nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create VM

resource "azurerm_windows_virtual_machine" "main" {
  name                = "sivaVM"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_F2"
  admin_username      = "siva"
  admin_password      = "Password@123"
  network_interface_ids = [azurerm_network_interface.nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}