resource_group_name     = "web_app"
location                = "West US"
virtual_network_name    = "webapp_vnet"
address_space           = ["192.168.0.0/16"]
subnet_name             = "webapp_subnet"
subnet_address_prefixes = ["192.168.1.0/24"]
lb_name                 = "ibm-lb"
public_ip_name          = "pip-lb"
backend_pool_name       = "ibm-pool"
nsg_name                = "vm-nsg"
instant_count           = 2
vm_name                 = "webapp_vm"
vm_size                 = "Standard_D2s_v3"
admin_username          = "admin100"
admin_password          = "password@1234"
instances_count         = 2

