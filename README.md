# Azure-Networking-and-infrastructure
## I tried to use all major networking services in this enterprises grade project. Services used in this lab include Azure WAN, Hub, Azure firewall, Virtual Networks, Virtual Machines, Peerings, Azure app gateway, Azure Load Balancer, Firewall Policy, Storage accounts, Private Endpoint, DNS resolvers, Private DNS zones, P2s VPNS and more
![Exported-Diagram (2)](https://github.com/user-attachments/assets/7773146a-9334-4ca4-81dd-f4b18be3454c)
## 1.I first created the root certificate that will be used to configure P2S vpn. This can created using certmgr. Use the New-SelfSignedCertificate cmdlet to create a self-signed root certificate. 
```bash
ls -l
cd /path/to/directory
grep 'search_term' file.txt
$params = @{
    Type = 'Custom'
    Subject = 'CN=P2SRootCert'
    KeySpec = 'Signature'
    KeyExportPolicy = 'Exportable'
    KeyUsage = 'CertSign'
    KeyUsageProperty = 'Sign'
    KeyLength = 2048
    HashAlgorithm = 'sha256'
    NotAfter = (Get-Date).AddMonths(24)
    CertStoreLocation = 'Cert:\CurrentUser\My'
}
$cert = New-SelfSignedCertificate @params
2. Generate client certificate 
$params = @{
       Type = 'Custom'
       Subject = 'CN=P2SChildCert'
       DnsName = 'P2SChildCert'
       KeySpec = 'Signature'
       KeyExportPolicy = 'Exportable'
       KeyLength = 2048
       HashAlgorithm = 'sha256'
       NotAfter = (Get-Date).AddMonths(18)
       CertStoreLocation = 'Cert:\CurrentUser\My'
       Signer = $cert
       TextExtension = @(
        '2.5.29.37={text}1.3.6.1.5.5.7.3.2')
   }
   New-SelfSignedCertificate @params
```

   
## 3. Export the root certificate in base 64 format and copy its value and will be needed at the creation time when configuring P2S from azure
## 4. install the client certificate on any computer that needs access
## 5  While creatting hub use the key extrated from root certificate and add in the approporaite place in p2s option
## 6. Download the settings from vpn settings and install on the computer that needs to connect
## 7. create several different vnets that will peer to hub. Later go to virtual networks in WAN and add peering from there
## 8. Check p2s machine is pinging the machine which is peered using ping command. You might have to disable firewall in windows machine for this.
## 9. I deployed the azure application gateway behind vnet experimental and added two machines in the vnet in the backend pool. I also added the waf firewall and a policy with that
## 10.
```bash
#!/bin/bash

# Variables
RESOURCE_GROUP="MyResourceGroup"
LOCATION="eastus"
VNET_NAME="MyVNet"  # Existing VNet
SUBNET_NAME="AppGatewaySubnet"  # Existing subnet in the VNet
APP_GATEWAY_NAME="MyAppGateway"
PUBLIC_IP_NAME="MyPublicIP"
WAF_POLICY_NAME="MyWAFPolicy"
HTTP_SETTINGS_NAME="MyHttpSettings"
FRONTEND_IP_NAME="MyFrontendIP"
LISTENER_NAME="MyListener"
ROUTING_RULE_NAME="MyRoutingRule"
SSL_CERT_NAME="MySSLCert"
CERT_FILE_PATH="/path/to/your/certificate.pfx"
CERT_PASSWORD="YourPassword"

# Create Public IP Address
az network public-ip create --resource-group $RESOURCE_GROUP --name $PUBLIC_IP_NAME --allocation-method Static

# Create Application Gateway
az network application-gateway create \
  --resource-group $RESOURCE_GROUP \
  --name $APP_GATEWAY_NAME \
  --location $LOCATION \
  --sku Standard_v2 \
  --capacity 2 \
  --http-settings-cookie-based-affinity Disabled \
  --frontend-port 80 \
  --backend-pool-name MyBackendPool \
  --backend-addresses "10.0.1.4" "10.0.1.5" \
  --http-settings-name $HTTP_SETTINGS_NAME \
  --http-settings-port 80 \
  --http-settings-protocol Http \
  --frontend-ip-name $FRONTEND_IP_NAME \
  --public-ip-address $PUBLIC_IP_NAME \
  --subnet $VNET_NAME/$SUBNET_NAME \
  --routing-rule-name $ROUTING_RULE_NAME \
  --listener-name $LISTENER_NAME \
  --redirect-config-name MyRedirectConfig

# Create WAF Policy
az network application-gateway waf-policy create \
  --resource-group $RESOURCE_GROUP \
  --name $WAF_POLICY_NAME \
  --location $LOCATION

# Add Custom WAF Rules (example)
az network application-gateway waf-policy rule collection add \
  --resource-group $RESOURCE_GROUP \
  --policy-name $WAF_POLICY_NAME \
  --rule-collection-name Default \
  --name MyRuleCollection \
  --rule-type MatchRule \
  --match-conditions "field=RequestHeaders,operator=Contains,value=MyHeader" \
  --action Allow \
  --priority 1

# Associate WAF Policy with Application Gateway
az network application-gateway update \
  --resource-group $RESOURCE_GROUP \
  --name $APP_GATEWAY_NAME \
  --waf-policy $WAF_POLICY_NAME

# Configure SSL Termination (optional, if using SSL)
az network application-gateway ssl-cert create \
  --resource-group $RESOURCE_GROUP \
  --gateway-name $APP_GATEWAY_NAME \
  --name $SSL_CERT_NAME \
  --cert-file $CERT_FILE_PATH \
  --cert-password $CERT_PASSWORD

az network application-gateway listener update \
  --resource-group $RESOURCE_GROUP \
  --gateway-name $APP_GATEWAY_NAME \
  --name $LISTENER_NAME \
  --ssl-cert $SSL_CERT_NAME

echo "Application Gateway and WAF Policy have been created and configured successfully."
```
11.on one of the backend machines i used the steps to manuallt add the server role and used it to host web server which is default in windows server
12 on the second machine i used the script below to added the config to dislay vm name when using app gateway.
```bash
Set-AzVMExtension -ResourceGroupName exp2_group -ExtensionName IIS -VMName exp2 -Publisher Microsoft.Compute -ExtensionType CustomScriptExtension -TypeHandlerVersion 1.4 -SettingString '{"commandToExecute":"powershell Add-WindowsFeature Web-Server; powershell Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value $($env:computername)"}' -Location CentralIndia
```
## 13.Next i made some custom rules and try to block traffic from certian ip address and certian regions using WAF custom rules and changed the mode to prevention mode from detection mode.
## 14.A standard virtual hub has no built-in security policies to protect the resources in spoke virtual networks. A secured virtual hub uses Azure Firewall or a third-party provider to manage incoming and outgoing traffic to protect your resources in Azure. So i deployed an azure firewall in the hub to make it a secured hub.
## 15. Before enabling the firewall all routes are allowed to all peered networks but after the firewall is deployed only the explicitly allowed connections are able to connect
## 16. Using the firewall manager> secured hub> security configurations i changed the private traffic to go through firewall.
## 17 I made a firewall policy using the network rules to allow P2S user to communicate with business only vm. Nobdy else from the peered networks can connect to business VM now.
## 18.Associalted the policy with the Hub in firewall manager
## 19. Next i put load balancer to manange the TCP/IP request to Businees only vms
```bash
#!/bin/bash

# Variables
RESOURCE_GROUP="MyResourceGroup"
LOCATION="eastus"
VNET_NAME="MyVNet"  # Existing VNet
SUBNET_NAME="MySubnet"  # Existing subnet in the VNet
LOAD_BALANCER_NAME="MyLoadBalancer"
PRIVATE_IP_ADDRESS="10.0.1.4"  # Private IP address for the frontend IP configuration
BACKEND_POOL_NAME="MyBackendPool"
HTTP_SETTINGS_NAME="MyHttpSettings"
PROBE_NAME="MyHealthProbe"
RULE_NAME="MyLoadBalancingRule"
LOAD_BALANCER_FRONTEND_NAME="MyFrontendIP"
LOAD_BALANCER_BACKEND_NAME="MyBackendAddressPool"

# Create a Private IP Frontend Configuration
az network lb frontend-ip create \
  --resource-group $RESOURCE_GROUP \
  --lb-name $LOAD_BALANCER_NAME \
  --name $LOAD_BALANCER_FRONTEND_NAME \
  --private-ip-address $PRIVATE_IP_ADDRESS \
  --subnet $VNET_NAME/$SUBNET_NAME

# Create Backend Pool
az network lb address-pool create \
  --resource-group $RESOURCE_GROUP \
  --lb-name $LOAD_BALANCER_NAME \
  --name $LOAD_BALANCER_BACKEND_NAME

# Create Health Probe
az network lb probe create \
  --resource-group $RESOURCE_GROUP \
  --lb-name $LOAD_BALANCER_NAME \
  --name $PROBE_NAME \
  --protocol Tcp \
  --port 80

# Create Load Balancing Rule
az network lb rule create \
  --resource-group $RESOURCE_GROUP \
  --lb-name $LOAD_BALANCER_NAME \
  --name $RULE_NAME \
  --protocol Tcp \
  --frontend-port 80 \
  --backend-port 80 \
  --frontend-ip-name $LOAD_BALANCER_FRONTEND_NAME \
  --backend-pool-name $LOAD_BALANCER_BACKEND_NAME \
  --probe-name $PROBE_NAME

# Configure Network Security Group Rules (optional, if required)
# az network nsg rule create \
#   --resource-group $RESOURCE_GROUP \
#   --nsg-name MyNetworkSecurityGroup \
#   --name AllowLoadBalancerTraffic \
#   --protocol Tcp \
#   --direction Inbound \
#   --priority 100 \
#   --source-address-prefixes '*' \
#   --source-port-ranges '*' \
#   --destination-address-prefixes '*' \
#   --destination-port-ranges 80 \
#   --access Allow

echo "Azure Load Balancer with private frontend and associated resources have been created successfully."
```
## 20.Added the frontend private ip address to the firewall rules to access from on prem vpn and the request successly executed.
## 21. Next i added a storage accout and made private enpoint for that in TAXI vnet using a special subnet for private endpoint for azure files
## 22. Now i can access the Storage account file storage from the vnet but not anyplace else. I want it to be accessible from on prem environmet as well through the hub and firewall. 

