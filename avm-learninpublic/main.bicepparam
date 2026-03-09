using './main.bicep'

param virtualNetworks_anarcill_network_hub_vnet_name = 'replace-with-vnet-name'
param networkSecurityGroups_anarcill_network_hub_vnet_AzureBastionSubnet_nsg_southeastasia_externalid = '/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Network/networkSecurityGroups/<bastion-subnet-nsg-name>'
param networkSecurityGroups_anarcill_network_hub_vnet_default_nsg_southeastasia_externalid = '/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Network/networkSecurityGroups/<default-subnet-nsg-name>'
param natGateways_anarcill_network_hub_vnet_natgw_externalid = '/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Network/natGateways/<nat-gateway-name>'
param virtualNetworks_anarcill_network_spoke_eastus2_vnet_externalid = '/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Network/virtualNetworks/<spoke-eastus2-vnet-name>'
param virtualNetworks_anarcill_network_spoke_eastus_vnet_externalid = '/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Network/virtualNetworks/<spoke-eastus-vnet-name>'
