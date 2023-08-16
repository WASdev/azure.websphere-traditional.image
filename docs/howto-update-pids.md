<!-- Copyright (c) Microsoft Corporation. -->
<!-- Copyright (c) IBM Corporation. -->

# How Azure customer usage attribution works in the IBM Partner Center offers

This (mostly) self-contained document describes how "Azure customer usage attribution" is implemented in the IBM partner center offers whose source code is maintained in this repository and related repositories linked in the top level [README.md](../README.md).

There is a guide from Microsoft about this topic, but reading it is not essential, and may even be confusing when trying to reconcile the implementation used in the IBM Partner Center ofers and that described in the guide. You can find this guide at [Azure customer usage attribution](https://learn.microsoft.com/en-us/partner-center/marketplace/azure-partner-customer-usage-attribution).

## What is Azure customer usage attribution and why is it necessary?

Let's unpack "Azure customer usage attribution".

- The "Azure customer" is an individual Azure subscription.
- The "usage" is the act of deploying an individual plan, within an offer, to Azure.
- The "attribution" allows Microsoft to attribute new deployments of specific individual plans. Partners can access these reports.

Why is it necessary? Reasons include, but are not limited to:

- Billing, especially for Pay-as-you-go offers PAYGO.
- Tracking popularity of the offers by viewing reports.
   - The IBM Partner Center offers are of two types, each with different ways to access the reports. The reports are beyond the scope of this document, but you can learn more at the following links.
      - Virtual machine offers: [Usage dashboard for Virtual Machine (VM) offers in commercial marketplace analytics
](https://learn.microsoft.com/en-us/partner-center/usage-vm-dashboard)
      - Azure Application offers: [Azure Usage report - Cloud product performance](https://learn.microsoft.com/en-us/partner-center/insights-azure-usage-report)

## What are the key artifacts that enable Azure customer usage attribution?

Partner Center offers (also called Commercial Marketplace offers), including the IBM Partner Center Offers, are organized in the following hierachy.

- **Tenant**. For the IBM Partner Center offers, this is **IBM-Alliance-Microsoft Partner Network-Global-Tenant**
   - **Marketplace Publisher ID**. This is **IBM Websphere-ibm-usa-ny-armonk-hq-6275750-ibmcloud-aiops**.
      - **Offer**. All offers have an Offer ID.
         - **Plan**. All offers must have at least one Plan. Plans have a Plan ID. The IBM Partner Center offers have one plan per offer.
            - If the offer is an Azure Application offer, the plan has a **Customer usage attribution ID**. A Virtual Machine offer does not have a Customer usage attribution ID.
              Each plan has one and only one of these. A Customer usage attribution ID is globally unique and **is assigned by Partner Center** when the plan is created.  **You cannot change a Customer usage attribution ID**.
              **If you try to publish an offer without including the assigned Customer usage attribution ID in the right way, the publish will fail**.
              A Customer usage attribution ID follows this format `pid-<GUID>-partnercenter`, where `<GUID>` is a 128 bit value as defined by [RFC-4122](https://datatracker.ietf.org/doc/html/rfc4122).
              Because the value starts with `pid`, let's call these values `pids` for discussion.
            - **Technical configuration package**. The technical configuration package is a zip file that contains all the necessary technical artifacts to make the offer available in the Azure Marketplace and Azure portal. If the offer is an Azure Application offer, one of the technical artifacts in the zip file is the `mainTemplate.json` file. One of the elements of this JSON file must have the `pid`, in exactly the expected format. The format is beyond the scope of this document, but here is an example.

               ```json
               {
                 "type": "Microsoft.Resources/deployments",
                 "apiVersion": "2022-09-01",
                 "name": "pid-5d69db5c-7773-47d1-9455-890d05fb3c2b-partnercenter",
                 "properties": {
                 // removed for clarity.
                 }
               }
               ```

## How do the IBM Partner Center Azure Application offers satisfy the above requirements?

The manner in which the requirements are met depends on which Infrastructure as Code template is used in the offer: Azure Resource Manager (ARM) or Bicep. All of the Azure Application offers except for Liberty on ARO use Bicep. Liberty on ARO uses ARM.  The "compiled" format of Bicep is ARM. Colloquially, it is said, "Bicep 'compiles down' to ARM."

### ARM

The Partner Center `pid` value is kept in the top level `pom.xml`, in the `<properties>` section. The name of the property is `customer.usage.attribution.id`. This POM produces the technical configuration package zip file. The system orchestrated by the POM ensures the `pid` value is encoded in the proper file and the proper place in that file.

To update the `pid` you simply update the value in the `pom.xml` and re-run the automation as described in [GitHub Actions automation](howto-update-image.md).

### Bicep

The `pid` value is kept in the `mainTemplate.bicep` file, in the `src/main/bicep` directory for each offer. Due the approach taken by the IBM Partner Center offers to the architecture of Bicep, the `pid` must be hard-coded into the `mainTemplate.bicep` file. All the offers use the following convention.

- Declare a Bicep `module` named `partnerCenterPid` whose `name` is the `pid` value from Partner Center.  The module source file is empty. There are no `params`. Here is an example.

   ```json
   module partnerCenterPid './modules/_pids/_empty.bicep' = {
     name: 'pid-68a0b448-a573-4012-ab25-d5dc9842063e-partnercenter'
     params: {}
   }
   ```
   
To update the `pid` you simply update the value in the `mainTemplate.bicep` and re-run the automation as described in [GitHub Actions automation](howto-update-image.md).

## When do I need to change the pid values as described in the preceding section?

The only time you need to do this is if you are creating a new Plan, either in an existing Azure Application offer, or in a new Azure Application offer.
