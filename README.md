# Azure Virtual Machine offers for IBM WebSphere traditional and supporting components

This repository contains code which creates [Microsoft Partner Center](https://partner.microsoft.com/) ready offers of type [Azure virtual machine](https://learn.microsoft.com/en-us/partner-center/marketplace/publisher-guide-by-offer-type#list-of-offer-types). These are called "VM offers" for discussion. The following sub-directories are self contained VM offers.

- [Deploy an Azure VM with RHEL, IBM HTTP Server V9.0 & IBM JDK 8.0 pre-installed](/ihs)
- [Deploy an Azure VM with RHEL, IBM WebSphere Application Server Traditional V9.0.5 & IBM JDK 8.0 pre-installed](/twas-base)
- [Deploy an Azure VM with RHEL, IBM WebSphere Application Server ND Traditional V9.0.5 & IBM JDK 8.0 pre-installed](/twas-nd)

These VM offers are consumed by the following related offers of type [Azure Application solution template](https://learn.microsoft.com/en-us/partner-center/marketplace/publisher-guide-by-offer-type#list-of-offer-types).

- [Deploy RHEL VM on Azure with IBM WebSphere Application Server traditional V9.0.5 singleserver pre-installed](https://github.com/WASdev/azure.websphere-traditional.singleserver)
- [Deploy RHEL VMs on Azure with IBM WebSphere Application Server ND Traditional V9.0.5 cluster pre-installed](https://github.com/WASdev/azure.websphere-traditional.cluster)

## Automated Publishing of Azure virtual machine and Azure Application offers

This repository and the related repositories have GitHub Actions workflows that package, test, and publish these offers to Microsoft Partner Center. For the definitive guide to this automation, see [GitHub Actions automation](docs/howto-update-image.md).
