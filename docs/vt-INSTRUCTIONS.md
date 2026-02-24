# Denial Navigator - Azure Deployment Guide

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Step 1: Clone the Repository](#step-1-clone-the-repository)
3. [Step 2: Configure Deployment Parameters](#step-2-configure-deployment-parameters)
4. [Step 3: Deploy Azure Resources](#step-3-deploy-azure-resources)
5. [Step 4: Create SharePoint Document Library](#step-4-create-sharepoint-document-library)
6. [Step 5: Import Power Apps Solution](#step-5-import-power-apps-solution)
7. [Step 6: Configure the PowerApp Dashboard](#step-6-configure-the-powerapp-dashboard)
8. [Step 7: Import Code Definitions](#step-7-import-code-definitions)
9. [Step 8: Verify Deployment](#step-8-verify-deployment)
10. [Troubleshooting](#troubleshooting)
11. [Post-Deployment Security Recommendations](#post-deployment-security-recommendations)

---

## Prerequisites

Before you begin the deployment, ensure you have the following:

### Azure Subscription Requirements
- **Azure Subscription** with **Owner** or **Contributor** permissions
- Sufficient quota for Azure OpenAI Service (GPT-4o model)
- Permission to create resource groups and deploy resources
- Access to Azure Portal at https://portal.azure.com

### Software Requirements

#### PowerShell Installation
- **Windows PowerShell 5.1** or **PowerShell 7+** (recommended)
- PowerShell ISE (comes with Windows PowerShell)
- To check your PowerShell version:
  ```powershell
  $PSVersionTable.PSVersion
  ```

#### Azure CLI Installation
- **Azure CLI version 2.40.0 or higher**
- Download from: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli
- To check your Azure CLI version:
  ```bash
  az --version
  ```
- Note: The deployment script includes an option to install Azure CLI automatically

### Power Platform Requirements
- **Power Apps Premium license** (per user)
- Access to https://make.powerapps.com
- Permissions to create solutions and connections in your Power Platform environment
- Microsoft Dataverse environment provisioned

### SharePoint Requirements
- **Microsoft 365 subscription** with SharePoint Online access
- Permissions to create SharePoint sites and document libraries
- SharePoint site collection administrator rights (recommended)

### Estimated Total Time
- **Azure resource deployment**: 15-25 minutes
- **SharePoint configuration**: 5-10 minutes
- **Power Apps solution import**: 20-30 minutes
- **Total deployment time**: 45-70 minutes

---

## Step 1: Clone the Repository

### 1.1 Clone the Forked Repository
Open a command prompt or terminal and run:
```bash
git clone https://github.com/voltaire-toledo/Forked-RHAIL-Claims-Denial-Navigator.git
```

### 1.2 Navigate to the Azure Resources Folder
```bash
cd Forked-RHAIL-Claims-Denial-Navigator/azureresources
```

This folder contains:
- `AddResource.ps1` - Main deployment script
- `main.bicep` - Azure infrastructure template
- `IndexResource/` - Search service configuration scripts

---

## Step 2: Configure Deployment Parameters

### 2.1 Edit the Deployment Script
Open `AddResource.ps1` in a text editor (Notepad, VS Code, or PowerShell ISE).

### 2.2 Update Required Variables
Locate and modify the following variables (around lines 51-55):

#### Resource Group Name
```powershell
New-Variable -Name newRG -Value "ClaimCopilot-RG" -Description "Name of the new resource group" -Force
```
- **Change**: Replace `"ClaimCopilot-RG"` with your desired resource group name
- **Naming rules**: Use only letters, numbers, underscores, hyphens, periods, and parentheses
- **Example**: `"DenialNavigator-Prod-RG"`

#### Azure Region
```powershell
New-Variable -name loc -Value "East US 2" -Description "The location for your resources" -Force
```
- **Change**: Replace `"East US 2"` with your preferred Azure region
- **Common regions**: 
  - `"East US"`, `"East US 2"`, `"West US"`, `"West US 2"`
  - `"Central US"`, `"South Central US"`
  - `"West Europe"`, `"North Europe"`
  - `"Southeast Asia"`, `"East Asia"`
- **Tip**: Choose a region closest to your users for optimal performance
- **Verify GPT-4o availability**: https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models#model-summary-table-and-region-availability

#### Azure Tenant ID
```powershell
New-Variable -name tenant -Value "<YOUR-TENANT-ID>" -Force
```
- **Change**: Replace `<YOUR-TENANT-ID>` with your Azure Active Directory tenant ID

**How to find your Tenant ID:**
1. Navigate to https://portal.azure.com
2. Search for "Azure Active Directory" or "Microsoft Entra ID"
3. In the **Overview** page, copy the **Tenant ID** (GUID format)
4. Alternative method using Azure CLI:
   ```bash
   az account show --query tenantId -o tsv
   ```
- **Format**: 32-character GUID (e.g., `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)
- **Documentation**: https://learn.microsoft.com/en-us/azure/active-directory/fundamentals/how-to-find-tenant

#### Azure Subscription ID
```powershell
New-Variable -Name sub -Value "<YOUR-SUBSCRIPTION-ID>" -Description "ID of the Azure Subscription"
```
- **Change**: Replace `<YOUR-SUBSCRIPTION-ID>` with your Azure subscription ID

**How to find your Subscription ID:**
1. Navigate to https://portal.azure.com
2. Search for "Subscriptions"
3. Select your subscription and copy the **Subscription ID**
4. Alternative methods:
   - Azure CLI:
     ```bash
     az account show --query id -o tsv
     ```
   - PowerShell:
     ```powershell
     Get-AzSubscription
     ```
- **Format**: 32-character GUID (e.g., `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)
- **Documentation**: https://learn.microsoft.com/en-us/azure/azure-portal/get-subscription-tenant-id

### 2.3 Save the File
Save your changes to `AddResource.ps1`.

---

## Step 3: Deploy Azure Resources

### 3.1 Open PowerShell ISE
1. Press `Windows Key + R`
2. Type `powershell_ise.exe` and press Enter
3. If prompted by UAC, click "Yes" to allow

Alternative: Use PowerShell 7+ terminal:
```powershell
pwsh
```

### 3.2 Navigate to the Azure Resources Directory
```powershell
cd C:\path\to\Forked-RHAIL-Claims-Denial-Navigator\azureresources
```

### 3.3 Run the Deployment Script
```powershell
.\AddResource.ps1
```

### 3.4 Follow Authentication Prompts
1. A browser window will open for Azure login
2. Sign in with your Azure credentials
3. If you have MFA enabled, complete the multi-factor authentication
4. Close the browser once authentication is complete

### 3.5 Monitor Deployment Progress
The script will:
1. ✅ Install Azure CLI (if not already installed)
2. ✅ Authenticate to Azure with your tenant
3. ✅ Set the subscription context
4. ✅ Create the resource group
5. ✅ Deploy Azure resources using the Bicep template
6. ✅ Create Azure AI Search indexes
7. ✅ Configure indexers and data sources

**Expected deployment time**: 15-25 minutes

### 3.6 Resources Created
Upon successful deployment, the following resources will be created:

#### Storage Account
- **Name**: `<unique-string>` (auto-generated)
- **Type**: Standard_RAGRS (Geo-redundant)
- **Containers**:
  - `parse` - Stores uploaded claim files for processing
  - `recs` - Stores AI-generated recommendations

#### Azure OpenAI Service
- **Name**: `RHAILModel<unique-string>`
- **Model Deployment**: GPT-4o
  - **Version**: 2024-05-13
  - **Capacity**: 90 (150,000 tokens per minute / 900 requests per minute)
  - **SKU**: Standard S0
- **RAI Policy**: Microsoft.Default

#### Azure AI Search Service
- **Name**: `rhailsearch<unique-string>`
- **SKU**: Basic
- **Indexes**:
  - `filerecs-autocreate` - Stores recommendation data for retrieval
  - `parse-autocreate` - Stores parsed claim file data
- **Features**:
  - Semantic search (free tier)
  - Indexers and data sources configured automatically

#### Deployment Script Resource
- Executes post-deployment configuration tasks

### 3.7 Verify Deployment Success
Check for the following output messages:
```
Resources created !
Indexes created! Script complete
```

If you see these messages, your Azure resources are successfully deployed! ✅

**Troubleshooting**: If deployment fails, see the [Troubleshooting](#troubleshooting) section below.

---

## Step 4: Create SharePoint Document Library

### 4.1 Create a SharePoint Site
1. Navigate to https://yourtenant.sharepoint.com
2. Click **Create site** > **Team site** or **Communication site**
3. Provide a site name (e.g., "Denial Navigator File Intake")
4. Complete the site creation wizard

### 4.2 Create Document Library
1. In your new SharePoint site, click **New** > **Document library**
2. Name the library (e.g., "ClaimFiles" or "FileIntake")
3. Click **Create**

### 4.3 Configure Library Columns
The library needs the following columns (some are default):

| Column Name | Type | Required | Notes |
|-------------|------|----------|-------|
| Name | Single line of text | Yes | Default column (file name) |
| Message | Multiple lines of text | Yes | Add this column |
| Modified | Date and time | Yes | Default column |
| ModifiedBy | Person or Group | Yes | Default column |

**To add the "Message" column:**
1. In the document library, click **Add column** > **Multiple lines of text**
2. Name it `Message`
3. Configure:
   - **Type**: Plain text or Rich text
4. Click **Save**

### 4.4 Copy the SharePoint Library URL
1. Navigate to your document library
2. Copy the full URL from the browser address bar
3. **Format**: `https://yourtenant.sharepoint.com/sites/SiteName/LibraryName`
4. Save this URL - you'll need it in Step 5 and Step 6

**Example URL**:
```
https://contoso.sharepoint.com/sites/DenialNavigator/Shared%20Documents/ClaimFiles
MyURL: https://proventuras.sharepoint.com/RHAILClaimFiles
```

---

## Step 5: Import Power Apps Solution

### 5.1 Navigate to Power Apps
1. Open a web browser and go to https://make.powerapps.com
2. Sign in with your organizational credentials
3. Select your environment (top-right corner)

### 5.2 Import the Solution
1. In the left navigation, click **Solutions**
2. Click **Import solution** (top toolbar)
3. Click **Browse**
4. Navigate to the `src` folder of your cloned repository
5. Select `ClaimsDenialNavigator.zip`
6. Click **Next**

### 5.3 Configure Connections
You'll need to configure **5 connection references**. For each connection:

#### Connection 1: Azure Blob Storage DenialNavigator Conn
1. Click **Select a connection** dropdown
2. If a connection exists, select it
3. If not, click **New connection**:
   - Connection name: Azure Blob Storage
   - Authentication: Account name and account key
   - **Azure Storage account name**: From Azure Portal (Step 3)
   - **Shared Storage Key**: From Azure Portal > Storage Account > Access keys
4. Click **Create**

#### Connection 2: Content Conversion
1. Click **Select a connection**
2. If a connection exists, select it
3. If not, click **New connection** (uses Microsoft authentication)
4. Sign in and authorize

#### Connection 3: Microsoft Dataverse
1. Click **Select a connection**
2. Select an existing Dataverse connection or create new
3. Uses your current Power Apps credentials (automatic)

#### Connection 4: SharePoint
1. Click **Select a connection**
2. If a connection exists, select it
3. If not, click **New connection**:
   - Sign in with your Microsoft 365 credentials
   - Grant permissions to SharePoint

#### Connection 5: HTTP (for Azure OpenAI)
- This connection is typically created automatically
- Uses API key authentication configured in environment variables

**Verify**: All 5 connections should have a **green checkmark** ✅ before proceeding.

Click **Next** to continue.

### 5.4 Fill Out Environment Variables
You'll need to provide values for **9 environment variables**. Retrieve these from the Azure Portal:

#### How to Retrieve Azure Values
1. Go to https://portal.azure.com
2. Navigate to your resource group (created in Step 3)
3. Open each resource to find the required values

#### Environment Variable 1: Azure Blob Storage Name
- **Value**: Storage account name
- **Where to find**:
  1. Azure Portal > Resource Group > Storage Account
  2. Copy the **Storage account name** (e.g., `rhailstorage<unique>`)

#### Environment Variable 2: Azure Search Service API Key
- **Value**: Admin key for Azure AI Search
- **Where to find**:
  1. Azure Portal > Resource Group > Search Service
  2. Left menu: **Settings** > **Keys**
  3. Copy **Primary admin key** or **Secondary admin key**

#### Environment Variable 3: Azure Search Service URL
- **Value**: Search service endpoint
- **Where to find**:
  1. Azure Portal > Resource Group > Search Service
  2. **Overview** page > Copy **Url**
  3. **Format**: `https://rhailsearch<unique>.search.windows.net`

#### Environment Variable 4: AzureOpenAI API Key
- **Value**: Azure OpenAI access key
- **Where to find**:
  1. Azure Portal > Resource Group > Azure OpenAI Service
  2. Left menu: **Resource Management** > **Keys and Endpoint**
  3. Copy **Key 1** or **Key 2**

#### Environment Variable 5: AzureOpenAI API URL
- **Value**: Azure OpenAI endpoint URL
- **Where to find**:
  1. Azure Portal > Resource Group > Azure OpenAI Service
  2. Left menu: **Resource Management** > **Keys and Endpoint**
  3. Copy **Endpoint**
  4. **Format**: `https://rhailmodel<unique>.openai.azure.com/`

#### Environment Variable 6: Parse Index
- **Value**: `parse-autocreate`
- This is the index name created by the deployment script

#### Environment Variable 7: Recs Index
- **Value**: `filerecs-autocreate`
- This is the index name created by the deployment script

#### Environment Variable 8: SharePoint Doc Site
- **Value**: SharePoint site URL (from Step 4.4)
- **Format**: `https://yourtenant.sharepoint.com/sites/SiteName`
- **Example**: `https://contoso.sharepoint.com/sites/DenialNavigator`

#### Environment Variable 9: SharePoint Library Name
- **Value**: Document library name (from Step 4.2)
- **Example**: `ClaimFiles` or `Shared Documents/ClaimFiles`

### 5.5 Complete the Import
1. Verify all environment variables are filled
2. Click **Import**
3. Wait for the import to complete (this may take 10-15 minutes)
4. You'll see a success message when complete: "Solution imported successfully" ✅

---

## Step 6: Configure the PowerApp Dashboard

### 6.1 Navigate to the Solution
1. In Power Apps (https://make.powerapps.com), go to **Solutions**
2. Click on the imported solution (e.g., "Denial Navigator")

### 6.2 Edit the Dashboard
1. In the left navigation pane, expand **Dashboards**
2. Click **Claim Navigator** (or the dashboard for 835 files)
3. Click **Edit** in the toolbar

### 6.3 Update the IFrame Component
1. Locate the **IFrame** component labeled "File Upload" on the dashboard
2. Click on the IFrame component to select it
3. Click **Edit Component** in the properties pane

### 6.4 Update the URL
1. In the **Edit Component** dialog, find the **URL** field
2. Replace the existing URL with your SharePoint document library URL (from Step 4.4)
3. **Format**:
   ```
   https://yourtenant.sharepoint.com/sites/SiteName/LibraryName/Forms/AllItems.aspx
   ```
4. **Example**:
   ```
   https://contoso.sharepoint.com/sites/DenialNavigator/Shared%20Documents/ClaimFiles/Forms/AllItems.aspx
   ```

### 6.5 Save and Publish
1. Click **OK** to close the component editor
2. Click **Save** (top-right)
3. Click **Publish** to make changes available to users
4. Wait for the publish to complete ✅

---

## Step 7: Import Code Definitions

The Code Definitions table contains CARC (Claim Adjustment Reason Codes) and RARC (Remittance Advice Remark Codes) that the AI uses for generating recommendations.

### 7.1 Download the CSV File
1. Navigate to the `data` folder in your cloned repository
2. Locate the file `rhail_codedefinitions.csv`
3. Download it to your local machine

### 7.2 Navigate to Code Definitions Table
1. In Power Apps (https://make.powerapps.com), go to **Solutions**
2. Click on the imported solution
3. In the left pane, click **Tables**
4. Find and click **Code Definitions** (or `rhail_CodeDefinition`)

### 7.3 Import Data
1. In the **Code Definitions** table view, click **Import** > **Import data** (or **Get data** > **Import from Excel**)
2. Click **Choose File** and select `rhail_codedefinitions.csv`
3. Click **Next**

### 7.4 Confirm Destination Settings
1. Verify the destination table is `rhail_CodeDefinition`
2. Click **Next**

### 7.5 Map Columns
Ensure the columns are mapped correctly:

| CSV Column | Table Column |
|------------|--------------|
| Name | Name |
| Code | Code |
| Description | Description |
| Type | Type (CARC/RARC) |

The import wizard should auto-map these columns. Verify the mapping is correct.

### 7.6 Complete Import
1. Click **Next** to review settings
2. Click **Submit** or **Finish** to start the import
3. Wait for the import to complete
4. Verify success: Navigate to the **Code Definitions** table and confirm data is loaded ✅

**Expected record count**: 500+ code definitions

---

## Step 8: Verify Deployment

### 8.1 Test File Upload to SharePoint
1. Navigate to your SharePoint document library (from Step 4)
2. Upload a sample 835 or 837 claim file
   - Sample files may be available in the repository's `data` or test folders
   - Or use a real 835/837 file (ensure PHI is handled appropriately)
3. Verify the file appears in the library

### 8.2 Verify Cloud Flows Trigger
1. Go to https://make.powerapps.com
2. Navigate to **Solutions** > Your solution > **Cloud flows**
3. Click **DenialNavigator_MainProcessFlow**
4. Check the **28-day run history**
5. Verify a new run was triggered after file upload
6. Status should be **Running** or **Succeeded**

**Expected trigger time**: Within 1-2 minutes of file upload

### 8.3 Check Dataverse Tables for Parsed Data
1. In Power Apps, navigate to **Tables** in your solution
2. Check the following tables for new records:
   - **Claims** (or equivalent table for claim data)
   - **Claim Lines** (parsed claim line items)
   - **Denials** (denial codes and reasons)
3. Open a record to verify data was parsed correctly

### 8.4 Verify AI Recommendations Appear
1. Open the **Denial Navigator** app:
   - Go to **Solutions** > Your solution > **Apps**
   - Click **Denial Navigator** > **Play**
2. Navigate to the claims view
3. Select a claim with denial codes
4. Verify that **Recommendations** are displayed
5. Recommendations should be AI-generated suggestions based on CARC/RARC codes

### 8.5 End-to-End Test Checklist
- [ ] File uploaded to SharePoint successfully
- [ ] MainProcessFlow cloud flow triggered and completed
- [ ] Claim data parsed and stored in Dataverse
- [ ] CARC/RARC codes identified and recorded
- [ ] AI recommendations generated and visible in the app
- [ ] User can view claim details and recommendations
- [ ] User can submit feedback (optional test)

If all checks pass, your deployment is complete! 🎉

---

## Troubleshooting

### Issue 1: Max Token Settings Too Low

**Symptom**: Parsing fails or returns incomplete data

**Solution**:
1. Navigate to **Solutions** > Your solution > **Cloud flows**
2. Open **DenialNavigator_Child_Parse835Claims**
3. Edit the flow
4. Find the Azure OpenAI API call action
5. Locate the `max_tokens` parameter
6. **Change value to**: `16000`
7. Save and test again

### Issue 2: Azure OpenAI Quota Exceeded

**Symptom**: Error message: "Rate limit exceeded" or "Insufficient quota"

**Solution**:
1. Go to Azure Portal > Your OpenAI resource
2. Navigate to **Resource Management** > **Model deployments**
3. Check current **Capacity** (default: 90 for GPT-4o)
4. Request quota increase:
   - Azure Portal > **Quotas** > **+ Request quota increase**
   - Or visit: https://learn.microsoft.com/en-us/azure/ai-foundry/openai/how-to/quota
5. Typical increase: From 90K TPM to 150K+ TPM
6. Approval time: 1-3 business days

**Temporary workaround**: Reduce concurrent file processing

### Issue 3: Connection Failures

**Symptom**: "Connection not found" or "Authentication failed"

**Solution**:
1. Go to **Solutions** > Your solution > **Connection references**
2. For each failing connection:
   - Click on the connection reference
   - Click **Edit**
   - Re-authenticate or create a new connection
   - Save changes
3. Republish the solution if needed

**Common causes**:
- Expired credentials
- Insufficient permissions
- Connection created in a different environment

### Issue 4: Permission Errors

**Symptom**: "Access denied" or "Insufficient privileges"

**Solution**:

#### Azure RBAC:
1. Azure Portal > Resource Group > **Access control (IAM)**
2. Click **Add role assignment**
3. Assign yourself:
   - **Owner** or **Contributor** role
   - **Cognitive Services OpenAI User** (for OpenAI access)
   - **Storage Blob Data Contributor** (for Blob access)

#### Power Platform:
1. Power Platform Admin Center: https://admin.powerplatform.microsoft.com
2. Navigate to your environment
3. **Settings** > **Users + permissions** > **Security roles**
4. Assign **System Administrator** or **System Customizer** role

#### SharePoint:
1. SharePoint Site > **Settings** > **Site permissions**
2. Grant yourself **Full Control** or **Owner** permissions

### Issue 5: Search Indexer Failures

**Symptom**: "Indexer error" or "Data source connection failed"

**Solution**:
1. Azure Portal > Search Service > **Indexers**
2. Check indexer status (should be "Success")
3. If failed, click **Run** to manually trigger
4. Check **Execution history** for error details
5. Verify:
   - Storage account connection string is correct
   - Containers `parse` and `recs` exist
   - Indexer has access to the storage account

### Issue 6: Cloud Flow Not Triggering

**Symptom**: File uploaded to SharePoint but flow doesn't run

**Solution**:
1. Verify SharePoint connection is active
2. Check the trigger configuration in **DenialNavigator_MainProcessFlow**:
   - Trigger: "When a file is created or modified"
   - Site Address: Correct SharePoint site URL
   - Library Name: Correct library name
3. Turn off and turn on the cloud flow
4. Test with a new file upload

### Issue 7: Environment Variables Not Applied

**Symptom**: App doesn't connect to Azure resources

**Solution**:
1. Go to **Solutions** > Your solution > **Environment variables**
2. Verify all 9 variables have values (no blank fields)
3. Edit any missing or incorrect values
4. Publish changes
5. Restart the app

### General Debugging Tips
- **Enable diagnostics logging** on Azure resources (OpenAI, Search, Storage)
- **Check cloud flow run history** for detailed error messages
- **Review Azure Activity Log** for resource-level errors
- **Test connections** individually in Power Apps
- **Verify API keys haven't expired** (rotate every 90 days recommended)

---

## Post-Deployment Security Recommendations

After deploying the Denial Navigator solution, follow these security best practices to protect sensitive healthcare data:

### 1. Enable Virtual Network and Private Endpoints

**Why**: Eliminate public internet exposure of Azure resources

**Steps**:
1. Create an Azure Virtual Network (VNet)
2. Configure VNet subnet delegation for Power Platform
3. Create Private Endpoints for:
   - Azure OpenAI Service
   - Azure AI Search Service
   - Azure Storage Account
4. Update Bicep template to disable public access:
   ```bicep
   publicNetworkAccess: 'Disabled'
   ```
5. Configure DNS for private endpoints

**Documentation**: 
- https://learn.microsoft.com/en-us/power-platform/admin/vnet-support-setup-configure
- https://learn.microsoft.com/en-us/azure/ai-foundry/openai/how-to/network

### 2. Configure Azure API Management (APIM)

**Why**: Centralized authentication, rate limiting, and content filtering

**Steps**:
1. Deploy Azure API Management instance
2. Configure backend APIs (Azure OpenAI, AI Search)
3. Set up policies:
   - Validate Azure AD JWT tokens
   - Transform to service credentials
   - Apply rate limits and quotas
4. Update Power Platform connections to use APIM endpoint
5. Enable OAuth 2.0 authentication

**Documentation**: 
- https://learn.microsoft.com/en-us/shows/apis-in-action/leveraging-api-management-for-openai-applications

### 3. Enable Diagnostic Logging

**Why**: Support threat detection and security investigations

**Steps**:
1. Azure Portal > Each resource > **Diagnostic settings**
2. Enable logging for:
   - **Azure OpenAI**: Audit, RequestResponse, Trace
   - **Azure AI Search**: OperationLogs, AllMetrics
   - **Azure Storage**: StorageRead, StorageWrite, StorageDelete
3. Send logs to:
   - Log Analytics Workspace (recommended)
   - Azure Storage Account (for long-term retention)
   - Event Hub (for SIEM integration)

**Documentation**: 
- https://learn.microsoft.com/en-us/azure/ai-services/diagnostic-logging
- https://learn.microsoft.com/en-us/azure/search/search-monitor-enable-logging

### 4. Set Up Azure Content Safety

**Why**: Prevent malicious content uploads and AI exploitation

**Steps**:
1. Deploy Azure Content Safety service
2. Configure APIM policy to scan file uploads
3. Block or flag potentially harmful content
4. Integrate with Power Automate for approval workflows

**Use Cases**:
- Validate 835/837 files before processing
- Prevent injection attacks
- Ensure compliance with healthcare data policies

### 5. Implement Managed Identity

**Why**: Eliminate API key management, automatic credential rotation

**Steps**:
1. Enable System-Assigned Managed Identity on Azure OpenAI, Search, and Storage
2. Assign RBAC roles:
   - `Cognitive Services OpenAI User`
   - `Search Service Contributor`
   - `Storage Blob Data Contributor`
3. Update Bicep template:
   ```bicep
   disableLocalAuth: true
   ```
4. Modify Power Platform connectors (may require custom connector)

### 6. Enable Multi-Factor Authentication (MFA)

**Why**: Protect user accounts from unauthorized access

**Steps**:
1. Azure Portal > **Microsoft Entra ID** > **Security** > **MFA**
2. Enable MFA for all users with access to:
   - Power Apps
   - Azure Portal
   - SharePoint
3. Configure Conditional Access policies
4. Enforce MFA for sensitive operations

### 7. Rotate API Keys Regularly

**Why**: Limit exposure window if keys are compromised

**Steps**:
1. Set a reminder to rotate keys every **90 days**
2. Azure Portal > Each resource > **Keys and Endpoint**
3. Regenerate **Secondary key** first
4. Update Power Apps environment variables with new key
5. Test the solution
6. Regenerate **Primary key**
7. Update environment variables again

**Best Practice**: Migrate to Managed Identity to eliminate key rotation

### 8. Configure Azure RBAC (Role-Based Access Control)

**Why**: Principle of least privilege

**Steps**:
1. Review current role assignments
2. Remove unnecessary **Owner** roles
3. Use granular roles:
   - `Cognitive Services OpenAI User` (not Contributor)
   - `Storage Blob Data Reader` (for read-only access)
   - `Search Index Data Reader` (for query-only access)
4. Create custom roles for specific scenarios

### 9. Enable Azure Defender / Microsoft Defender for Cloud

**Why**: Advanced threat protection and vulnerability scanning

**Steps**:
1. Azure Portal > **Microsoft Defender for Cloud**
2. Enable Defender plans for:
   - **Azure Storage**
   - **Azure AI Services**
   - **Azure Resource Manager**
3. Review security recommendations
4. Implement suggested improvements
5. Monitor security alerts

### 10. Implement Data Loss Prevention (DLP)

**Why**: Prevent accidental sharing of sensitive healthcare data

**Steps**:
1. Microsoft 365 Compliance Center > **Data loss prevention**
2. Create DLP policies for:
   - Power Platform environments
   - SharePoint sites
3. Configure rules to detect:
   - Protected Health Information (PHI)
   - Personally Identifiable Information (PII)
4. Set enforcement actions (block, warn, audit)

### 11. Regular Security Audits

**Schedule**: Monthly or quarterly

**Checklist**:
- [ ] Review user access and permissions
- [ ] Check for unused API keys
- [ ] Verify MFA is enabled for all users
- [ ] Review diagnostic logs for anomalies
- [ ] Scan for vulnerabilities
- [ ] Test disaster recovery procedures
- [ ] Update security documentation

### 12. Business Associate Agreement (BAA)

**For HIPAA Compliance**:
1. Ensure you have a signed BAA with Microsoft Azure
2. Verify Azure OpenAI and Dataverse are covered under BAA
3. Configure services in HIPAA-compliant mode:
   - Encryption at rest enabled (default)
   - Encryption in transit enforced (HTTPS only)
   - Audit logging enabled
4. Document compliance measures

**Documentation**: 
- https://learn.microsoft.com/en-us/azure/compliance/offerings/offering-hipaa-us

---

## Conclusion

You have successfully deployed the Denial Navigator solution! 🎉

**Next Steps**:
1. Train users on how to use the application
2. Monitor usage and performance
3. Implement security recommendations
4. Provide feedback to improve the solution

**Support**:
- Review the repository README for additional information
- Check the FAQ.md for common questions
- Report issues on GitHub

**Stay Secure**: Regularly review and update your security posture to protect sensitive healthcare data.
