<!-- Copyright (c) Microsoft Corporation. -->
<!-- Copyright (c) IBM Corporation. -->

# How to update the CRM connection string

Microsoft Partner Center allows you to connect a CRM system to capture leads when customers interact with your offers. For the official documentation, see [Customer leads from your commercial marketplace offer](https://learn.microsoft.com/en-us/partner-center/marketplace/partner-center-portal/commercial-marketplace-get-customer-leads).

The IBM offers use this feature in two ways.

1. As the CRM system in the [CONTACT ME](https://partner.microsoft.com/en-us/dashboard/commercial-marketplace/offers/ef053efe-304c-4a35-b125-9d5b940ae520/overview) offer.
1. As the CRM system in the Azure Application and Azure Virtual Machine offers.

In both cases, the CRM system uses the facility documented at [Connect to your CRM system](https://learn.microsoft.com/en-us/partner-center/marketplace/partner-center-portal/commercial-marketplace-get-customer-leads#connect-to-your-crm-system). The documentation does not explain how to connect **Azure Table**, but does say **Azure Table** is supported. 

## How to get the connection string.

1. Sign in to the [Azure Portal](https://aka.ms/publicportal).
1. Ensure you have selected the correct subscription, WAS-MSFT-TEAM.
1. Select the hamburger menu and select **Storage accounts**.
1. Select the row with the **Name** that contains **customerleads**.
1. Under **Security + networking**, select **Access keys**.
1. Next to **Connection string**, select **Show**. You can use either **key1** or **key2**.
1. Select the copy icon to copy the value to the clipboard.

## Where to put the connection string in partner center.

1. Sign in to Partner center.
1. Select the offer.
1. Select **Offer setup**.
1. Under **Customer leads** select **Connect**.
1. Select the drop down menu for **Lead destination** and select **Azure Table**.
1. Paste the value you copied from the preview section.
1. Select **Validate**.
1. Successful validation should include text similar to, "You have successfully connected to the lead destination."
1. Select **Connect**.
1. Select **Save draft**.
