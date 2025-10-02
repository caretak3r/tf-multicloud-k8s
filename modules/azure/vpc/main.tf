# Data source for existing VNet when create_vpc = false
data "azurerm_virtual_network" "existing" {
  count               = var.create_vpc ? 0 : 1
  name                = split("/", var.vpc_id)[8]
  resource_group_name = split("/", var.vpc_id)[4]
}

data "azurerm_subnet" "existing" {
  count                = var.create_vpc ? 0 : 1
  name                 = split("/", var.subnet_id)[10]
  virtual_network_name = split("/", var.subnet_id)[8]
  resource_group_name  = split("/", var.subnet_id)[4]
}

# Resource group (only when creating new VPC)
resource "azurerm_resource_group" "main" {
  count    = var.create_vpc ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  count               = var.create_vpc ? 1 : 0
  name                = "${var.name_prefix}-vnet"
  address_space       = [var.vnet_cidr]
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  depends_on = [azurerm_resource_group.main]
}

# Private subnet for AKS
resource "azurerm_subnet" "aks" {
  count                = var.create_vpc ? 1 : 0
  name                 = "${var.name_prefix}-aks-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main[0].name
  address_prefixes     = [var.aks_subnet_cidr]
  
  # Disable private endpoint network policies for AKS
  private_endpoint_network_policies = "Disabled"
  
  # Service endpoints for secure access to Azure services
  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.ContainerRegistry",
    "Microsoft.Sql"
  ]
}

# Private subnet for other workloads
resource "azurerm_subnet" "private" {
  count                = var.create_vpc ? 1 : 0
  name                 = "${var.name_prefix}-private-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main[0].name
  address_prefixes     = [var.private_subnet_cidr]
  
  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.ContainerRegistry"
  ]
}

# Bastion subnet (if enabled)
resource "azurerm_subnet" "bastion" {
  count                = var.create_vpc && var.enable_bastion ? 1 : 0
  name                 = "AzureBastionSubnet" # Must be this exact name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main[0].name
  address_prefixes     = [var.bastion_subnet_cidr]
}

# NAT Gateway Public IP
resource "azurerm_public_ip" "nat" {
  count               = var.create_vpc && var.enable_nat_gateway ? 1 : 0
  name                = "${var.name_prefix}-nat-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

# NAT Gateway
resource "azurerm_nat_gateway" "main" {
  count                   = var.create_vpc && var.enable_nat_gateway ? 1 : 0
  name                    = "${var.name_prefix}-nat-gateway"
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  zones                   = ["1", "2", "3"]
  tags                    = var.tags
}

# Associate NAT Gateway with Public IP
resource "azurerm_nat_gateway_public_ip_association" "main" {
  count                = var.create_vpc && var.enable_nat_gateway ? 1 : 0
  nat_gateway_id       = azurerm_nat_gateway.main[0].id
  public_ip_address_id = azurerm_public_ip.nat[0].id
}

# Associate NAT Gateway with AKS subnet
resource "azurerm_subnet_nat_gateway_association" "aks" {
  count          = var.create_vpc && var.enable_nat_gateway ? 1 : 0
  subnet_id      = azurerm_subnet.aks[0].id
  nat_gateway_id = azurerm_nat_gateway.main[0].id
}

# Associate NAT Gateway with private subnet
resource "azurerm_subnet_nat_gateway_association" "private" {
  count          = var.create_vpc && var.enable_nat_gateway ? 1 : 0
  subnet_id      = azurerm_subnet.private[0].id
  nat_gateway_id = azurerm_nat_gateway.main[0].id
}

# Network Security Group for AKS
resource "azurerm_network_security_group" "aks" {
  count               = var.create_vpc ? 1 : 0
  name                = "${var.name_prefix}-aks-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Associate NSG with AKS subnet
resource "azurerm_subnet_network_security_group_association" "aks" {
  count                     = var.create_vpc ? 1 : 0
  subnet_id                 = azurerm_subnet.aks[0].id
  network_security_group_id = azurerm_network_security_group.aks[0].id
}

# Private DNS Zone for AKS
resource "azurerm_private_dns_zone" "aks" {
  count               = var.create_vpc && var.create_private_dns_zone ? 1 : 0
  name                = "privatelink.${var.location}.azmk8s.io"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Link Private DNS Zone to Virtual Network
resource "azurerm_private_dns_zone_virtual_network_link" "aks" {
  count                 = var.create_vpc && var.create_private_dns_zone ? 1 : 0
  name                  = "${var.name_prefix}-aks-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.aks[0].name
  virtual_network_id    = azurerm_virtual_network.main[0].id
  tags                  = var.tags
}

# Azure Bastion (if enabled)
resource "azurerm_public_ip" "bastion" {
  count               = var.create_vpc && var.enable_bastion ? 1 : 0
  name                = "${var.name_prefix}-bastion-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_bastion_host" "main" {
  count               = var.create_vpc && var.enable_bastion ? 1 : 0
  name                = "${var.name_prefix}-bastion"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion[0].id
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }

  tags = var.tags
}

# Log Analytics Workspace (if enabled)
resource "azurerm_log_analytics_workspace" "main" {
  count               = var.create_vpc && var.enable_log_analytics ? 1 : 0
  name                = "${var.name_prefix}-law"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = var.tags
}