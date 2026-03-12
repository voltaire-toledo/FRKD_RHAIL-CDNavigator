# Denial Navigator — Installation Guide

This document consolidates all installation steps for the Claims Denial Navigator solution. It is intended to replace scattered instructions across multiple READMEs and provide a single, authoritative reference for new deployers.

> **Scope**: This guide covers Azure resource provisioning, Power Apps solution import, SharePoint setup, and code-definition data upload. It does **not** cover Power Automate automation or custom EHR integration.

---

## Table of Contents

- [Denial Navigator — Installation Guide](#denial-navigator--installation-guide)
  - [Table of Contents](#table-of-contents)
  - [Prerequisites](#prerequisites)
  - [Architecture Overview](#architecture-overview)
  - [Step 1 — Provision Azure Resources](#step-1--provision-azure-resources)
    - [1.1 Edit Required Variables](#11-edit-required-variables)
    - [1.2 Run the Script](#12-run-the-script)
    - [1.3 Expected Outputs](#13-expected-outputs)
    - [1.4 Collect Values for Later](#14-collect-values-for-later)
  - [Step 2 — Create the SharePoint Document Library](#step-2--create-the-sharepoint-document-library)
    - [Required Library Columns](#required-library-columns)
    - [Record Your SharePoint Details](#record-your-sharepoint-details)
  - [Step 3 — Pack the Power Apps Solution](#step-3--pack-the-power-apps-solution)
    - [3.0 Source vs. Bundle Distinction](#30-source-vs-bundle-distinction)
    - [3.1 Clone the Repository](#31-clone-the-repository)
    - [3.2 Install Power Platform CLI](#32-install-power-platform-cli)
    - [3.3 Pack the Solution](#33-pack-the-solution)
  - [Step 4 — Import the Solution into Power Apps](#step-4--import-the-solution-into-power-apps)
  - [Step 5 — Configure the App](#step-5--configure-the-app)
  - [Step 6 — Upload Code Definitions](#step-6--upload-code-definitions)
  - [Environment Variable Reference](#environment-variable-reference)
  - [Troubleshooting](#troubleshooting)
    - [Azure Deployment Fails](#azure-deployment-fails)
    - [JSON Gets Cut Off in Claims Processing](#json-gets-cut-off-in-claims-processing)
    - [Power Apps Import Fails](#power-apps-import-fails)
    - [Search Indexes Not Populating](#search-indexes-not-populating)
    - [App Shows Blank SharePoint iFrame](#app-shows-blank-sharepoint-iframe)
    - [Dashboard List in Step 5 Is Very Slow to Load](#dashboard-list-in-step-5-is-very-slow-to-load)

---

## Prerequisites

Before starting, ensure you have the following:

| Requirement | Notes |
|---|---|
| **Azure subscription** | You need Owner or Contributor rights to create resources. |
| **Azure tenant ID** | Found in the Azure portal under **Microsoft Entra ID > Overview**. See [how to find it](https://learn.microsoft.com/en-us/azure/azure-portal/get-subscription-tenant-id). |
| **Azure subscription ID** | Found in **Subscriptions** in the Azure portal. |
| **PowerShell** | Version 5.1+ or PowerShell 7+. Run `$PSVersionTable.PSVersion` to check. |
| **Azure CLI** | Run `az --version` to check. Use [`InstallAzureCLI.ps1`](../azureresources/InstallAzureCLI.ps1) to install if missing (Windows only). |
| **Power Platform CLI (`pac`)** | Recommended: Install the **Power Platform VS Code Extension**. Alternatively, use `dotnet tool install --global Microsoft.PowerApps.CLI.Tool`. |
| **Microsoft 365 license** | SharePoint is included in standard M365 plans. |
| **Power Apps Premium license** | Required for each user of the app. See [Licensing overview](https://learn.microsoft.com/en-us/power-platform/admin/pricing-billing-skus). |

!!! Note:
    The method of useing `npm install -g @microsoft/powerplatform-cli` was phased out in November 2023. Please refer to the [Microsoft Installation Instructions](https://learn.microsoft.com/en-us/power-platform/developer/cli/introduction?WT.mc_id=power-81315-dlaskewitz&tabs=linux-macos#install-microsoft-power-platform-cli) to determine which method to use to install the `pac` CLI command.
---

## Architecture Overview

The Denial Navigator uses the following Azure and Microsoft 365 services:

```
User uploads 835 file to SharePoint
        ↓
Power Automate (Cloud Flow) picks up the file
        ↓
Azure OpenAI parses the 835 text and extracts claim data
        ↓
Azure AI Search indexes parsed data and policy documents
        ↓
Azure OpenAI generates denial recommendations
        ↓
Results stored in Dataverse tables
        ↓
User reviews recommendations in the Model-Driven Power App
```

**Azure resources provisioned by `AddResource.ps1`:**

| Resource | Purpose |
|---|---|
| Azure Storage Account | Holds `parse` and `recs` blob containers for 835 files and policy documents |
| Azure OpenAI (GPT model) | Parses 835 claim text; generates denial recommendations |
| Azure AI Search Service | Indexes documents and parsed claims for retrieval-augmented generation |
| Deployment Script | Runs as part of the Bicep deployment to initialize resources |

---

## Step 1 — Provision Azure Resources

### 1.1 Edit Required Variables

Open `azureresources/AddResource.ps1` in a text editor and update the following variables near the top of the script:

| Variable | Description | Example |
|---|---|---|
| `newRG` | Name for the new Azure Resource Group. Letters, numbers, and dashes only. | `"DenialNavigator-RG"` |
| `loc` | Azure region closest to your organization. | `"East US 2"` |
| `tenant` | Your Azure tenant ID (GUID). | `"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"` |
| `sub` | Your Azure subscription ID (GUID). | `"yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"` |

> **Note**: `bicepFile` defaults to `.\main.bicep` and does not need to be changed if you run the script from the `azureresources/` folder.

### 1.2 Run the Script

Open a PowerShell window in the `azureresources/` folder and run:

```bash
cd .\azureresources
.\AddResource.ps1
```

The script will:

1. Log you in to Azure (a browser window will open for authentication).
2. Set your subscription as the default.
3. Create the new resource group.
4. Deploy Azure Storage, Azure OpenAI, and Azure AI Search via the Bicep template (`main.bicep`).
5. Automatically call `IndexResource\SetupSearchService_v1.ps1` to create indexes, data sources, and indexers.

### 1.3 Expected Outputs

When complete, the following resources will exist in the new resource group:

- **Storage Account** with containers `parse` and `recs`
- **Azure OpenAI** account and a GPT model deployment
- **Azure AI Search** service with indexes:
  - `filerecs-autocreate`
  - `parse-autocreate`
- Indexers:
  - `indexerparse-autocreate`
  - `indexerrec-autocreate` _(note: the Bicep README has a display typo `auotcreate` — this is cosmetic only)_
- Data sources connected to the `parse` and `recs` containers

### 1.4 Collect Values for Later

After the deployment completes, note the following values from the Azure portal or deployment output. You will need them when importing the Power Apps solution:

| Value | Where to find it |
|---|---|
| **Azure Blob Storage Account Name** | Storage Account > **Overview** |
| **Azure Search Service URL** | AI Search > **Overview** — format: `https://<name>.search.windows.net` |
| **Azure Search Service API Key** | AI Search > **Keys** > Primary admin key |
| **Azure OpenAI API URL** | Azure OpenAI > **Overview** — format: `https://<name>.openai.azure.com/` |
| **Azure OpenAI API Key** | Azure OpenAI > **Keys and Endpoint** > Key 1 |
| **Parse Index name** | `parse-autocreate` (default) |
| **Recs Index name** | `filerecs-autocreate` (default) |

---

## Step 2 — Create the SharePoint Document Library

A SharePoint document library is required for file intake. Power Automate monitors this library and triggers processing when a new file is uploaded.

### Required Library Columns

Create or configure a SharePoint library with the following columns:

| Column Type | Internal Name | Required |
|---|---|:---:|
| Single line of text | `Name` | Yes (Default) |
| Multiple lines of text | `Message` | Yes |
| Date and Time | `Modified` | System |
| Person | `ModifiedBy` | System |

> **Note**: `Name`, `Modified`, and `ModifiedBy` are standard SharePoint columns. `Name` is required by default, while `Modified` and `ModifiedBy` are managed automatically by the system; you do not need to (and cannot) manually set their "Required" property.

### Record Your SharePoint Details

After creating the library, note:

| Value | Example |
|---|---|
| **SharePoint Site URL** | `https://mytenant.sharepoint.com/sites/PatientFinancialServcies` |
| **Library Name** | `RHAILClaimFiles` |

---

## Step 3 — Pack the Power Apps Solution

### 3.0 Source vs. Bundle Distinction
> **Important**: If you have seen the installation video, you may notice a ZIP file containing PDFs and folders. That is a **Deployment Bundle**. This repository contains the **Source Code**. 
> 
> The `pac solution pack` command creates the **Power Platform Solution Zip** (the App and Flows). You must handle Azure Storage assets (like PDFs for the `recs` container) separately by uploading them via the Azure Portal.

The solution source code is located in the `solution_1.15.0.33/` folder. This directory contains the unpacked XML, JSON, and YAML files that define the application.

### 3.1 Clone the Repository

```bash
git clone https://github.com/voltaire-toledo/FRKD_RHAIL-CDNavigator.git
cd FRKD_RHAIL-CDNavigator
```

### 3.2 Install Power Platform CLI

If not already installed:

```bash
dotnet tool install --global Microsoft.PowerApps.CLI.Tool
```

Verify:

```bash
pac test
pac tool list
```

### 3.3 Pack the Solution

Open a terminal in the repository root and run the following command. This uses the Power Platform CLI to aggregate the source files into a single unmanaged solution file.

```bash
cd ..
pac solution pack --folder .\solution\ --zipfile .\solution\CDN-MainBranch.zip --packagetype Unmanaged
```

**Expected output**: A file named `ClaimsDenialNavigator.zip` is created in the repository root.

!!! Note:
    If you want to try the older version, use the `./src/ClaimsDenialNavigatorSoltuion/RHAIL_1_15_0_22.zip`

> **Options**:
> - `--packagetype Unmanaged` — use for development environments where you want to edit the solution after import.
> - `--packagetype Managed` — use for production environments.

---

## Step 4 — Import the Solution into Power Apps

1. Open [https://make.powerapps.com](https://make.powerapps.com) in a browser.
2. Sign in with an account that has **System Administrator** or **System Customizer** role in the target environment.
3. In the left-hand menu, select **Solutions**.
4. Select **Import solution** > **Browse**, then select `RHAIL_1_15_0_22.zip`.

   ![Upload Solution](../assets/appuploadsolution.png)

5. Click **Next**. On the **Connections** step, create or select a connection for each of the five required connections. The goal is to have all connections show a green checkmark before proceeding to the next step. You may need to create new connections if you do not have existing ones with the correct permissions.
   
    i. For the **Azure Blob Storage** connection, you will need the storage account name and key from the Azure portal. When creating the connection, select "Connect using on-premises data gateway" and provide the storage account name as the gateway URL and the storage account key as the authentication key.
    ![Create BlobStorage Connection](../assets/img-sol-connections-blob.png)
    ![Azure BlobStorage Configuartion](../assets/img-sol-connections-blob-config.png)
    ![Zero Green](../assets/img-sol-connections-zerogreen.png)

  
6. On the **Environment Variables** step, fill in the values collected in [Step 1.4](#14-collect-values-for-later) and [Step 2](#step-2--create-the-sharepoint-document-library):

   | Environment Variable | Maps to table in AzResources-###.md  |
   |---|:---|
   | Azure Search Index URL | `searchServiceEndpoint` |
   | Azure Search Index API Key | `searchServiceQueryKey` |
   | Azure Open AI API URL | `openAIEndpoint` |
   | Azure Open AI API Key | `openAIAPIKey` |
   | Azure Storage Account Name | `storageAccountName` |
   | Sharepoint Doc Site | SharePoint site URL from Step 2 |
   | Sharepoint Library Name | Library name from Step 2 |
   | File Recommendation Index | `filerecs-autocreate` |
   | File Parsing Index | `parse-autocreate` |

   ![Environment Variables](../assets/appenvvariable.png)

7. Select **Import** and wait for the process to complete.

!!! Note:
    This can take several minutes to complete. There is no progress bar, but you can monitor the status in the Power Apps portal. If you see any errors during import, review the error messages carefully as they often indicate missing connections or environment variables.

If the following occurs, it means the solution was imported successfully but the connections were not configured correctly. You can determine which connection may be fix this by going to **Data > Connections** in the Power Apps portal and creating new connections with the correct credentials, then re-importing the solution.
![PowerApp Warning](../assets/non-critical-warning-powerapps.png)

---

## Step 5 — Configure the App

After import, you must update the SharePoint iFrame embedded in the app dashboard to point to your library.

1. In Power Apps, navigate to your solution and select **Dashboards > Claim Navigator for 835 File**.

   ![Dashboard](../assets/appdash.png)

2. Select the **IFrame: File Upload** component, then click **Edit Component**.

   ![iFrame](../assets/appiframe.png)

3. In the **Edit Component** dialog, update the URL to match your SharePoint document library URL. Close and Save.

   ![iFrame2](../assets/appiframe2.png)

4. In the solution view, select **Apps > Denial Navigator**.
5. Select **Publish** and wait for publishing to complete.
6. Select **Play** and navigate to the file intake section to confirm the embedded SharePoint site is displayed correctly.

---

## Step 6 — Upload Code Definitions

CARC and RARC code definitions must be loaded into Dataverse to enable the app to display denial reason explanations.

1. Download `data/rhail_codedefinitions.csv` from this repository.
2. In Power Apps, navigate to the solution and find the **Code Definitions** Dataverse table.
3. Select **Import** > **Import Data**, then select the CSV file.

   ![Import Step 1](../assets/uploadcodes_1.png)
   ![alt text](image.png)

   !!! Warning
         Do NOT select "Allow duplicates" as this will cause issues with lookups in the app. The import process does not enforce uniqueness, so if you accidentally import duplicates, you will need to manually delete the duplicate records from the `rhail_CodeDefinition` table in Dataverse.


4. Click through until you reach **Destination settings**. Confirm the target table is `rhail_CodeDefinition`.

    !!! Danger
        This is an invalid screenshot

   ![Import Step 2](../assets/uploadcodes_2.png)



1. Confirm column mappings match the table schema shown.

   ![Import Step 3](../assets/uploadcodes_3.png)

2. Submit and confirm the data loads successfully.

---

## Environment Variable Reference

All nine Power Apps environment variables must be set for the solution to function:

| Variable Name | Description | Where to Get Value |
|---|---|---|
| `Azure Blob Storage Name` | Storage account name | Azure portal > Storage Account > Overview |
| `Azure Search Service API Key` | Admin API key for AI Search | Azure portal > AI Search > Keys |
| `Azure Search Service URL` | AI Search endpoint URL | Azure portal > AI Search > Overview |
| `AzureOpenAi API Key` | Key for Azure OpenAI | Azure portal > Azure OpenAI > Keys and Endpoint |
| `AzureOpenAi API URL` | Endpoint URL for Azure OpenAI | Azure portal > Azure OpenAI > Keys and Endpoint |
| `Parse Index` | Name of the parse index | `parse-autocreate` (created by script) |
| `Recs Index` | Name of the recs index | `filerecs-autocreate` (created by script) |
| `Sharepoint Doc Site` | URL of SharePoint site | Your SharePoint admin |
| `Sharepoint Library Name` | Name of document library | Your SharePoint admin |

---

## Troubleshooting

### Azure Deployment Fails

- **Authentication error**: Ensure you are logged in to the correct tenant. The script calls `az login --tenant <tenant>`. If you have multiple accounts, verify with `az account show`.
- **Insufficient permissions**: You need **Owner** or **Contributor** role on the subscription to create resource groups and deploy resources.
- **Region availability**: Not all Azure regions support all OpenAI model versions. If deployment fails, try a different region (change `loc`). See [Azure OpenAI model availability](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models).
- **Quota limits**: Your subscription may have zero quota for the requested OpenAI model. Request quota increases via the Azure portal before running the script.

### JSON Gets Cut Off in Claims Processing

The default `max_tokens` setting in the Parse 835 child flow may be too low. Edit the flow and add `"max_tokens": 16000` to the Azure OpenAI request body.

### Power Apps Import Fails

- **Connections not completing**: Ensure you have the correct permissions for each connection type. SharePoint connections require access to the target site. Azure Blob Storage connections require the storage account key.
- **Missing environment variables**: All nine environment variables must be filled before import will succeed.

### Search Indexes Not Populating

- Confirm the Azure AI Search indexers ran successfully. In the Azure portal, navigate to your AI Search service > **Indexers** and check the run history.
- If indexers report errors, verify that the storage account connection string in the data sources is correct.

### App Shows Blank SharePoint iFrame

The iFrame URL was not updated post-import. Return to [Step 5](#step-5--configure-the-app) and update the URL to your SharePoint document library.

### Dashboard List in Step 5 Is Very Slow to Load

The modern maker portal loads all solution component metadata before rendering the dashboard list, which can take several minutes. Use one of these faster alternatives:

- **Filter by type**: In your solution's object list, use the **Type** filter and select **Dashboard**. The filtered view loads significantly faster.
- **Use the classic interface**: Navigate to `https://<your-org>.crm.dynamics.com/main.aspx`, then go to **Settings** > **Customizations** > **Customize the System** and expand **Dashboards** in the left tree.
- **Direct URL**: While in your solution in [make.powerapps.com](https://make.powerapps.com), note the environment and solution IDs from the browser address bar and navigate directly to `https://make.powerapps.com/environments/<env-id>/solutions/<solution-id>/dashboards`.

---

> **Disclaimer**: This code is provided *as is* without warranty of any kind. See [LICENSE](../LICENSE) for details.
