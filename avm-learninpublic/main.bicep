param virtualNetworks_anarcill_network_hub_vnet_name string
param networkSecurityGroups_anarcill_network_hub_vnet_default_nsg_southeastasia_externalid string
param natGateways_anarcill_network_hub_vnet_natgw_externalid string
param virtualNetworks_anarcill_network_spoke_eastus2_vnet_externalid string
param virtualNetworks_anarcill_network_spoke_eastus_vnet_externalid string

resource virtualNetworks_anarcill_network_hub_vnet_name_resource 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: virtualNetworks_anarcill_network_hub_vnet_name
  location: 'southeastasia'
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    encryption: {
      enabled: true
      enforcement: 'AllowUnencrypted'
    }
    privateEndpointVNetPolicies: 'Disabled'
    dhcpOptions: {
      dnsServers: []
    }
    subnets: [
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.0.2.0/24'
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          defaultOutboundAccess: false
        }
      }
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: networkSecurityGroups_anarcill_network_hub_vnet_default_nsg_southeastasia_externalid
          }
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          defaultOutboundAccess: false
        }
      }
      {
        name: 'PublicSubnet'
        properties: {
          addressPrefix: '10.0.3.0/24'
          networkSecurityGroup: {
            id: networkSecurityGroups_anarcill_network_hub_vnet_default_nsg_southeastasia_externalid
          }
          natGateway: {
            id: natGateways_anarcill_network_hub_vnet_natgw_externalid
          }
          delegations: [
            {
              name: 'Microsoft.ApiManagement/service'
              properties: {
                serviceName: 'Microsoft.ApiManagement/service'
              }
            }
          ]
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          defaultOutboundAccess: false
        }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.0.4.0/26'
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          defaultOutboundAccess: false
        }
      }
      {
        name: 'AzureFirewallManagementSubnet'
        properties: {
          addressPrefix: '10.0.4.64/26'
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          defaultOutboundAccess: false
        }
      }
    ]
    virtualNetworkPeerings: [
      {
        name: 'hub-to-spoke-eastus2'
        properties: {
          peeringState: 'Connected'
          peeringSyncLevel: 'FullyInSync'
          remoteVirtualNetwork: {
            id: virtualNetworks_anarcill_network_spoke_eastus2_vnet_externalid
          }
          allowVirtualNetworkAccess: true
          allowForwardedTraffic: true
          allowGatewayTransit: true
          useRemoteGateways: false
          doNotVerifyRemoteGateways: false
          peerCompleteVnets: true
          remoteAddressSpace: {
            addressPrefixes: [
              '10.1.0.0/16'
            ]
          }
          remoteVirtualNetworkAddressSpace: {
            addressPrefixes: [
              '10.1.0.0/16'
            ]
          }
        }
      }
      {
        name: 'hub-to-spoke-eastus'
        properties: {
          peeringState: 'Connected'
          peeringSyncLevel: 'FullyInSync'
          remoteVirtualNetwork: {
            id: virtualNetworks_anarcill_network_spoke_eastus_vnet_externalid
          }
          allowVirtualNetworkAccess: true
          allowForwardedTraffic: true
          allowGatewayTransit: true
          useRemoteGateways: false
          doNotVerifyRemoteGateways: false
          peerCompleteVnets: true
          remoteAddressSpace: {
            addressPrefixes: [
              '10.3.0.0/16'
            ]
          }
          remoteVirtualNetworkAddressSpace: {
            addressPrefixes: [
              '10.3.0.0/16'
            ]
          }
        }
      }
    ]
    enableDdosProtection: false
  }
}

resource virtualNetworks_anarcill_network_hub_vnet_name_AzureFirewallManagementSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' = {
  parent: virtualNetworks_anarcill_network_hub_vnet_name_resource
  name: 'AzureFirewallManagementSubnet'
  properties: {
    addressPrefix: '10.0.4.64/26'
    delegations: []
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    defaultOutboundAccess: false
  }
}

resource virtualNetworks_anarcill_network_hub_vnet_name_AzureFirewallSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' = {
  parent: virtualNetworks_anarcill_network_hub_vnet_name_resource
  name: 'AzureFirewallSubnet'
  properties: {
    addressPrefix: '10.0.4.0/26'
    delegations: []
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    defaultOutboundAccess: false
  }
}

resource virtualNetworks_anarcill_network_hub_vnet_name_default 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' = {
  parent: virtualNetworks_anarcill_network_hub_vnet_name_resource
  name: 'default'
  properties: {
    addressPrefix: '10.0.0.0/24'
    networkSecurityGroup: {
            id: networkSecurityGroups_anarcill_network_hub_vnet_default_nsg_southeastasia_externalid
    }
    delegations: []
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    defaultOutboundAccess: false
  }
}

resource virtualNetworks_anarcill_network_hub_vnet_name_GatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' = {
  parent: virtualNetworks_anarcill_network_hub_vnet_name_resource
  name: 'GatewaySubnet'
  properties: {
    addressPrefix: '10.0.2.0/24'
    delegations: []
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    defaultOutboundAccess: false
  }
}

resource virtualNetworks_anarcill_network_hub_vnet_name_PublicSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' = {
  parent: virtualNetworks_anarcill_network_hub_vnet_name_resource
  name: 'PublicSubnet'
  properties: {
    addressPrefix: '10.0.3.0/24'
    networkSecurityGroup: {
      id: networkSecurityGroups_anarcill_network_hub_vnet_default_nsg_southeastasia_externalid
    }
    delegations: [ {
        name: 'Microsoft.ApiManagement/service'
        id: '/delegations/Microsoft.ApiManagement/service'
        properties: {
          serviceName: 'Microsoft.ApiManagement/service'
        }
      }
    ]
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    defaultOutboundAccess: false
  }
}

resource virtualNetworks_anarcill_network_hub_vnet_name_hub_to_spoke_eastus 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-07-01' = {
  parent: virtualNetworks_anarcill_network_hub_vnet_name_resource
  name: 'hub-to-spoke-eastus'
  properties: {
    peeringState: 'Connected'
    peeringSyncLevel: 'FullyInSync'
    remoteVirtualNetwork: {
      id: virtualNetworks_anarcill_network_spoke_eastus_vnet_externalid
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    doNotVerifyRemoteGateways: false
    peerCompleteVnets: true
    remoteAddressSpace: {
      addressPrefixes: [
        '10.3.0.0/16'
      ]
    }
    remoteVirtualNetworkAddressSpace: {
      addressPrefixes: [
        '10.3.0.0/16'
      ]
    }
  }
}

resource virtualNetworks_anarcill_network_hub_vnet_name_hub_to_spoke_eastus2 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-07-01' = {
  parent: virtualNetworks_anarcill_network_hub_vnet_name_resource
  name: 'hub-to-spoke-eastus2'
  properties: {
    peeringState: 'Connected'
    peeringSyncLevel: 'FullyInSync'
    remoteVirtualNetwork: {
      id: virtualNetworks_anarcill_network_spoke_eastus2_vnet_externalid
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    doNotVerifyRemoteGateways: false
    peerCompleteVnets: true
    remoteAddressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
    remoteVirtualNetworkAddressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
  }
}
