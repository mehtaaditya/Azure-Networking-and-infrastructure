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

