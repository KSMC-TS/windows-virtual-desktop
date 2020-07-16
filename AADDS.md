Deploying AzureAD Domain Services

Decide on domain
Microsoft recommends using subdomain that is _different_ than on-prem and AzureAD domains 
(eg. ad.contoso.com)

Configure Resource Group, VNet, Location
Microsoft encourages a separate subnet for AADDS on the VNet. Create a new subnet for it on the VNet
Decide on where AADDS will be deployed, this cannot be changed

Create Resource
Azure AD Domain Services
Forest Type: user - will be fine for SMB deployments with a single directory
SKU: Standard - will be fine for SMB deployments with a single directory
Sync: All 

Add admins - client admina account for team notifications, onsite IT

Deployment takes a long time (1hr+)
Deployment will complete, and then Managed Domain will go through another setup process. When finally complete, Health Status will show "Running"

Configuring Password Hash Sync

AzureAD doesn't store passwords in the correct format by default. Synced users from AD Connect must have their password hash synced up from on-prem by running a Powershell script on the AD Connect server

Cloud Only users must reset their password after AADDS is deployed, before they will be able to login

[https://docs.microsoft.com/en-us/azure/active-directory-domain-services/tutorial-configure-password-hash-sync](https://docs.microsoft.com/en-us/azure/active-directory-domain-services/tutorial-configure-password-hash-sync)


Setup Secure LDAP
Zach Choate has built an ARM Template to deploy the required Automation account and Runbooks to setup LDAPS with Let's Encrypt certificates

[https://github.com/zchoate/LetsEncrypt\_Az\_AADDS_Renewal](https://github.com/zchoate/LetsEncrypt_Az_AADDS_Renewal)

Using the "Deploy to Azure" button, sign in with the appropriate credentials and follow the template. You will need the following info:
Client Public DNS Provider - Azure, GoDaddy, CloudFlare currently supported
DNS Provider-specific API credentials
Set to LE_Stage for first run
External Access Enabled yes or no

Current issue with deployment causes Automation RunAs account to not be created successfully. Navigate to Automation Account and go to RunAs accounts, under Account Settings
Create new Azure RunAs account, accept defaults
Go to AzureAD, Roles, and Add the Automation RunAs account to "Global Administrators" role
Go to Runbook and run the Install-LE-AADDS.ps1 runbook. It will take a few minutes. When complete, verify in output that cert request was successful. 
Navigate to Variables in Automation account, and change "LEserver" to "LE_PROD"
Verify output again. This time, prod certificate will be requested and installed
Once Complete, check AADDS to verfiy LDAPS is enabled successfully. 
Configure External Access and NSG as needed. 
Back on Runbook, add new schedule to run Runbook weekly (wed, 3am)



Domain-Joining Servers

Domain join on VMs is normal process. Use the Managed Domain name, and ensure that password hash synch as been configured first.