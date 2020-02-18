# Deploy an Azure VM with RHEL 7.4, IBM WebSphere Application Server ND Traditional V9.0.5 & IBM JDK 8.0 pre-installed

## Prerequisites
 - Register an [Azure subscription](https://azure.microsoft.com/en-us/)
 - Register an [IBM id](https://idaas.iam.ibm.com/idaas/mtfim/sps/authsvc?PolicyId=urn:ibm:security:authentication:asf:basicldapuser)
 - Download [IBM Installation Manager Installation Kit V1.9](https://www-945.ibm.com/support/fixcentral/swg/downloadFixes?parent=ibm%7ERational&product=ibm/Rational/IBM+Installation+Manager&release=1.9.0.0&platform=Linux&function=fixId&fixids=1.9.0.0-IBMIM-LINUX-X86_64-20190715_0328&useReleaseAsTarget=true&includeRequisites=1&includeSupersedes=0&downloadMethod=http)
 - Install [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli?view=azure-cli-latest)
 - Install [PowerShell Core](https://docs.microsoft.com/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-7.1)
 - Install [Maven](https://maven.apache.org/download.cgi)
 - Install [`jq`](https://stedolan.github.io/jq/download/)

 ## Steps of deployment
 1. Checkout [azure-javaee-iaas](https://github.com/Azure/azure-javaee-iaas)
    - change to directory hosting the repo project & run `mvn clean install`
 2. Checkout [arm-ttk](https://github.com/Azure/arm-ttk) under the specified parent directory
 3. Checkout this repo under the same parent directory and change to directory hosting the repo project
 4. Build the project by replacing all placeholder `${<place_holder>}` with valid values
      ```
      mvn -Dgit.repo=<repo_user> -Dgit.tag=<repo_tag> -DibmUserId=<ibmUserId> -DibmUserPwd=<ibmUserPwd> -DadminUser=<adminUser> -DadminPwd=<adminPwd> -DvmAdminId=<vmAdminId> -DvmAdminPwd=<vmAdminPwd> -DdnsLabelPrefix=<dnsLabelPrefix> -Dtest.args="-Test All" -Ptemplate-validation-tests clean install
      ```
 5. Change to `./target/arm` directory
 6. Using `deploy.azcli` to deploy
    ```
    ./deploy.azcli -n <deploymentName> -f <installKitFile> -i <subscriptionId> -g <resourceGroupName> -l <resourceGroupLocation>
    ```

## After deployment
 1. You can [capture the source VM to a custom image](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/capture-image), which consists of RHEL 7.4, IBM WebSphere Application Server ND Traditional V9.0.5 & IBM JDK 8.0, so it can be reused to create VM instances based on it using the same subscription;
 2. Similar to creating a custom private image, you can also [create a Virtual Machine offer in Azure Marketplace](https://docs.microsoft.com/en-us/azure/marketplace/cloud-partner-portal/virtual-machine/cpp-virtual-machine-offer), which is globally public and accessible.
