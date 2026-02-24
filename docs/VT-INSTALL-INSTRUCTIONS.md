# Denial Navigator — Consolidated Installation Instructions

**Single Source of Truth**
This document serves as the primary installation guide for the Denial Navigator solution. It consolidates steps from previous guides and reflects the current repository structure where source code resides in the `src/` directory.

## Table of Contents
1. Prerequisites
2. Step 1: Azure Resource Deployment
3. Step 2: SharePoint Configuration
4. Step 3: Pack the Solution
5. Step 4: Import Solution to Power Apps
6. Step 5: Configure the Application
7. Step 6: Import Data
8. Troubleshooting

---

## Prerequisites

### Access & Licenses
- **Azure Subscription**: Owner/Contributor access.
- **Power Apps Premium License**: Per user.
- **SharePoint Online**: Permission to create sites/libraries.
- **Microsoft 365**: Standard license.

### Tools
- **PowerShell** (v5.1 or 7+)
- **Azure CLI** (`az`)
- **Power Platform CLI** (`pac`)
  - *Recommended*: Install via **Power Platform VS Code Extension**.
  - *Alternative*: `dotnet tool install --global Microsoft.PowerApps.CLI.Tool`

---

## Step 1: Azure Resource Deployment

1.  Navigate to the `azureresources/` folder in this repository.
2.  Open `AddResource.ps1` and update the variables at the top:
    -   `$newRG`: Your desired Resource Group name.
    -   `$loc`: Region (e.g., "East US 2").
    -   `$tenant`: Your Tenant ID.
    -   `$sub`: Your Subscription ID.
3.  Run the script:
    ```powershell
    .\AddResource.ps1
    ```
4.  **Record Outputs** (you will need these for Step 4):
    -   Storage Account Name
    -   Azure Search Service URL & Key
    -   Azure OpenAI Endpoint & Key
    -   Index Names (`parse-autocreate`, `filerecs-autocreate`)

---

## Step 2: SharePoint Configuration

1.  Create a **SharePoint Team Site**.
2.  Create a **Document Library** (e.g., "835 Files").
3.  Ensure the following columns exist:

| Column Name | Type | Required | Notes |
|---|---|---|---|
| **Name** | Single line of text | Yes | Default |
| **Message** | Multiple lines of text | **Yes** | Create this column manually |
| **Modified** | Date and time | System | Default |
| **ModifiedBy** | Person | System | Default |

4.  **Record URLs**:
    -   Site URL (e.g., `https://org.sharepoint.com/sites/DenialNavigator`)
    -   Library Name (e.g., `835 Files`)

---

## Step 3: Pack the Solution

The source code is located in the `src/` directory. You must pack it into a deployable ZIP file before importing it into Power Apps.

1.  Open a terminal in the repository root.
2.  Run the pack command:
    ```bash
    pac solution pack --folder ./src/ClaimsDenialNavigatorSolution --zipfile ./src/ClaimsDenialNavigator.zip --packagetype Unmanaged
    ```
3.  Verify that `src/ClaimsDenialNavigator.zip` has been created.

> **Note**: This ZIP file contains the Power Apps solution logic. It does *not* contain the PDF policy documents shown in demo videos. Those must be uploaded manually to Azure Storage if needed.

---

## Step 4: Import Solution to Power Apps

1.  Go to make.powerapps.com.
2.  Select **Solutions** > **Import solution**.
3.  Browse and select the file you created: `src/ClaimsDenialNavigator.zip`.
4.  **Configure Connections**:
    -   Create/Select connections for SharePoint, Dataverse, Azure Blob Storage, etc.
5.  **Environment Variables**:
    -   Fill in the values recorded in Step 1 and Step 2.
6.  Click **Import**.

---

## Step 5: Configure the Application

1.  In the Solution, go to **Dashboards** > **Claim Navigator**.
2.  Select the **IFrame: File Upload** component.
3.  Click **Edit Component**.
4.  Update the **URL** to your SharePoint Library URL (All Items view).
    -   Example: `https://org.sharepoint.com/sites/DenialNavigator/835%20Files/Forms/AllItems.aspx`
5.  **Save** and **Publish** the dashboard.
6.  Go to **Apps**, select **Denial Navigator**, and **Publish**.

---

## Step 6: Import Data

1.  In the Solution, locate the **Code Definitions** table.
2.  Select **Import** > **Import data from Excel/CSV**.
3.  Upload `data/rhail_codedefinitions.csv`.
4.  Map columns (Name, Code, Description, Type) and finish import.

---

## Troubleshooting

### JSON Cut Off
If the AI response is incomplete:
1.  Edit the `DenialNavigator_Child_Parse835Claims` flow.
2.  In the HTTP action calling OpenAI, add `"max_tokens": 16000` to the body.

### Azure Quota
Ensure your Azure region supports GPT-4o and you have requested sufficient quota.

### Flow Not Triggering
1.  Check the SharePoint connection.
2.  Ensure the `DenialNavigator_MainProcessFlow` is turned on.
3.  Verify the SharePoint Site Address and Library Name in the flow trigger match your setup.