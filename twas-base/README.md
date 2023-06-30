<!-- Copyright (c) Microsoft Corporation. -->
<!-- Copyright (c) IBM Corporation. -->

# Deploy an Azure VM with RHEL 8.4, IBM WebSphere Application Server Traditional V9.0.5 & IBM JDK 8.0 pre-installed

## Prerequisites

1. Register an [Azure subscription](https://azure.microsoft.com/).
1. Register an [IBM id](https://www.ibm.com/account/reg/sg-en/signup?formid=urx-19776). Contact IBM to make it entitled.
1. Install [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli?view=azure-cli-latest).
1. Install [PowerShell Core](https://docs.microsoft.com/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-7.1).
1. Install [Maven](https://maven.apache.org/download.cgi).
1. Install [`jq`](https://stedolan.github.io/jq/download/).

## Steps of deployment

1. Checkout [azure-javaee-iaas](https://github.com/Azure/azure-javaee-iaas)
   1. Change to directory hosting the repo project & run `mvn clean install`
1. Checkout [arm-ttk](https://github.com/Azure/arm-ttk) under the specified parent directory
   1. Run `git checkout cf5c927eaf1f5652556e86a6b67816fc910d1b74` to checkout the verified version of `arm-ttk`
1. Checkout this repo under the same parent directory and change to directory hosting the repo project
1. Change to sub-directory `twas-base`
1. Build the project by replacing all placeholder `${<place_holder>}` with valid values

   ```bash
   mvn -Dgit.repo=<repo_user> -Dgit.tag=<repo_tag> -DibmUserId=<entitledIBMid> -DibmUserPwd=<entitledIBMidPwd> -DvmAdminId=<vmAdminId> -DvmAdminPwd=<vmAdminPwd> -DdnsLabelPrefix=<dnsLabelPrefix> -Dtest.args="-Test All" -Ptemplate-validation-tests -Dtemplate.validation.tests.directory=../../arm-ttk/arm-ttk clean install
   ```

1. Change to `./target/cli` directory
1. Using `deploy.azcli` to deploy

   ```bash
   ./deploy.azcli -n <deploymentName> -i <subscriptionId> -g <resourceGroupName> -l <resourceGroupLocation>
   ```

## After deployment

1. You can [capture the source VM to a custom image](https://docs.microsoft.com/azure/virtual-machines/linux/capture-image), which consists of RHEL 8.4, IBM WebSphere Application Server Traditional V9.0.5 & IBM JDK 8.0, so it can be reused to create VM instances based on it using the same subscription;
1. Similar to creating a custom private image, you can also [create a Virtual Machine offer in Azure Marketplace](https://docs.microsoft.com/azure/marketplace/cloud-partner-portal/virtual-machine/cpp-virtual-machine-offer), which is globally public and accessible. You can see more information in the following section.

### Creating Virtual Machine offer in Azure Marketplace manually

1. Deploy an Azure VM provisioned with RHEL, WebSphere & JDK (e.g., RHEL 8.4, IBM WebSphere Application Server Traditional V9.0.5 & IBM JDK 8.0). Use different combinations of OS, WebSphere and JDK per your requirements. If you want to install WebSphere and JDK in a separate data disk, only provision the VM with RHEL. Manual deployment or using the tailored ARM template works.
   1. Use un-managed disks instead of managed disks for VM provision. By doing so, the VHDs attached to the VM are stored in the storage account, which can be accessed later during the certification process of publishing VM image into Azure Marketplace
   1. This repo is an example on how to create an un-managed OS disk and data disk in the storage account using ARM template;
1. [Generate VM image](https://docs.microsoft.com/azure/virtual-machines/linux/capture-image):
   1. SSH into the provisioned VM
      1. Delete all sensitive files that you don't want them appear in image
      1. Update applications installed on the system: `sudo yum update -y`
      1. Deprovision: `sudo waagent -deprovision+user -force`
      1. exit
   1. De-allocate VM: `az vm deallocate --resource-group <resourceGroupName> --name <vmName>`
   1. Generalize VM: `az vm generalize --resource-group <resourceGroupName> --name <vmName>`
   1. [**Optional**] To test if the VHD of de-allocated and generalized VM works, you can create image and use it for creating new VM instances to verify
      1. `az image create --resource-group <resourceGroupName> --name <imageName> --source <vmName>`
      1. `az vm create --resource-group <resourceGroupName> --name <newVMInstanceName> --image <imageId> --generate-ssh-keys`
1. Create virtual machine offer on Azure Marketplace using the VM image:
   1. [How to plan a virtual machine offer](https://docs.microsoft.com/azure/marketplace/marketplace-virtual-machines)
   1. [How to create plans for a virtual machine offer](https://docs.microsoft.com/azure/marketplace/azure-vm-create-plans)
   1. [How to create a virtual machine using your own image](https://docs.microsoft.com/azure/marketplace/azure-vm-create-using-own-image)
   1. [How to generate a SAS URI for a VM image](https://docs.microsoft.com/azure/marketplace/azure-vm-get-sas-uri)
1. Once the VM offer created successfully in Azure Marketplace, try to deploy a virtual machine using this VM offer and export the ARM template, where you can find how to correctly reference the VM offer in the upstream ARM template.
