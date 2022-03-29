# How to access the source VM when image build CI/CD failed

Normally, the image build CICD ([ihs CICD](../.github/workflows/ihsBuild.yml), [twas-base CICD](../.github/workflows/twas-baseBuild.yml) and [twas-nd CICD](../.github/workflows/twas-ndBuild.yml)) workflow will provision the source VM, install software package, execute integration test and finally generate SAS urls for OS disk and data disk which will be used for creating/updating Azure virtual machine offer(s) in Azure Partner Center. 

However, if the CICD workflow failed at step of installing software package due to unknown issues, user usually needs to access the source VM to triage the issue, and/or collect logs for issue reporting. Here're instructions on how to access the source VM.

## Find out the source VM from Azure Portal

Follow steps below to find out where the source VM is from Azure Portal.

1. Go to [Actions](https://github.com/WASdev/azure.websphere-traditional.image/actions).
1. Find out the workflow you kicked off before. Click to open.
1. Copy URL from browser address bar, which looks like `https://github.com/WASdev/azure.websphere-traditional.image/actions/runs/<run-id>`. Copy `<run-id>`.
1. Go to [Azure Portal](https://portal.azure.com/#home) > Type "Resource groups" in the search bar > Select "Resource groups" from the list of service.
1. In the page of "Resource groups", paste copied `<run-id>` into the filter box. Wait a few seconds and click the resource group listed in the page. Log down the resource group name.
1. In the page of selected resource group, find out the VM resource with type "Virtual machine". Click to open.
1. In the page of selected virtual mainche, log down value of "Public IP address".

## Access the source VM

In order to connect to the source VM, you also need VM administrator credentials that you configured as GitHub action repository secrets `VM_ADMIN_ID` and `VM_ADMIN_PASSWORD`. Find out and log down the credentials.

Follow steps below to connect to the source VM and inspect the issue.

1. Open a command line interface where `ssh` command is supported.
1. Exceute `ssh <VM_ADMIN_ID>@<Public_IP_address>` and follow the prompts to complete ssh login with `VM_ADMIN_PASSWORD`. If you can't connect to the source VM with `ssh`, you must resolve the issue and return here to continue.
1. After you successfully logging into the source VM with `ssh`
   1. Run the shell with root privilidges.
      ```bash
      sudo -i
      ```

    1. View and export environment variables defined in `/datadrive/virtualimage.properties`.
       ```bash
       cat /datadrive/virtualimage.properties
       source /datadrive/virtualimage.properties
       ```

       Common to all CICDs:
       * `IM_INSTALL_DIRECTORY` is the directory where IBM Installation Manager is installed.
       * Export IBM Installation Manager installation data: `${IM_INSTALL_DIRECTORY}/eclipse/tools/imcl exportinstalldata imagent.zip`

       For `twas-nd CICD`:
       * `WAS_ND_INSTALL_DIRECTORY` is the directory where IBM WebSphere Application Server Network Deployment is installed.

       For `twas-base CICD`:
       * `WAS_BASE_INSTALL_DIRECTORY` is the directory where IBM WebSphere Application Server is installed.

       For `ihs CICD`:
       * `IHS_INSTALL_DIRECTORY` is the directory where IBM HTTP Server is installed.
       * `PLUGIN_INSTALL_DIRECTORY` is the directory where Web Server Plug-ins for IBM WebSphere Application Server is installed.
       * `WCT_INSTALL_DIRECTORY` is the directory where WebSphere Customization Toolbox is installed

    1. Change directory to the working directory of VM extension execution.
       ```bash
       cd /var/lib/waagent/custom-script/download/0/
       ```

    1. List all files.
       ```bash
       ls
       agent.installer.linux.gtk.x86_64.zip  im_installer  install.sh  stderr  stdout
       ```

       Note:
       * `install.sh` is the script responsible for installing software packages.
       * `stdout` is the log file including text output sent from the shell commands in `install.sh`.
       * `stderr` is the log file including error messages sent from the shell commands in `install.sh`.

## Clean up

Once you completed the trouble shooting of the source VM, clean up the Azure resources to avoid Azure charges:

```bash
az group delete --name <resource-group-of-source-vm> --yes 
```
