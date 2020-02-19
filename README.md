# Deploy an Azure VM with RHEL 7.4, IBM WebSphere Application Server ND Traditional V9.0.5 & IBM JDK 8.0 pre-installed

## Prerequisites
 - Register an [Azure subscription](https://azure.microsoft.com/en-us/)
 - Register an [IBM id](https://idaas.iam.ibm.com/idaas/mtfim/sps/authsvc?PolicyId=urn:ibm:security:authentication:asf:basicldapuser)
 - Download [IBM Installation Manager Installation Kit V1.9](https://www-945.ibm.com/support/fixcentral/swg/downloadFixes?parent=ibm%7ERational&product=ibm/Rational/IBM+Installation+Manager&release=1.9.0.0&platform=Linux&function=fixId&fixids=1.9.0.0-IBMIM-LINUX-X86_64-20190715_0328&useReleaseAsTarget=true&includeRequisites=1&includeSupersedes=0&downloadMethod=http)
 - Install [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
 - Install [PowerShell Core](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-6)
 - Install Maven

 ## Steps of deployment
 1. Checkout [azure-javaee-iaas](https://github.com/Azure/azure-javaee-iaas)
    - change to directory hosting the repo project & run `mvn clean install`
 2. Checkout [azure-quickstart-templates](https://github.com/Azure/azure-quickstart-templates) under the specified parent directory
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
 1. Once the deployment is complete, we can capture the created VM to a custom image, which consists of RHEL 7.4, IBM WebSphere Application Server ND Traditional V9.0.5 & IBM JDK 8.0
