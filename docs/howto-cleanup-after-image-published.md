# How to clean up the storage account with VHD files after image is published

Normally, the image build CICD ([ihs CICD](../.github/workflows/ihsBuild.yml), [twas-base CICD](../.github/workflows/twas-baseBuild.yml), [twas-nd CICD](../.github/workflows/twas-ndBuild.yml), [ihs-cis CICD](../.github/workflows/ihs-cisBuild.yml), [twas-base-cis CICD](../.github/workflows/twas-base-cisBuild.yml) and [twas-nd-cis CICD](../.github/workflows/twas-nd-cisBuild.yml)) workflow will provision the source VM, install software package, execute integration test and finally generate SAS urls for OS disk and data disk VHD files which will be used for creating/updating Azure virtual machine offer(s) in Azure Partner Center. 

These VHD files are stored in a storage account in Azure, and you should get it deleted to reduce Azure cost **after image is successfully published and available in the Partner Center**.

## Find out the storage account from Azure Portal

Follow steps below to find out where the storage account is from Azure Portal.

1. Go to [Actions](https://github.com/WASdev/azure.websphere-traditional.image/actions).
1. Find out the workflow you kicked off before. Click to open.
1. Copy URL from browser address bar, which looks like `https://github.com/WASdev/azure.websphere-traditional.image/actions/runs/<run-id>`. Copy `<run-id>`.
1. Go to [Azure Portal](https://portal.azure.com/#home) > Type "Resource groups" in the search bar > Select "Resource groups" from the list of service.
1. In the page of "Resource groups", paste copied `<run-id>` into the filter box. Wait a few seconds and click the resource group listed in the page. Log down the resource group name.
1. In the page of selected resource group, you should be able to see the storage account resource.

## Clean up

Now you can delete the resource group of the storage account, which will delete all resources inside the resource group.

1. In the page of selected resource group, click "Delete resource group".
1. Type the resource group name and click "Delete".
1. The deletion operation is handled asychronously, the UI will notify you once it completes.

Alternatively, you can also execute the following command to delete the resource group:

```bash
az group delete --name <resource-group-of-storage-account> --yes 
```
