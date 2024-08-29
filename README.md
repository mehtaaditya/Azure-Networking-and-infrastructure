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
## 9. I deployed the azure application gateway behind vnet experimental and added two machines in the vnet in the backend pool.
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

