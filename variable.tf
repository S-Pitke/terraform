variable "resource_group_name" {
  description = "name of the resource group"

}

variable "location" {
  description = "location of that resource group"

}

variable "virtual_network_name" {
  description = "name of virtual network"

}

variable "address_space" {
  description = "address space for virtual network"

}

variable "subnet_name" {
  description = "name of subnet"

}

variable "subnet_address_prefixes" {
  description = "address prefixes for subnet"

}
variable "public_ip_name" {
  description = "defined load balancer public ip"

}

variable "lb_name" {
  description = "define load balancer name"

}

variable "backend_pool_name" {
  description = "define backend pool name for that lb"

}
variable "nsg_name" {

}
variable "instant_count" {
  description = "define the number of instant count"

}
variable "vm_name" {
  description = "define the vm name"

}

variable "vm_size" {
  description = "define the size of vm"

}

variable "instances_count" {

}

variable "admin_username" {

}

variable "admin_password" {

}



