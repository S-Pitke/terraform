terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.14.0"
    }
  }
}

provider "azurerm" {
  features {}
  /*subscription_id = "1596e5a4-ada5-4be6-9897-4bdbdd0efbc2"*/
}


/*define resource group*/
resource "azurerm_resource_group" "webapp_rg" {
  name     = var.resource_group_name
  location = var.location

}

/*define virtual network*/
resource "azurerm_virtual_network" "webapp_vnet" {
  name                = var.virtual_network_name
  address_space       = var.address_space
  location            = azurerm_resource_group.webapp_rg.location
  resource_group_name = azurerm_resource_group.webapp_rg.name

}

/*define subnet of virtual network*/

resource "azurerm_subnet" "webapp_subnet" {
  name                 = var.subnet_name
  virtual_network_name = azurerm_virtual_network.webapp_vnet.name
  resource_group_name  = azurerm_resource_group.webapp_rg.name
  address_prefixes     = var.subnet_address_prefixes

}

/* define public ip for load balancer */

resource "azurerm_public_ip" "public_ip" {
  name                = var.public_ip_name
  location            = var.location
  resource_group_name = azurerm_resource_group.webapp_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

}

/* create load balancer */

resource "azurerm_lb" "lb" {
  name                = var.lb_name
  resource_group_name = azurerm_resource_group.webapp_rg.name
  location            = var.location
  sku                 = "Standard"
  frontend_ip_configuration {
    name                 = "FrontendConfig"
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }

}

/* create backend pool for load balancer */
resource "azurerm_lb_backend_address_pool" "backend_pool" {
  name            = var.backend_pool_name
  loadbalancer_id = azurerm_lb.lb.id

}

resource "azurerm_lb_nat_rule" "rdp_nat_rule" {
  resource_group_name = azurerm_resource_group.webapp_rg.name
  loadbalancer_id = azurerm_lb.lb.id
  name = "RDPAccess"
  protocol = "Tcp"
  frontend_port = 50001
  backend_port = 3389
  frontend_ip_configuration_name = "FrontendConfig"
  
}

/* create nsg & security rule */
resource "azurerm_network_security_group" "nsg" {
  name                = var.nsg_name
  resource_group_name = azurerm_resource_group.webapp_rg.name
  location            = var.location

  security_rule {
    name                       = "Allow-RDP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-http"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association" {
    subnet_id = azurerm_subnet.webapp_subnet.id
    network_security_group_id = azurerm_network_security_group.nsg.id
  
}

/* create network interface for vms */
resource "azurerm_network_interface" "nic" {
  name                = "ibm-nic"
  location            = azurerm_resource_group.webapp_rg.location
  resource_group_name = azurerm_resource_group.webapp_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.webapp_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

}

/*nic association with load balancer pool */

resource "azurerm_network_interface_backend_address_pool_association" "nic_lb_association" {
  network_interface_id    = azurerm_network_interface.nic.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id

}

resource "azurerm_lb_probe" "http_probe" {
  name                = "http-probe"
  loadbalancer_id     = azurerm_lb.lb.id
  protocol            = "Tcp"
  port                = 80
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "http_rule" {
  name                           = "http-rule"
  loadbalancer_id                = azurerm_lb.lb.id
  frontend_ip_configuration_name = "FrontendConfig"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend_pool.id]
  probe_id                       = azurerm_lb_probe.http_probe.id
}

/* deploy Vm scale set */
resource "azurerm_windows_virtual_machine_scale_set" "vm_scale_set" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.webapp_rg.name
  location            = var.location
  sku                 = var.vm_size
  instances           = var.instances_count
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface {
    name    = "vmss_nic"
    primary = true
    /* subnet_id = azurerm_subnet.webapp_subnet.id */
    enable_accelerated_networking = true

    ip_configuration {
      name                                   = "ipconfig"
      primary                                = true
      subnet_id                              = azurerm_subnet.webapp_subnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.backend_pool.id]
    }
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter-smalldisk"
    version   = "latest"
  }

  computer_name_prefix = "vm"
}

