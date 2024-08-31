# Azure-Networking-and-infrastructure
## I tried to use all major networking services in this enterprises grade project. Services used in this lab include Azure WAN, Hub, Azure firewall, Virtual Networks, Virtual Machines, Network Peerings, Azure app gateway, Azure Load Balancer, Firewall Policy, Storage accounts, Private Endpoint, Private DNS resolvers, Private DNS zones, P2s VPNS, WAF and more
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
## 23. At this point its already been 2 days since i started the project and i couldn't figure out what to do to access private endpoint from on prem machines and specifically from P2S devices
## 24. I destroyed all the hub and spoke network as it already costed me 10000 rs, i came back with a vnet and a storage account and a virtual network gateway and p2s configration to emulate the same sceniario described above but without the hub spokes and firewall
## 25.After some trial and error method, i found the solution can use Azure private DNS reoslver fully managed service.
## 26 I connected the vpn to p2s devices again by using the root and child certificate method. Storage account and private endpoint were already in place and a private DNS zone was adlready created.
## 27. Next i created a private DNS resolver and used the same location as the vnet used. made a new subnet for the vnet of /28 subnet mask and noted the ip of the inbound endpoint of the resolver.
## 28. I then chnaged the settings of the vpn dns setting in my win 11 computer to use the ip of the inbound endpoint and subsequently chnaged the dns server of the vnet to inbound ip of the resolver
## 29. I used NSlookup before and after doing the setup for the file storage of the storage account and got public ip before and private ip after i confgiured all the settings above.
## 30. I mounted the drive using the connect option in the storage account and the connection was successfull and i can access the private endpoint privately 
![Screenshot 2024-08-24 152359](https://github.com/user-attachments/assets/ed0ea388-0b78-47b5-9bb2-583eb91e9c55)

![Screenshot 2024-08-24 152933](https://github.com/user-attachments/assets/b3033639-02c3-4df6-9d33-eeb63a3bab71)

![Screenshot 2024-08-24 205836](https://github.com/user-attachments/assets/80bb3e2a-0a8f-419e-a83a-ea7e4f9e3690)

![Screenshot 2024-08-24 210736](https://github.com/user-attachments/assets/575ee20c-088e-4800-af99-a81ccf0f31e0)

![Screenshot 2024-08-24 214635](https://github.com/user-attachments/assets/0fee8b72-28ae-4849-9eeb-0f0335e52d4b)

![Screenshot 2024-08-24 215055](https://github.com/user-attachments/assets/5d303a98-2cb4-4daf-98a0-92f21f45b19b)


![Screenshot 2024-08-24 215106](https://github.com/user-attachments/assets/936ea4e2-ac02-4458-801d-1729d8dd1969)


![Screenshot 2024-08-24 220824](https://github.com/user-attachments/assets/03c68709-2a06-4076-b142-754f11ba5336)

![Screenshot 2024-08-24 221509](https://github.com/user-attachments/assets/b8f2747e-ea65-4342-8c22-37704428fbc7)

Adding certificate data in user conf in WAN
![Screenshot 2024-08-24 221519](https://github.com/user-attachments/assets/30ae090c-6e6f-425f-8f8b-655406418826)

![Screenshot 2024-08-24 221801](https://github.com/user-attachments/assets/8377ce10-c3ce-46d6-ac85-7fe6bd438f12)
This deployment of HUB took 40 mins approx
![Screenshot 2024-08-24 223107](https://github.com/user-attachments/assets/725bf065-a186-49bc-8b86-5838b6007a99)
Adding connections to wan

![Screenshot 2024-08-24 232024](https://github.com/user-attachments/assets/07f4fba4-19d2-42d5-8250-f31afb8f922e)
Peerings succesfully added
![Screenshot 2024-08-24 232449](https://github.com/user-attachments/assets/4d0efaa8-2331-461c-85ea-3231f70158ce)
Downlaoded and installed the VPN file from the hub 
![Screenshot 2024-08-24 232939](https://github.com/user-attachments/assets/dc8ac9a9-7f4e-49b9-8786-459144c9ad87)

![Screenshot 2024-08-24 233001](https://github.com/user-attachments/assets/43b137f3-726b-4785-b387-911a2361ea2a)
Peerings as seen from the connected vnets
![Screenshot 2024-08-24 233258](https://github.com/user-attachments/assets/ec28310a-eae7-4750-a2ee-d8ba700a24c5)
pinging of the vms successful from P2S to peered networks to the hub
![Screenshot 2024-08-24 234634](https://github.com/user-attachments/assets/23c45572-8ac8-4076-a647-47d64a3eb5bc)
![Screenshot 2024-08-24 234643](https://github.com/user-attachments/assets/24359faf-0f86-4e58-a6cc-b78b482537bd)
Disabling wins firewall from portal using powershell
![Screenshot 2024-08-25 145302](https://github.com/user-attachments/assets/c30bfee7-abec-4a71-bae9-7cca43afccd6)
allowing ICMP from windows firewall from insode the VM
![Screenshot 2024-08-25 152142](https://github.com/user-attachments/assets/4b21d708-e925-41c0-981b-521fb710ccd4)

App gateway frontend config
![Screenshot 2024-08-25 163336](https://github.com/user-attachments/assets/345bd3d3-5f28-4e32-9661-704d547173b0)


![Screenshot 2024-08-25 164031](https://github.com/user-attachments/assets/2bb66bf5-fdcb-4179-8ea2-c35c14c284ca)
configures default IIS server on one machine
![Screenshot 2024-08-25 164907](https://github.com/user-attachments/assets/f489aa82-017e-4110-afe5-07cc2c840493)

![Screenshot 2024-08-25 165345](https://github.com/user-attachments/assets/87ea31c7-36c4-4f34-9af7-54ddeeaa51b7)


Both public and private listeners available for the gateway
![Screenshot 2024-08-25 165926](https://github.com/user-attachments/assets/6920eaa2-ca38-473e-902c-99b4b541853d)
now connecting using private ip from P2S client

![Screenshot 2024-08-25 170133](https://github.com/user-attachments/assets/0fcaf3f2-cd46-4868-a37c-f4468784be31)

configured IIS on another machine using custom script extension which will show the vm name to test our gateway

```bash
Set-AzVMExtension -ResourceGroupName exp2_group -ExtensionName IIS -VMName exp2 -Publisher Microsoft.Compute -ExtensionType CustomScriptExtension -TypeHandlerVersion 1.4 -SettingString '{"commandToExecute":"powershell Add-WindowsFeature Web-Server; powershell Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value $($env:computername)"}' -Location CentralIndia
```
![Screenshot 2024-08-25 173428](https://github.com/user-attachments/assets/5e5db90c-0116-4020-abb3-b81b4a009469)
![Screenshot 2024-08-25 173617](https://github.com/user-attachments/assets/829002b2-1692-43e4-ae64-08fff1eb5125)
Clicking randomly to private ip of the app gateway the vms change like below
![Screenshot 2024-08-25 173745](https://github.com/user-attachments/assets/1be1f1c8-a856-4d16-83a8-9a6d2a834a58)

![Screenshot 2024-08-25 173754](https://github.com/user-attachments/assets/a2e3e37f-ef68-42f6-96a8-8da347362d1d)
Used WAF v2 for the gateway
![Screenshot 2024-08-25 175736](https://github.com/user-attachments/assets/fabf29d6-b575-4a4a-b0e5-a33b9ce43fab)

![Screenshot 2024-08-25 181423](https://github.com/user-attachments/assets/89b76058-5f60-4ccd-ab50-2afe3bab404f)
Adding custom rules to not give acces to certain IP address in prevention mode( important)

![Screenshot 2024-08-25 181638](https://github.com/user-attachments/assets/b5c2fda7-0e23-4eff-9908-bd073e42b78c)
accesing the gateway from the restricted IP address i get this 
![Screenshot 2024-08-25 183756](https://github.com/user-attachments/assets/14376b0c-2562-4cb7-82ff-a5b5f5076d33)
Setting up firewalin the hub to make secure hub. Connection must be explicitly allowed now
![Screenshot 2024-08-25 200246](https://github.com/user-attachments/assets/7885828c-a4f1-43c6-8b08-fe0e0e7b6733)

![Screenshot 2024-08-25 204742](https://github.com/user-attachments/assets/df8cc3c2-2062-4890-9108-a69db044ca37)
Added network rule in firewall policy to allow connection as everything is blocked by default
![Screenshot 2024-08-25 205726](https://github.com/user-attachments/assets/5b4157e6-3e13-47b7-b729-071dc66cc932)
![Screenshot 2024-08-25 210234](https://github.com/user-attachments/assets/27eaa8e6-23ea-4c69-9bba-12de922af0f4)

![Screenshot 2024-08-25 211147](https://github.com/user-attachments/assets/d70afaa6-996a-416d-a0cf-281a66ee34ef)

tried to attach premieum poicy to standard firewall which didnt work

![Screenshot 2024-08-25 211816](https://github.com/user-attachments/assets/558b399f-256b-400a-828e-35b35f0867d1)

testing using NCAP
![Screenshot 2024-08-26 002237](https://github.com/user-attachments/assets/1f0bbd4b-d762-43ce-aeae-6b712512d0ae)

Load Balancer

![Screenshot 2024-08-26 003848](https://github.com/user-attachments/assets/17cb1582-583f-4be7-8db0-c37d3f09feae)



![Screenshot 2024-08-26 003919](https://github.com/user-attachments/assets/dd8faef9-4068-4fd3-b9dc-2b97f63034cc)

Storage account with private endpoint
![Screenshot 2024-08-26 114240](https://github.com/user-attachments/assets/d3076f9a-1c11-42bd-9fe2-0dd731a4fcd1)
![Screenshot 2024-08-26 120302](https://github.com/user-attachments/assets/6e6c903d-eb55-4604-b495-02abec242e5d)

accessing storage endpoint using private address from outside the vnet

![Screenshot 2024-08-26 235925](https://github.com/user-attachments/assets/13356fb2-51c2-4cca-adb2-ddbc2ac286f8)
normally without the conf it will be like this, using the public ip of the strage acount
![Screenshot 2024-08-27 101805](https://github.com/user-attachments/assets/3c069732-760f-493e-a9cc-34d34201a2e3)
Total cost incurred over 3 days. Later i destroyed the resouces and started again with storage account access problem
![Screenshot 2024-08-27 132043](https://github.com/user-attachments/assets/b7e9b420-3edd-4a1e-bd1d-358655c3d017)

![Screenshot 2024-08-27 132050](https://github.com/user-attachments/assets/e7248fc6-1ad1-4cc4-85ce-f94194c89880)
Using Private dns resolver and used the inbound ip confired in that as DNS server for the P2S client
![Screenshot 2024-08-31 004304](https://github.com/user-attachments/assets/668bd2e5-820b-4d09-800a-227e13ba778a)

![Screenshot 2024-08-31 004323](https://github.com/user-attachments/assets/ff155ded-b303-44c5-b641-437f20e9ba02)


![Screenshot 2024-08-31 143748](https://github.com/user-attachments/assets/4f663b89-f8c8-4a39-8732-86ad310fa926)

![Screenshot 2024-08-31 143753](https://github.com/user-attachments/assets/be646b62-2934-4161-96bd-61f143639750)
![Screenshot 2024-08-31 143808](https://github.com/user-attachments/assets/ebcad8c5-98ff-4d76-97a8-a179d3d525d5)








# LAB CONCLUDED
