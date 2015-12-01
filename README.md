# Azure-RM-Templates

This repository provides some samples for **Infrastructure as a Code** (using RM templates) in order to provision VM, Web Sites with Deployment slots, Virtual Networks, SQL server, Service Bus etc. The samples can be use to automate the CI process where the entire infrastructure for a typical application can be build on Azure.

#### Requirement

Before you begin, you need to have a storage account that will be used to store the RM templates before it starts deployment on Azure. Assuming the Azure Subscription is already available.

#### Service Bus

The Script will create the service bus using Power shell CMDLET, the Azure RM templates do not support provisioning services buses yet, *As of Today (12/1/2015)*.

#### Web Sites

The samples create two web site with one deployment slot for each. The samples will also assign the service bus connection strings, SQL Azure connection strings to the application configurations, both for the production and staging slots. 

#### Virtual Networks

The samples will also create virtual networks where two virtual machines are provisioned. 

#### Virtual Machines

The samples will provision two VMs, one Windows VM and an Ubuntu VM. Uses a VM Extensions to allow further configuration needed for a VM (using a bash script). 

#### How to Run?

Go to the script folder, correct the parameters as they fit your situation and execute the powershell script named **Go.ps1** from a Power Shell command window. Hit **enter**, sit back and relax for 10 minutes or so...everything will be okay.
