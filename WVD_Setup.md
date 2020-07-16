# Windows Virtual Desktop (WVD)
## First Time Setup

WVD is an Azure supplement to the traditional ‘RD Gateway’ and ‘RD Connection Broker’ server roles. It allows you to provision image-based session hosts that will run either Windows 10 VDI or traditional server-based RD RemoteApps.

Session hosts are based off of a ‘template’ machine. Template machine should be Azure-based, and avoid complex marketplace images.

### Preparing the template

#### Deploy new VM of preferred OS and login to it. 

Template needs setup with any required roles, applications, and configurations that will be required on session hosts. This includes any application-specific requirements to prepare a machine for Sysprep Generalization. 

- Pick a small size for template, won’t have any load on it and session hosts deployed from image can be set to different size than template. If not doing the template/image model, select appropriate size for server to handle production traffic.
- Domain join template machine, setup OU for “WVD Servers”
- if converting an existing traditional session host, be sure to decommission everything but the “Session Host” role. 
    -  Be sure to disable UPD’s prior to removing the other roles. If needed, remove registry key: 
 > "HKLM\\System\\CurrentControlSet\\Control\\Terminal Server\\ClusterSettings”
 
 - Reboot and login, if you get temp profile, check registry and remove any keys with .bak extensions under: 
 > "HKLM\\SOFTWARE\\Microsoft\\Windows NT\\Current Version\\ProfileList" 
- Uninstall unneeded apps, certificates, etc. Cleanup user directories.
- If OS is Windows Server, “RD Licensing” will need to be installed on another server (Server based session hosts still require CAL/SALs). 
    - Setup GPO pointing to “WVD Servers” OU to configure RD licensing server and license type (based on purchased licensing).
    - Windows 10 VDI is covered by Microsoft M365 / enterprise licensing

    
#### Install FSLogix 

[FSLogix Download](https://aka.ms/fslogix_download)

Will need to decide if user profiles will be stored on File Server or Azure storage account.

If using file share, create new share (under DFS if it’s being used) with appropriate permissions

[Profile Storage Configuration](https://docs.microsoft.com/en-us/fslogix/fslogix-storage-config-ht)

Test share from template server, make sure no issues accessing it. 

Follow the config tutorial to set registry keys as necessary (Profiles key may need to be created)
> “HKLM\\SOFTWARE\\FSLogix\\Profiles”

[Profile Container Tutorial](https://docs.microsoft.com/en-us/fslogix/configure-profile-container-tutorial)

Recommended keys: 
- Enabled, 
- VHDLocations,
- PreventLoginWithFailure,
- PreventLoginWithTempProfile
- (if migrating from existing deployment) DeleteLocalProfileWhenVHDShouldApply


#### Setting up Service Accounts, Admin tool

##### Download ‘WVD Admin’ app

The ‘WVD Admin’ application can be used as a GUI app that brings the entire WVD provisioning process into one convenient location. It even allows for switching between multiple tenants. 

Important to note: All of these tasks can be accomplished manually in the Azure portal. With the Spring 2020 release, Powershell is no longer required to provision WVD. However, this app utilizes a script that makes the sysprep and image creation process much simpler. 

[WVD Admin](https://blog.itprocloud.de/Windows-Virtual-Desktop-Admin/)

- Follow the instructions to create AzureAD Service Account for WVD Admin and assign appropriate permissions/roles

- This service account will be used to make changes through the app. Follow the instructions to configure connection to client’s Azure tenant using the service account. 

- Make sure to configure for ‘Spring 2020 only’ release, if new WVD build

- Follow instructions to setup file share on-prem for template server to access

- Follow instructions to setup local AD service account for joining the session hosts to domain during host pool provisioning process

- (optional) Additional useful features of the admin app: registry setting to enable tenant switcher (designed for consultants with multiple clients)  [https://blog.itprocloud.de/Windows-Virtual-Desktop-Windows-Virtual-Desktop-Administration-for-CSP-and-Consulting-Partners/](https://blog.itprocloud.de/Windows-Virtual-Desktop-Windows-Virtual-Desktop-Administration-for-CSP-and-Consulting-Partners/)

#### Capturing template image

- once all changes have been applied to template VM, shut it down. ** do not sysprep the template **

- using WVD Admin app, capture image from template VM. 

- app will intiate cloning the template, sysprep’ing it and creating an image from it. The image will be stored in Azure


#### Deploying WVD Host Pool

- Right click Host Pool, Add host pool. Shared for remote app, or persistant/vdi if VDI assigned desktops

- Follow Wizard and fill out form with required info to select Resource group, subscription, VNet, etc. Will need to select proper image (just created above) and number of VMs to deploy, and size. 

	* recommended to use separate resource group / vnet for WVD. use vnet peering to make local domain or Azure AD Domain Services available

- Once everything is entered, deploy the host pool. depending on number of hosts it’s provisioning, this can take some time (hour+)
	* it is possible to create a host pool without provisioning VMs, and adding them later. 

#### Deploying RemoteApps or Desktop 


##### Workspaces
To make these session hosts available to users, we need to create a workspace for them to access. 
Right click Workspaces, add workspace. Follow the wizard

Workspaces make various ‘app groups’ available to assigned users/groups. 

##### Application Groups
App groups come in 2 types: Desktop or Application

**Desktop** groups make full desktop sessions available to the session hosts. If the source session host is Windows 10 image, this would be used to give access to the VDI. For servers, this will give user access to standard “Full desktop” of server. 

**Application** groups make specific applications available for users to run as RemoteApps. 

Users are assigned access via Membership to the application groups. Recommended practice is using Azure AD groups to limit access. Using multiple application groups to give users access to only the apps they require. 

##### Adding Applications to App Group

Applications can be added to application groups by right clicking the app group and “add remote application”, or “add remote application from start menu”. if the installed app is available in start menu, WVD can use that existing shortcut/icon to configure access to application. Otherwise, provide file path to executable and icon file (usually the same .exe) Be sure to include any command line arguments if they are required

#### Adding additional/updated session hosts

The benefit of using a template, is that it can be powered-up and changed whenever changes are needed. Once changes are applied, power it back down and follow the image process to deploy additional session hosts to the existing host pool. once new hosts are deployed, configure ‘drain mode’ on old session hosts to prevent new connections. once all users have disconnected from old servers, shut them down and deprovision and delete them. 

#### Adding standalone hosts

If you wanted to move an existing standalone server to be managed by WVD (skipping the template/image process - best for app hosts with local application data)

From WVD Admin app, locate VM in Azure section, right click, “Add to host pool”

WVD agents will be installed and configured, server will be rebooted and come back up as host pool. 

Servers in this scenario require their own host pools and cannot be mixed in host pools that using template/image deployments - since session hosts in a host pool must be identical for load balancing.


Provide app consent

[https://rdweb.wvd.microsoft.com/](https://rdweb.wvd.microsoft.com/)
enter tenant ID and approve server and client app



#### Setup WVD Feed to be discoverable by user’s email address

[https://docs.microsoft.com/en-us/windows-server/remote/remote-desktop-services/rds-email-discovery](https://docs.microsoft.com/en-us/windows-server/remote/remote-desktop-services/rds-email-discovery)

Using instructions here, create specified txt record on each email domain, with appropriate WVD feed as value. 

* (fall 2019) [https://rdweb.wvd.microsoft.com/api/feeddiscovery](https://rdweb.wvd.microsoft.com/api/arm/feeddiscovery)

* (spring 2020) [https://rdweb.wvd.microsoft.com/api/arm/feeddiscovery](https://rdweb.wvd.microsoft.com/api/arm/feeddiscovery)


#### Accessing WVD

WVD can be accessed using HTML5, Android/iOS Apps, and Windows 10 App

##### HTML5 portal here: 
* (fall 2019) https://rdweb.wvd.microsoft.com/webclient/index.html

* (spring 2020) https://rdweb.wvd.microsoft.com/arm/webclient/index.html


##### Windows 10 MSI
https://go.microsoft.com/fwlink/?linkid=2068602

- Once app is installed, enter user’s email address to discover and subscribe to feed

- Standard Office365 auth prompt to sign in


Scripts are available to deploy windows 10 app via intune, and create desktop shortcut of user’s RemoteApps folder for easier locating. 




Additional References

- [https://medium.com/@zhenyuzhao/windows-virtual-desktop-spring-2020-release-step-by-step-guide-part-1-basic-292d52203802](https://medium.com/@zhenyuzhao/windows-virtual-desktop-spring-2020-release-step-by-step-guide-part-1-basic-292d52203802)

- [https://community.sophos.com/kb/en-us/120560](https://community.sophos.com/kb/en-us/120560)

