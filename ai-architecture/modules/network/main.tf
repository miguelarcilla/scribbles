###############################################################################
# Network layer
# Best-practice subnet design for a network-isolated Microsoft Foundry workload.
# Address space defaults to 192.168.0.0/16 (the Foundry Agent Service delegated
# subnet historically rejected 10.0.0.0/8).
###############################################################################

locals {
  space = var.vnet_address_space

  # Subnet allocation (relative to a /16 base).
  subnet_prefixes = {
    container_apps    = cidrsubnet(local.space, 7, 0)   # 192.168.0.0/23  - app workload (delegated)
    apim              = cidrsubnet(local.space, 8, 2)   # 192.168.2.0/24  - API Management (internal)
    agents_egress     = cidrsubnet(local.space, 8, 3)   # 192.168.3.0/24  - Foundry agent egress (delegated)
    private_endpoints = cidrsubnet(local.space, 8, 4)   # 192.168.4.0/24  - all private endpoints
    data              = cidrsubnet(local.space, 8, 5)   # 192.168.5.0/24  - database tier expansion
    firewall          = cidrsubnet(local.space, 10, 24) # 192.168.6.0/26  - AzureFirewallSubnet
    bastion           = cidrsubnet(local.space, 10, 26) # 192.168.6.128/26 - AzureBastionSubnet
    jumpbox           = cidrsubnet(local.space, 11, 54) # 192.168.6.192/27 - management jump box
    build_agents      = cidrsubnet(local.space, 11, 55) # 192.168.6.224/27 - CI/CD build agents
  }

  # Private DNS zones required for the private endpoints in this architecture.
  private_dns_zones = {
    vault             = "privatelink.vaultcore.azure.net"
    blob              = "privatelink.blob.core.windows.net"
    cosmos_sql        = "privatelink.documents.azure.com"
    cognitiveservices = "privatelink.cognitiveservices.azure.com"
    openai            = "privatelink.openai.azure.com"
    aiservices        = "privatelink.services.ai.azure.com"
    search            = "privatelink.search.windows.net"
    container_apps    = "privatelink.${replace(lower(var.location), " ", "")}.azurecontainerapps.io"
  }
}

resource "azurerm_virtual_network" "this" {
  name                = "vnet-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [local.space]
  tags                = var.tags
}

###############################################################################
# Subnets
###############################################################################

resource "azurerm_subnet" "container_apps" {
  name                            = "ContainerAppsSubnet"
  resource_group_name             = var.resource_group_name
  virtual_network_name            = azurerm_virtual_network.this.name
  address_prefixes                = [local.subnet_prefixes.container_apps]
  default_outbound_access_enabled = false

  delegation {
    name = "Microsoft.App.environments"
    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "apim" {
  name                            = "ApiManagementSubnet"
  resource_group_name             = var.resource_group_name
  virtual_network_name            = azurerm_virtual_network.this.name
  address_prefixes                = [local.subnet_prefixes.apim]
  default_outbound_access_enabled = false
}

resource "azurerm_subnet" "agents_egress" {
  name                            = "AgentsEgressSubnet"
  resource_group_name             = var.resource_group_name
  virtual_network_name            = azurerm_virtual_network.this.name
  address_prefixes                = [local.subnet_prefixes.agents_egress]
  default_outbound_access_enabled = false

  delegation {
    name = "Microsoft.App.environments"
    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "private_endpoints" {
  name                              = "PrivateEndpointsSubnet"
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.this.name
  address_prefixes                  = [local.subnet_prefixes.private_endpoints]
  private_endpoint_network_policies = "Enabled"
  default_outbound_access_enabled   = false
}

resource "azurerm_subnet" "data" {
  name                            = "DataSubnet"
  resource_group_name             = var.resource_group_name
  virtual_network_name            = azurerm_virtual_network.this.name
  address_prefixes                = [local.subnet_prefixes.data]
  default_outbound_access_enabled = false
}

resource "azurerm_subnet" "firewall" {
  name                            = "AzureFirewallSubnet"
  resource_group_name             = var.resource_group_name
  virtual_network_name            = azurerm_virtual_network.this.name
  address_prefixes                = [local.subnet_prefixes.firewall]
  default_outbound_access_enabled = false
}

resource "azurerm_subnet" "bastion" {
  name                            = "AzureBastionSubnet"
  resource_group_name             = var.resource_group_name
  virtual_network_name            = azurerm_virtual_network.this.name
  address_prefixes                = [local.subnet_prefixes.bastion]
  default_outbound_access_enabled = false
}

resource "azurerm_subnet" "jumpbox" {
  name                            = "JumpboxSubnet"
  resource_group_name             = var.resource_group_name
  virtual_network_name            = azurerm_virtual_network.this.name
  address_prefixes                = [local.subnet_prefixes.jumpbox]
  default_outbound_access_enabled = false
}

resource "azurerm_subnet" "build_agents" {
  name                            = "BuildAgentsSubnet"
  resource_group_name             = var.resource_group_name
  virtual_network_name            = azurerm_virtual_network.this.name
  address_prefixes                = [local.subnet_prefixes.build_agents]
  default_outbound_access_enabled = false
}

###############################################################################
# Network security groups
###############################################################################

resource "azurerm_network_security_group" "private_endpoints" {
  name                = "nsg-privateEndpoints-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "DenyAllOutbound"
    description                = "Private endpoints are sinks; they should never originate egress."
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = local.subnet_prefixes.private_endpoints
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "container_apps" {
  name                = "nsg-containerapps-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "Allow.Out.PrivateEndpoints"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = local.subnet_prefixes.container_apps
    destination_address_prefix = local.subnet_prefixes.private_endpoints
  }

  security_rule {
    name                       = "Allow.Out.AzureMonitor"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = local.subnet_prefixes.container_apps
    destination_address_prefix = "AzureMonitor"
  }
}

resource "azurerm_network_security_group" "agents_egress" {
  name                = "nsg-agentsEgress-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow.Out.PrivateEndpoints"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = local.subnet_prefixes.agents_egress
    destination_address_prefix = local.subnet_prefixes.private_endpoints
  }

  security_rule {
    name                       = "Allow.Out.Https.Internet"
    description                = "Egress to internet on 443 - Azure Firewall applies further FQDN filtering."
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = local.subnet_prefixes.agents_egress
    destination_address_prefix = "Internet"
  }
}

resource "azurerm_network_security_group" "apim" {
  name                = "nsg-apim-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "Allow.In.ApimManagement"
    description                = "Required management endpoint for APIM (internal VNet)."
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3443"
    source_address_prefix      = "ApiManagement"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "Allow.In.AzureLoadBalancer"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6390"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "Allow.In.Https"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }
}

resource "azurerm_network_security_group" "bastion" {
  name                = "nsg-bastion-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "Allow.In.Https.Internet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow.In.GatewayManager"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow.In.AzureLoadBalancer"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow.In.BastionDataPlane"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["8080", "5701"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "Allow.Out.Ssh.Rdp.VNet"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "3389"]
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "Allow.Out.AzureCloud.Https"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }

  security_rule {
    name                       = "Allow.Out.Internet.Http"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }
}

resource "azurerm_network_security_group" "management" {
  name                = "nsg-management-${var.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "Allow.In.Bastion"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "3389"]
    source_address_prefix      = local.subnet_prefixes.bastion
    destination_address_prefix = "*"
  }
}

# NSG associations
resource "azurerm_subnet_network_security_group_association" "private_endpoints" {
  subnet_id                 = azurerm_subnet.private_endpoints.id
  network_security_group_id = azurerm_network_security_group.private_endpoints.id
}

resource "azurerm_subnet_network_security_group_association" "container_apps" {
  subnet_id                 = azurerm_subnet.container_apps.id
  network_security_group_id = azurerm_network_security_group.container_apps.id
}

resource "azurerm_subnet_network_security_group_association" "agents_egress" {
  subnet_id                 = azurerm_subnet.agents_egress.id
  network_security_group_id = azurerm_network_security_group.agents_egress.id
}

resource "azurerm_subnet_network_security_group_association" "apim" {
  subnet_id                 = azurerm_subnet.apim.id
  network_security_group_id = azurerm_network_security_group.apim.id
}

resource "azurerm_subnet_network_security_group_association" "bastion" {
  subnet_id                 = azurerm_subnet.bastion.id
  network_security_group_id = azurerm_network_security_group.bastion.id
}

resource "azurerm_subnet_network_security_group_association" "jumpbox" {
  subnet_id                 = azurerm_subnet.jumpbox.id
  network_security_group_id = azurerm_network_security_group.management.id
}

resource "azurerm_subnet_network_security_group_association" "build_agents" {
  subnet_id                 = azurerm_subnet.build_agents.id
  network_security_group_id = azurerm_network_security_group.management.id
}

###############################################################################
# Azure Firewall - inspects/filters all egress from the agent + compute tiers
###############################################################################

# resource "azurerm_public_ip" "firewall" {
#   name                = "pip-fw-${var.name_suffix}"
#   location            = var.location
#   resource_group_name = var.resource_group_name
#   allocation_method   = "Static"
#   sku                 = "Standard"
#   zones               = ["1", "2", "3"]
#   tags                = var.tags
# }

# resource "azurerm_firewall_policy" "this" {
#   name                = "afwp-${var.name_suffix}"
#   location            = var.location
#   resource_group_name = var.resource_group_name
#   sku                 = "Standard"
#   tags                = var.tags
# }

# resource "azurerm_firewall_policy_rule_collection_group" "egress" {
#   name               = "egress-rules"
#   firewall_policy_id = azurerm_firewall_policy.this.id
#   priority           = 500

#   application_rule_collection {
#     name     = "allow-ai-egress"
#     priority = 500
#     action   = "Allow"

#     rule {
#       name = "allow-microsoft-and-ai-fqdns"
#       protocols {
#         type = "Https"
#         port = 443
#       }
#       source_addresses = [
#         local.subnet_prefixes.agents_egress,
#         local.subnet_prefixes.container_apps,
#       ]
#       destination_fqdns = [
#         "*.openai.azure.com",
#         "*.cognitiveservices.azure.com",
#         "*.services.ai.azure.com",
#         "*.search.windows.net",
#         "login.microsoftonline.com",
#         "management.azure.com",
#         "*.blob.core.windows.net",
#         "*.documents.azure.com",
#       ]
#     }
#   }
# }

# resource "azurerm_firewall" "this" {
#   name                = "afw-${var.name_suffix}"
#   location            = var.location
#   resource_group_name = var.resource_group_name
#   sku_name            = "AZFW_VNet"
#   sku_tier            = "Standard"
#   firewall_policy_id  = azurerm_firewall_policy.this.id
#   zones               = ["1", "2", "3"]
#   tags                = var.tags

#   ip_configuration {
#     name                 = "fw-ipconfig"
#     subnet_id            = azurerm_subnet.firewall.id
#     public_ip_address_id = azurerm_public_ip.firewall.id
#   }
# }

###############################################################################
# Egress route table - forces compute/agent egress through the firewall
###############################################################################

# resource "azurerm_route_table" "egress" {
#   name                = "rt-egress-${var.name_suffix}"
#   location            = var.location
#   resource_group_name = var.resource_group_name
#   tags                = var.tags

#   route {
#     name                   = "default-to-firewall"
#     address_prefix         = "0.0.0.0/0"
#     next_hop_type          = "VirtualAppliance"
#     next_hop_in_ip_address = azurerm_firewall.this.ip_configuration[0].private_ip_address
#   }
# }

# resource "azurerm_subnet_route_table_association" "agents_egress" {
#   subnet_id      = azurerm_subnet.agents_egress.id
#   route_table_id = azurerm_route_table.egress.id
# }

# resource "azurerm_subnet_route_table_association" "container_apps" {
#   subnet_id      = azurerm_subnet.container_apps.id
#   route_table_id = azurerm_route_table.egress.id
# }

# resource "azurerm_subnet_route_table_association" "build_agents" {
#   subnet_id      = azurerm_subnet.build_agents.id
#   route_table_id = azurerm_route_table.egress.id
# }

###############################################################################
# Private DNS zones (one per private-linked service) + VNet links
###############################################################################

resource "azurerm_private_dns_zone" "this" {
  for_each            = local.private_dns_zones
  name                = each.value
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each              = local.private_dns_zones
  name                  = "link-${each.key}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this[each.key].name
  virtual_network_id    = azurerm_virtual_network.this.id
  registration_enabled  = false
  tags                  = var.tags
}
