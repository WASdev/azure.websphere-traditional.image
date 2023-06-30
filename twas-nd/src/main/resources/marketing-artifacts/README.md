<!-- Copyright (c) Microsoft Corporation. -->
<!-- Copyright (c) IBM Corporation. -->

# Purpose: Capture text and images intended for Partner Center offer

## Properties

* Primary category: 

  compute

* Subcategory: 

  Application Infrastructure

* Use standard contract

## Offer listing

* Name

  IBM WebSphere Application Server Cluster
  
* Search results summary

  IBM WebSphere Application Server (Traditional) Network Deployment cluster on Virtual Machines
  
* Short description

  Provisions an IBM WebSphere Application Server (Traditional) Network Deployment cluster on Azure Virtual Machines, including the Deployment Manager, Admin Console, and a specified number of Server Nodes.
  
* Description

This offer automatically provisions several Azure resources to quickly move to WebSphere (Traditional) Application Server on Azure Virtual Machines. The automatically provisioned resources include virtual network, storage, network security group, Java, Linux, and WebSphere. With minimal effort you can provision a fully functional, highly available WebSphere Network Deployment cluster including the Deployment Manager and any number of servers you need. This offer automatically provisions the latest Red Hat Enterprise Linux, IBM Java SDK 8, and WebSphere 9.0.5 to ensure your VM has the latest fixes.


The Deployment Manager and all servers are started by default, which allows you to begin managing the cluster right away using the Admin Console. For complete instructions, please follow the official [WebSphere documentation](https://www.ibm.com/docs/was-nd/9.0.5).

This offer is Bring-Your-Own-License. You will be required to enter your registered IBM ID prior to successfully deploying this offer and your IBM ID must have active WebSphere entitlements associated with it. If you find that provisioning fails due to lack of entitlements, please contact the primary or secondary contacts for your IBM Passport Advantage Site who should be able to grant you access. This offer also assumes you are properly licensed to run offers in Microsoft Azure.

WebSphere Solutions Overview
The IBM WebSphere product portfolio is a set of industry-leading runtimes powering some of the most mission critical enterprise applications across geographies and environments. The WebSphere portfolio includes WebSphere (Traditional) Application Server, WebSphere Liberty, and Open Liberty.

WebSphere products are key components in enabling enterprise Java workloads on Azure. IBM and Microsoft are working on a set of jointly developed and supported solutions for the product family. Potential offers include Open Liberty on Azure Red Hat OpenShift (ARO), WebSphere Liberty on ARO, WebSphere Application Server (traditional) on Virtual Machines, Open Liberty on the Azure Kubernetes Service (AKS), and WebSphere Liberty on AKS.

If you want to provide feedback on these offers, stay updated on the roadmap, or work closely on your migration scenarios with the engineering team developing these offers, select the CONTACT ME button on the marketplace offer [overview page](https://aka.ms/websphere-on-azure). The opportunity to collaborate on a migration scenario is free while the offers are under active development.

The currently available offers are listed in the Learn More section at the bottom of the [overview page](https://aka.ms/websphere-on-azure).
* Privacy policy link

  https://www.ibm.com/privacy/us/en/
  
* Customer support links

  * Azure Global support website
  
    https://www.ibm.com/developerworks/websphere/support/
    
  * Azure Government support website
  
    https://www.ibm.com/developerworks/websphere/support/
    
## Preview audience

* See internal list.

## Plan overview

* Plan ID 2021-06-03-ihs-base-image

* License model Bring your own license

* Availability Public

### 2021-04-27-twas-cluster-base-image

* Plan setup

  * Azure Global
  
* Plan listing

  * Plan name

    cluster

  * Plan summary

    Provisions an IBM WebSphere Application Server (Traditional) Network Deployment cluster

  * Plan description

    Provisions an IBM WebSphere Application Server (Traditional) Network Deployment cluster including the Deployment Manager, Admin Console, and a specified number of Server Nodes.
  
* Pricing and availibility

  * Markets
  
    Your plan will be available for users in the 142 of 142 markets to deploy this offer in any of the Azure regions.

  * Pricing
  
    Bring your own license
    
* Plan visibility

  * Public
  
* Hide plan

  * **CHECKED** This is extremely important to check.
  
* Technical configuration

   * Operating system
   
      Linux

   * Vendor
   
      Red Hat Enterprise Linux
      
   * OS friendly name
   
      RHEL_8_4
      
* Recommended VM sizes

   * A1 Standard
   * D2 Standard v3
   * D1 Standard
   * D2s Standard v3
   * D1 Standard v2
   
* The following public ports are added to all VMs...

   No additional ports.
   
* Properties

   * Only checked is "Supports extensions".
   
* Generations

   * Generation type
   
      Generation 1
      
* VM images

   * Disk version
   
      9.0.2021052001

   * Select a method to provide your VM image

      * SAS URI

         https://storage8602096754.blob.core.windows.net/vhds/was8602096754.vhd?st=2021-05-19T12%3A15Z&se=2021-06-19T12%3A15Z&sp=rl&sv=2018-11-09&sr=c&sig=redacted


      * Data disk number

         Data disk 0

      * Data disk VHD link

         https://storage8602096754.blob.core.windows.net/vhds/was8602096754datadisk1.vhd?st=2021-05-19T12%3A15Z&se=2021-06-19T12%3A15Z&sp=rl&sv=2018-11-09&sr=c&sig=redacted

# Co-sell with Microsoft

* Left at defaults

# Resell through CSPs

* Left at defaults
