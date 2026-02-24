# Denial Navigator - Verified Azure Deployment Guide

This guide provides step-by-step instructions to deploy the Denial Navigator solution, verified against the Version 1 release artifacts.

## Table of Contents
- [Denial Navigator - Verified Azure Deployment Guide](#denial-navigator---verified-azure-deployment-guide)
  - [Table of Contents](#table-of-contents)
  - [Prerequisites](#prerequisites)
  - [Step 1: Azure Resource Deployment](#step-1-azure-resource-deployment)
  - [Step 2: SharePoint Configuration](#step-2-sharepoint-configuration)
  - [Step 3: Power Apps Solution Import](#step-3-power-apps-solution-import)
  - [Step 4: App Configuration](#step-4-app-configuration)
  - [Step 5: Data Import (Code Definitions)](#step-5-data-import-code-definitions)
  - [Final Verification](#final-verification)

---

## Prerequisites

- **Azure Subscription**: Owner or Contributor access.
- **Power Apps License**: Premium per-user license or equivalent.
- **SharePoint Online**: Permission to create sites/libraries.
- **Software**: PowerShell (v5.1 or 7+) and Azure CLI installed.

---

## Step 1: Azure Resource Deployment

This step provisions the required Azure Storage, OpenAI, and Search services.

1.  **Locate Scripts**: Navigate to the `azureresources` folder in your repository.
2.  **Configure Script**:
    - Open `AddResource.ps1`.
    - Update the following variables:
        ```powershell
        $newRG = "Your-Resource-Group-Name" # e.g., DenialNavigator-RG
        $loc = "East US 2"                  # Ensure region supports GPT-4o
        $tenant = "Your-Tenant-ID"          # Found in Azure Active Directory overview
        $sub = "Your-Subscription-ID"       # Found in Azure Subscriptions
        ```
3.  **Run Deployment**:
    - Open PowerShell and execute:
        ```powershell
        .\AddResource.ps1
        ```
    - Sign in to Azure when prompted.
4.  **Verify Outputs**:
    - Ensure the script completes with "Resources created!" and "Indexes created!".
    - Note the **Resource Group Name** and newly created resource names; you will need these for the Power Apps import.

---

## Step 2: SharePoint Configuration

1.  **Create Site**: Create a new SharePoint Team Site (e.g., "Denial Navigator").
2.  **Create Library**: Create a new Document Library named **`835 Files`** (or your preferred name).
3.  **Add Columns**:
    - The solution requires specific metadata columns. Ensure the following exist (add if missing):
        - `Name` (Default)
        - `Message` (Multiple lines of text)
4.  **Copy URL**: Note the URL of your SharePoint site (e.g., `https://yourtenant.sharepoint.com/sites/DenialNavigator`).

---

## Step 3: Power Apps Solution Import

1.  **Access Power Apps**: Go to [make.powerapps.com](https://make.powerapps.com).
2.  **Import**:
    - Click **Solutions** > **Import solution**.
    - Browse and select the file **`src/ClaimsDenialNavigator.zip`** created in the repository root (packed from the `src/ClaimsDenialNavigatorSolution/` directory).
3.  **Configure Connections**:
    - You will be prompted to verify connections. Sign in to:
        - Azure Blob Storage (Use Storage Account Name and Access Key from Azure Portal).
        - SharePoint.
        - Dataverse.
        - Content Conversion.
4.  **Set Environment Variables**:
    Fill in the values using the resources created in Step 1:
    - **Azure Blob Storage Name**: Name of your created Storage Account.
    - **Azure Search Service API Key**: Admin Key from Azure AI Search service.
    - **Azure Search Service URL**: `https://[Your-Search-Service-Name].search.windows.net`.
    - **AzureOpenAI API Key**: Key 1 or 2 from Azure OpenAI resource.
    - **AzureOpenAI API URL**: `https://[Your-OpenAI-Name].openai.azure.com/`.
    - **Parse Index**: `parse-autocreate` (Default).
    - **Recs Index**: `filerecs-autocreate` (Default).
    - **Sharepoint Doc Site**: Your SharePoint Site URL (from Step 2).
    - **Sharepoint Library Name**: Name of your library (e.g., `835 Files`).
5.  **Finish**: Click **Import** and wait for completion.

---

## Step 4: App Configuration

1.  **Edit App**: In the Solutions list, open **Denial Navigator**.
2.  **Dashboard Setup**:
    - Navigate to **Dashboards** > **Claim Navigator**.
    - Select the **File Upload** IFrame component.
    - Click **Edit Component**.
    - Update the **URL** to point to your SharePoint Library's "All Items" view:
      `https://yourtenant.sharepoint.com/sites/DenialNavigator/835%20Files/Forms/AllItems.aspx`
    - Save and Close.
3.  **Publish**: Click **Publish all customizations**.

---

## Step 5: Data Import (Code Definitions)

The AI needs definitions for CARC/RARC codes to generate recommendations.

1.  **Locate Data**: Find `rhail_codedefinitions.csv` in the `data` folder.
2.  **Import**:
    - In the Solution, find the table **Code Definition** (`rhail_CodeDefinition`).
    - Click **Import** > **Import data from Excel/CSV**.
    - Upload `rhail_codedefinitions.csv`.
    - Ensure columns map correctly (Name, Code, Description, Type).
    - Finish import.

---

## Final Verification

1.  **Upload Test**: Upload a sample 835 text file to your SharePoint library.
2.  **Monitor**: Check Power Automate flow `DenialNavigator_MainProcessFlow` history. It should trigger, parse the file, and populate Dataverse.
3.  **View**: Open the **Denial Navigator** app. Verify the claim appears and, after a few minutes, AI recommendations are generated.
