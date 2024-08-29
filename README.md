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
