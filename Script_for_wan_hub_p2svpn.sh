#!/bin/bash

# Variables
location="eastus"  # Change to your preferred region
resourceGroupName="MyResourceGroup"
virtualWANName="MyVirtualWAN"
virtualHubName="MyVirtualHub"
gatewayName="MyP2SGateway"
gatewaySku="VpnGw1"  # Change SKU as needed (e.g., VpnGw2)
clientAddressPool="172.16.0.0/24"  # IP address range for VPN clients
vpnProtocol="OpenVPN"  # Use OpenVPN or IKEv2
rootCertName="MyRootCert"  # Name of the root certificate
rootCertData="MIIC..."  # Base64-encoded root certificate data (no line breaks)
outputFile="vpnconfig.zip"

# Create a resource group
az group create --name $resourceGroupName --location $location

# Create the Azure Virtual WAN
az network vwan create \
  --resource-group $resourceGroupName \
  --name $virtualWANName \
  --location $location \
  --type "Standard"  # or "Basic"

# Create the Virtual Hub
az network vhub create \
  --resource-group $resourceGroupName \
  --name $virtualHubName \
  --address-prefix "10.0.0.0/16"  # Adjust as needed
  --vwan $virtualWANName \
  --location $location

# Create the P2S VPN Gateway
az network vpn-gateway create \
  --resource-group $resourceGroupName \
  --name $gatewayName \
  --vhub $virtualHubName \
  --location $location \
  --scale-unit 1 \
  --vpn-gateway-generation Generation1 \
  --gateway-sku $gatewaySku \
  --client-protocol $vpnProtocol \
  --client-address-pool $clientAddressPool \
  --root-certificates name=$rootCertName cer=$rootCertData

# Download the VPN client configuration
az network vpn-gateway vpn-client generate \
  --resource-group $resourceGroupName \
  --name $gatewayName \
  --processor-arch AMD64 \
  --authentication-method EAPTLS \
  --output-file $outputFile

# Output the location of the downloaded file
echo "VPN client configuration downloaded to $outputFile"
