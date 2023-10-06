<!-- Copyright (c) Microsoft Corporation. -->
<!-- Copyright (c) IBM Corporation. -->

# How to update apiVersion

This guidance describes how to update `apiVersion` elements in Bicep and ARM files.

## What is an apiVersion?

Some resource references in Bicep files or ARM templates include an `apiVersion` in `YYYY-MM-DD` form. For the usage in Bicep templates see content related to `<api-version>` in [Understand the structure and syntax of Bicep files](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/file#bicep-format). For the usage in ARM templates see `apiVersion` in [ARM template best practices](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/best-practices#api-version).

## Why do I need to do this?

The certification tests for Azure Marketplace offers include a check that none of the `apiVersion` elements are older than two years from the current day when the test is run. If any of the `apiVersion` elements fail that check, the offer cannot be published.

## How do I proactively tell if the test would fail?

These workflows run the same test that Azure Marketplace runs, so you can view success or failure of these workflows as a proxy for what Azure Marketplace would do when you try to publish an offer.

* https://github.com/WASdev/azure.liberty.aks/actions/workflows/package.yaml
* https://github.com/WASdev/azure.liberty.aro/actions/workflows/package.yaml
* https://github.com/WASdev/azure.websphere-traditional.singleserver/actions/workflows/package.yaml
* https://github.com/WASdev/azure.websphere-traditional.cluster/actions/workflows/package.yaml

## What do I do if the test fails?

- How do I find the latest valid `YYYY-MM-DD` value for a given resource? 

   ```bash
   export NameSpace=<your_name_space>
   export ResourceType=<your_resource_type>
   az provider show --namespace ${NameSpace} --query "resourceTypes[?resourceType=='${ResourceType}'].apiVersions[:10]" \
      | jq -r '.[][] | select(test("preview$"; "i") | not)' | head -n 1
   ```
   
   For example, in Bicep, the resource to create an AKS cluster is `resource symbolicname 'Microsoft.ContainerService/managedClusters@<api-version>'`.  This same resource in ARM is 
   
   ```json
   {
      "type": "Microsoft.ContainerService/managedClusters",
      "apiVersion": "<api-version>",
   ```
   
   In either case, the way to get the `apiVersion` value is the same:
   
   ```bash
   export NameSpace="Microsoft.ContainerService"
   export ResourceType="managedClusters"
   az provider show --namespace ${NameSpace} --query "resourceTypes[?resourceType=='${ResourceType}'].apiVersions[:10]" \
      | jq -r '.[][] | select(test("preview$"; "i") | not)' | head -n 1
   2023-08-01
   ```
   
- How do I update the value in an ARM template?

   For offers that use ARM templates instead of Bicep, we use the [maven-resources-plugin](https://maven.apache.org/plugins/maven-resources-plugin/) to do `${}` substitution. Consider this ARM template excerpt.
   
      ```json
      "resources": [
          {
              "type": "Microsoft.Network/networkSecurityGroups/securityRules",
              "name": "[concat(parameters('networkSecurityGroupName'),'/','WebLogicAdminPortsDenied')]",
              "condition": "[parameters('denyPublicTrafficForAdminServer')]",
              "apiVersion": "${azure.apiVersion}",
      //...
      ]
      ```

    Because we run the ARM templates through the `maven-resources-plugin`, these values are replaced when copying from `src` to `target`. By convention we define these things in a properties file referred to from the POM and reference that properties file in tho `<properties>` element in the POM.
    
- How do I update the value in a Bicep file?

   The way we have adapted the Bicep tooling to our use of Maven does not allow such processing, so you must manually edit the hard-coded `<api-version>` values wherever they occur.

- References/Related PRs
    - https://github.com/WASdev/azure.websphere-traditional.image/pull/94
    - https://github.com/WASdev/azure.websphere-traditional.singleserver/pull/90
    - https://github.com/WASdev/azure.websphere-traditional.cluster/pull/229
    - https://github.com/WASdev/azure.websphere-traditional.image/pull/96
    - https://github.com/WASdev/azure.websphere-traditional.cluster/pull/231
