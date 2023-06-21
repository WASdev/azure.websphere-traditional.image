# GitHub Actions automation

This automation aims to simplify the process for keeping the Partner Center offers for WebSphere traditional up to date, with the latest fix packs, iFixes, yum updates, etc. At a high level, the least-effort update involves the following steps.

- Incrementing the versions in several `pom.xml` files.
- Updating a property in a few JSON files.
- Running a few GitHub Actions workflows.
- Selecting a few buttons in Partner Center.

This document describes two different approaches for causing an update to the code in this repository to be packaged, published and made available to users in Partner Center.

   - The automated process
   - The manual process.

Use of the processes is not mutually exclusive. Both processes share code to avoid DRY violations.  The shared code does a number of "software update" type actions such as `yum update`, installing iFixes, etc.

## The automated process

The GitHub Actions workflows in this repository, and the related repositories referenced in the top level [README](../README.md), automate the process of packaging, testing, and publishing Azure virtual machine and Azure Application offers to Microsoft Partner Center. The automated process does involve a small amount of manual action in Partner Center, as described below.

### Preconditions

<details>
<summary>Both sections of preconditions must be satisfied before running the workflows. [expand for details]</summary>

#### 1. Set the GitHub Actions secrets for the repository running the workflows

The recommended way to set the secrets is to run the scripts.  Setting the secrets manually is beyond the scope of this guide.

##### Preconditions for running the scripts to set the secrets

1. Ensure the Azure CLI is installed on a supported UNIX-like environment. See [How to install the Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli). **Sign in to Azure using the Azure CLI**. After installation, sign in to the correct tenant. The actions will create Azure resources in this signed-in tenant.
1. Ensure the GitHub CLI is installed on the same environment as the preceding step. See [Installation](https://cli.github.com/manual/installation). Note: If working on macOS, we highly recommend Homebrew. Visit https://brew.sh/ for instructions on installing Homebrew. **Authenticate to GitHub**. After installation, use `gh auth login` to sign in to GitHub. You'll need a sufficiently empowered `PERSONAL ACCESS TOKEN` for this repository.
1. Clone this repository into the environment from the preceding steps.

##### Setting the secrets

1. cd `.github/workflows`
1. Run the `setup-credentials.sh` script. This will ask you a series of questions and create the necessary GitHub Actions secrets using the `gh` cli. If this script exits successfully, you should be able to run the workflows successfully. If the script does not exit successfully, troubleshoot and resolve the problem before proceeding.
   Note, the script `tear-down-credentials.sh` is the inverse of `setup-credentials.sh`. It deletes any Azure service principals and roles and any GitHub Actions secrets.

#### 2. Set the GitHub Actions secrets for the related repositories

The related repositories referenced in the top level [README](../README.md) have analogous scripts to set up and tear down credentials. The preconditions and invocation for these scripts are the same as in the preceding section.

</details>

### Running the workflows and publishing the offers

Now that you have satisfied the preconditions **in this repository and related repositories**, you can run the workflows.

### Running the workflows and publishing the offers for WebSphere Application Server traditional Base

<details>
<summary>The steps in this section describe how to run the workflows and publish the VM offer and Azure Application offer for WebSphere Application Server traditional Base. [expand for details]</summary>

#### 1. Increment the version of tWAS Base VM offer in the pom.xml

1. Increment the version of `twas-base/pom.xml`.
1. Push the commit to the branch on which you intend to run the workflow in the next step.

#### 2. Run the workflow for the tWAS Base VM offer

<details>
<summary>Run the workflow to create the tWAS Base VM offer. [expand for details]</summary>

1. Decide on a value for the `imageVersionNumber` parameter. The required syntax for this value is `9.0.YYYYMMDD`. Where `YYYYMMDD` is usually today's date.
1. Visit the [GitHub Actions page for the workflow](https://github.com/WASdev/azure.websphere-traditional.image/actions/workflows/ihsBuild.yml).
1. Select the **Run workflow** dropdown. Enter the value for `imageVersionNumber`.
1. Select **Run workflow**.
1. Observe the execution of the jobs in the workflow.
   - One very important job is **Verify the image**. This job calls another workflow, on the related repository for the Azure Application, but the VM image created by the calling workflow is taken as input to this called workflow.
</details>

If the workflow completes successfully, proceed to the next section. If not, troubleshoot and resolve the problem with guidance from the section on **The manual process** before proceeding.

#### 3. Publish the tWAS Base VM offer in Partner Center

Because the workflow in the preceding section executed successfully, you can assume the VM image is ready to publish in Partner Center.

<details>
<summary>Use Partner Center to publish the VM offer and track to live. [expand for details]</summary>

1. Visit Partner Center at https://partner.microsoft.com/.
1. Sign in to the partner center by selecting the **Partner Center** link in the upper right corner of the page, next to **Search**. You must sign in this way.
1. Select **Marketplace offers**.
1. In the textfield labeled **Search by offer alias and ID**, enter `twas-single-server-base-image`.
1. Select the one and only row. If you see more than one row, consult with management to see which one to select.
1. In the left navigation panel, select **Plan overview**.
1. On the next page, select the one and only plan.
1. On the next page, in the left navigation panel, select **Technical configuration**.
1. In the **VM Images** section, you should see a row whose **Image version** column is the same as the value of `imageVersionNumber` you entered previously. If you do not see this value, troubleshoot and resolve the problem with guidance from the section on **The manual process** before proceeding.
1. The previously run workflow will have updated the technical configuration. Go to the bottom of the page and select **Review and publish**.
1. On the next page, in the text area, paste the URL to the successful GitHub Actions workflow from the preceding section.
1. Select **Publish**.
1. This should take you back to the Offer overview page, but the progress bar will now be partially filled in.
1. The offer will go through the publishing process. 
1. After some hours or maybe days, the offer will enter "preview" state. In this state, you can manually test the offer. The CI/CD has already done sufficient testing, but you can do more if you like.
1. Select the big **Go Live** button.
1. After some hours, or maybe days, the offer will enter "live" state.
</details>


#### 4. Update the source files in the tWAS Base (aka single-server) Azure Application offer

At this point, the tWAS Base Azure VM offer is live. This same VM offer has been tested with the Azure Application offer, but the source code changes to publish a new iteration of the Azure Application offer have not been updated. The steps is this section show how to update the source files to use the new VM offer.

1. Visit the [README](../README.md) and find the link containing the text `singleserver`. Select that link to visit that repository.
1. Increment the version of `pom.xml`.
1. Edit `main/src/main/bicep/config.json`.
   1. Change the value of `twasImageVersion` to be the value entered for `imageVersionNumber` previously.
1. Push the commit to the branch on which you intend to run the workflow in the next step.

#### 5. Run the workflow for the tWAS Base (aka single-server) Azure Application offer

 You can publish the corresponding Azure Application offer that uses that base image.

<details>
<summary>Run the workflow to create the tWAS Base (aka single-server) Azure Application offer. [expand for details]</summary>

1. Visit the [README](../README.md) and find the link containing the text `singleserver`. Select that link to visit that repository.
1. In that repository, select the **Actions** tab.
1. Select the **Package ARM** workflow.
1. Select the **Run workflow** dropdown.
1. Select **Run workflow**.
1. Observe the execution of the jobs in the workflow.
</details>

If the workflow completes successfully, proceed to the next section. If not, troubleshoot and resolve the problem with guidance from the section on **The manual process** before proceeding.

#### 6. Publish the tWAS Base Azure Application offer in Partner Center

Because the workflow in the preceding section executed successfully, you can assume the Azure Application offer is ready to publish in Partner Center.

<details>
<summary>Use Partner Center to publish the Azure Application offer and track to live. [expand for details]</summary>

1. Visit Partner Center at https://partner.microsoft.com/.
1. Sign in to the partner center by selecting the **Partner Center** link in the upper right corner of the page, next to **Search**. You must sign in this way.
1. Select **Marketplace offers**.
1. In the textfield labeled **Search by offer alias and ID**, enter `twas-base-single-server`.
1. Select the one and only row. If you see more than one row, consult with management to see which one to select.
1. In the left navigation panel, select **Plan overview**.
1. On the next page, select the one and only plan.
1. On the next page, in the left navigation panel, select **Technical configuration**.
1. The previously run workflow will have updated the technical configuration. Select **Review and publish**.
1. On the next page, in the text area, paste the URL to the successful GitHub Actions workflow from the preceding section.
1. Select **Publish**.
1. This should take you back to the Offer overview page, but the progress bar will now be partially filled in.
1. The offer will go through the publishing process. 
1. After some hours or maybe days, the offer will enter "preview" state. In this state, you can manually test the offer. The CI/CD has already done sufficient testing, but you can do more if you like.
1. Select the big **Go Live** button.
1. After some hours, or maybe days, the offer will enter "live" state.
</details>

</details>

### Running the workflows for WebSphere Application Server traditional Network Deployment

<details>
<summary>The steps in this section describe how to run the workflows and publish the VM offers and Azure Application offer for WebSphere Application Server ND [expand for details]</summary>

#### 1. Increment the version of ihs VM offer in the pom.xml

1. Increment the version of `ihs/pom.xml`.
1. Push the commit to the branch on which you intend to run the workflow in subsequent steps.

#### 2. Increment the version of tWAS ND VM offer in the pom.xml

1. Increment the version of `twas-nd/pom.xml`.
1. Push the commit to the branch on which you intend to run the workflow in subsequent steps.

#### 3. Run the workflow for the ihs VM offer

<details>
<summary>Run the workflow to create the IHS VM offer. [expand for details]</summary>

1. Decide on a value for the `imageVersionNumber` parameter. The required syntax for this value is `9.0.YYYYMMDD`. Where `YYYYMMDD` is usually today's date.
1. Visit the [GitHub Actions page for the workflow](https://github.com/WASdev/azure.websphere-traditional.image/actions/workflows/ihsBuild.yml).
1. The remaining steps are the same as in the section **Run the workflow for the tWAS Base VM offer**.
</details>

If the workflow completes successfully, proceed to the next section. If not, troubleshoot and resolve the problem with guidance from the section on **The manual process** before proceeding.

#### 4. Run the workflow for the tWAS ND VM offer

<details>
<summary>Run the workflow to create the tWAS ND VM offer. [expand for details]</summary>

1. Decide on a value for the `imageVersionNumber` parameter. The required syntax for this value is `9.0.YYYYMMDD`. Where `YYYYMMDD` is usually today's date.
1. Visit the [GitHub Actions page for the workflow](https://github.com/WASdev/azure.websphere-traditional.image/actions/workflows/twas-ndBuild.yml).
1. The remaining steps are the same as in the section **Run the workflow for the tWAS Base VM offer**.
</details>

If the workflow completes successfully, proceed to the next section. If not, troubleshoot and resolve the problem with guidance from the section on **The manual process** before proceeding.

#### 5. Publish the offers in Partner Center

Because the workflows in the preceding sections executed successfully, you can assume the VM images are ready to publish in Partner Center.

<details>
<summary>Use Partner Center to publish the VM offers for IHS and tWAS ND and track to live. [expand for details]</summary>

1. Visit Partner Center at https://partner.microsoft.com/.
1. Sign in to the partner center by selecting the **Partner Center** link in the upper right corner of the page, next to **Search**. You must sign in this way.
1. Select **Marketplace offers**.
1. In the textfield labeled **Search by offer alias and ID**, enter `ihs-base-image`.
1. Select the one and only row. If you see more than one row, consult with management to see which one to select.
1. In the left navigation panel, select **Plan overview**.
1. On the next page, select the one and only plan.
1. On the next page, in the left navigation panel, select **Technical configuration**.
1. In the **VM Images** section, you should see a row whose **Image version** column is the same as the value of `imageVersionNumber` you entered previously **for IHS and for tWAS ND**. If you do not see this value, troubleshoot and resolve the problem with guidance from the section on **The manual process** before proceeding.
1. The previously run workflow will have updated the technical configuration. export Go to the bottom of the page and select **Review and publish**.
1. On the next page, in the text area, paste the URL to the successful GitHub Actions workflow from the preceding section.
1. Select **Publish**.
1. This should take you back to the Offer overview page, but the progress bar will now be partially filled in.
1. The offer will go through the publishing process.
1. Return to the **Marketplace offers | Overview** page by selecting **Marketplace offers** in the breadcrumb navigation in the top left of the screen.
1. Return to step 4, but enter `twas-cluster-base-image` in the textfield. Continue the remaining steps up to and including 14. Be sure to use the correct `imageVersionNumber` value for tWAS ND.
1. After some hours or maybe days, the offers will enter "preview" state. In this state, you can manually test the offer. The CI/CD has already done sufficient testing, but you can do more if you like.
1. For each of the two offers you published previously, select the big **Go Live** button.
1. After some hours, or maybe days, the offer will enter "live" state.
</details>



</details>




#### 6. Update the source files in the tWAS ND (aka cluster) Azure Application offer

At this point, the tWAS ND and IHS Azure VM offers are live. These same VM offers have already been tested via CI/CD with the Azure Application offer, but the source code changes to publish a new iteration of the Azure Application offer have not been updated. The steps is this section show how to update the source files to use the new VM offer.

1. Visit the [README](../README.md) and find the link containing the text `cluster`. Select that link to visit that repository.
1. Increment the version of `pom.xml`.
1. Edit `main/src/main/bicep/config.json`.
   1. Change the value of `ihsImageVersion` to be the value entered for `imageVersionNumber` when you created the IHS image previously.
   1. Change the value of `twasNdImageVersion` to be the value entered for `imageVersionNumber` when you created the tWAS ND image previously.
1. Push the commit to the branch on which you intend to run the workflow in the next step.


#### 7. Run the workflow for the tWAS ND (aka cluster) Azure Application offer

 You can publish the corresponding Azure Application offer that uses the base images for IHS and tWAS ND.

<details>
<summary>Run the workflow to create the tWAS ND (aka cluster) Azure Application offer. [expand for details]</summary>

1. Visit the [README](../README.md) and find the link containing the text `cluster`. Select that link to visit that repository.
1. In that repository, select the **Actions** tab.
1. Select the **Package ARM** workflow.
1. Select the **Run workflow** dropdown.
1. Select **Run workflow**.
1. Observe the execution of the jobs in the workflow.
</details>

If the workflow completes successfully, proceed to the next section. If not, troubleshoot and resolve the problem with guidance from the section on **The manual process** before proceeding.



#### 8. Publish the tWAS ND Azure Application offer in Partner Center

Because the workflow in the preceding section executed successfully, you can assume the Azure Application offer is ready to publish in Partner Center.

<details>
<summary>Use Partner Center to publish the Azure Application offer and track to live. [expand for details]</summary>

1. Visit Partner Center at https://partner.microsoft.com/.
1. Sign in to the partner center by selecting the **Partner Center** link in the upper right corner of the page, next to **Search**. You must sign in this way.
1. Select **Marketplace offers**.
1. In the textfield labeled **Search by offer alias and ID**, enter `twas-cluster`.
1. There may be more than one row. Select the one in the whose **Offer type** is **Azure Application**. If you see more than one row with type **Azure Application**, consult with management to see which one to select.
1. In the left navigation panel, select **Plan overview**.
1. On the next page, select the one and only plan.
1. On the next page, in the left navigation panel, select **Technical configuration**.
1. The previously run workflow will have updated the technical configuration. Select **Review and publish**.
1. On the next page, in the text area, paste the URL to the successful GitHub Actions workflow from the preceding section.
1. Select **Publish**.
1. This should take you back to the Offer overview page, but the progress bar will now be partially filled in.
1. The offer will go through the publishing process. 
1. After some hours or maybe days, the offer will enter "preview" state. In this state, you can manually test the offer. The CI/CD has already done sufficient testing, but you can do more if you like.
1. Select the big **Go Live** button.
1. After some hours, or maybe days, the offer will enter "live" state.
</details>

</details>


## The manual process

See these links for guidance on how to update VM images.

1. For image `twas-base`, see [this](https://github.com/WASdev/azure.websphere-traditional.singleserver/blob/main/docs/howto-update-for-was-fixpack.md#updating-the-image).
1. For images `twas-nd` and `ihs`, see [this](https://github.com/WASdev/azure.websphere-traditional.cluster/blob/main/docs/howto-update-for-was-fixpack.md#updating-the-image).

## Troubleshooting

- Certification failure
