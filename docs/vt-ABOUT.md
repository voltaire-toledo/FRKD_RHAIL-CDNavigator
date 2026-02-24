# Denial Navigator - Technical Overview

## Table of Contents
1. [Application Overview](#application-overview)
2. [Architecture](#architecture)
3. [Technical Workflow](#technical-workflow)
4. [Technologies Used](#technologies-used)
5. [Resource Requirements](#resource-requirements)
6. [Data Flow](#data-flow)
7. [Security & Compliance](#security--compliance)

---

## Application Overview

### Purpose
Denial Navigator is an AI-powered healthcare claims denial management and recommendation system designed to help rural hospitals and healthcare organizations efficiently process, analyze, and resolve denied Medicare, Medicaid, and Commercial Insurance claims.

The application addresses a critical challenge in healthcare finance: In 2023, denials issued by commercial Medicare Advantage plans rose sharply by **55.7%**, and for other commercial payers, claims denials increased by **20.2%**. Healthcare organizations spend nearly **$20 billion annually** on appealing denials, creating a significant administrative and financial burden.

Denial Navigator automates the labor-intensive process of:
- Parsing complex healthcare claim files (835 and 837 formats)
- Extracting denial reason codes (CARC and RARC)
- Generating AI-powered recommendations for claim resolution
- Tracking claims through the review and appeal process

### Target Users
- **Healthcare organizations** processing 835 and 837 claim files
- **Rural hospitals** with limited IT and billing resources
- **Revenue cycle management teams** handling claim denials
- **Medical billing specialists** reviewing and appealing denied claims
- **Hospital administrators** monitoring denial trends and financial impact

### Key Capabilities

#### 1. Parse Healthcare Claim Files
- **Supported formats**: 
  - **835 (Electronic Remittance Advice)**: Payment and remittance information from payers
  - **837 (Healthcare Claim)**: Professional, institutional, and dental claims
- **Automated parsing**: Uses Azure OpenAI to extract structured data from unstructured text files
- **Data extraction**:
  - Patient information (ID, name, demographics)
  - Claim identifiers and dates
  - Service codes and amounts
  - Payment and adjustment details

#### 2. Extract CARC and RARC Codes
- **CARC (Claim Adjustment Reason Codes)**: Standardized codes explaining why claims were adjusted or denied
  - Maintained by the Washington Publishing Company
  - Examples: CO-50 (non-covered services), PR-1 (deductible amount)
- **RARC (Remittance Advice Remark Codes)**: Supplemental codes providing additional context
  - Examples: M80 (not covered unless prior authorized), N56 (decision based on medical necessity)
- **Automatic identification**: AI model identifies codes embedded in claim files
- **Code lookup**: Cross-references with built-in code definition table

#### 3. Generate AI-Powered Recommendations
- **Azure OpenAI integration**: Uses GPT-4o model to analyze denial codes
- **Contextual recommendations**: AI considers:
  - Specific CARC/RARC codes
  - Historical resolution patterns
  - Payer-specific guidelines
- **Actionable insights**: Provides specific steps for claim appeal or correction
- **Examples**:
  - "Verify prior authorization was obtained and resubmit with auth number"
  - "Submit additional medical documentation supporting medical necessity"
  - "Correct coding error: Use CPT code XXXXX instead of XXXXX"

#### 4. Store and Manage Claims Data
- **Centralized repository**: Microsoft Dataverse stores all claim information
- **Relational data model**: Links claims, claim lines, denials, and recommendations
- **Historical tracking**: Maintains full audit trail of claim lifecycle
- **Search and filter**: Power Apps interface for finding and reviewing claims
- **Reporting**: Built-in dashboards and analytics

#### 5. User Feedback Mechanism
- **Feedback collection**: Users can rate recommendation quality and usefulness
- **Continuous improvement**: Feedback stored for model refinement
- **Comment capture**: Users can provide detailed notes on outcomes
- **Feedback file**: Stored as `SubmittedUserFeedback.txt` in Azure Blob Storage

---

## Architecture

Denial Navigator uses a multi-tier architecture combining Microsoft Power Platform, Azure AI services, and SharePoint.

### Frontend Layer

#### Model-Driven Power App (Denial Navigator)
- **Framework**: Model-Driven App built on Power Apps
- **User interface components**:
  - **Dashboards**: Summary views of claims, denials, and recommendations
  - **Forms**: Detailed claim and recommendation views
  - **Views**: Filterable lists of claims by status, date, payer, etc.
  - **Charts**: Visual analytics of denial trends
- **IFrame integration**: Embedded SharePoint document library for file upload
- **Navigation**: Tab-based navigation between claims, code definitions, and feedback
- **Responsive design**: Works on desktop and mobile devices

#### SharePoint Document Library
- **Purpose**: File intake point for claim files
- **Integration**: Power Automate monitors for new files
- **Metadata**: Stores file properties (name, modified date, uploader)
- **Security**: Inherits SharePoint permissions and access controls
- **Version control**: Maintains file history if enabled

#### Interactive Dashboards
- **Embedded IFrame**: Direct access to SharePoint library within the app
- **Real-time updates**: Reflects claim processing status
- **Custom views**: Filtered by user, date range, payer, or denial type
- **Visual indicators**: Color-coded status (pending, processed, appealed, resolved)

### Integration Layer

#### Power Automate Cloud Flows
The solution uses **7 cloud flows** to orchestrate the entire claim processing workflow:

##### 1. DenialNavigator_MainProcessFlow (Orchestrator)
- **Trigger**: When a file is created or modified in SharePoint library
- **Function**: Main orchestration flow
- **Actions**:
  - Detects file upload event
  - Determines file type (835 or 837)
  - Converts file to compatible format
  - Uploads to Azure Blob Storage (`parse` container)
  - Calls appropriate child flow based on file type
  - Logs processing status
- **Error handling**: Catches failures and logs to Dataverse

##### 2. DenialNavigator_Child_Parse835Claims
- **Trigger**: Called by MainProcessFlow
- **Function**: Parse 835 claim files
- **Actions**:
  - Reads file from Blob Storage
  - Calls Azure OpenAI API with parsing prompt
  - Extracts claim line items
  - Identifies CARC/RARC codes
  - Stores parsed data in Dataverse
- **AI Configuration**:
  - Model: GPT-4o
  - Max tokens: 16000 (configurable)
  - Temperature: 0.3 (low for consistent parsing)

##### 3. DenialNavigator_Child_Parse837Claims
- **Trigger**: Called by MainProcessFlow
- **Function**: Parse 837 claim files
- **Actions**: Similar to Parse835Claims but with 837-specific logic
- **Differences**: Handles claim submission data vs. remittance data

##### 4. DenialNavigator_Child_ParseHeader835
- **Trigger**: Called by Parse835Claims flow
- **Function**: Extract header information from 835 files
- **Actions**:
  - Parses payer information
  - Extracts check/payment details
  - Identifies patient and provider information
  - Stores header data separately from claim lines

##### 5. DenialNavigator_Child_GetRec (AI Recommendations)
- **Trigger**: After claims are parsed and stored
- **Function**: Generate AI recommendations for denied claims
- **Actions**:
  - Queries Dataverse for claims with denial codes
  - Retrieves CARC/RARC definitions from Code Definitions table
  - Constructs prompt with denial context
  - Calls Azure OpenAI for recommendation generation
  - Stores recommendations in Blob Storage (`recs` container)
  - Updates Dataverse with recommendation reference
- **AI Configuration**:
  - Model: GPT-4o
  - Temperature: 0.7 (higher for creative recommendations)
  - System prompt includes payer guidelines and best practices

##### 6. DenialNavigator_AddFeedback
- **Trigger**: When user submits feedback in Power App
- **Function**: Capture and store user feedback
- **Actions**:
  - Receives feedback rating and comments
  - Appends to `SubmittedUserFeedback.txt` in Blob Storage
  - Logs feedback to Dataverse
  - Sends confirmation to user

##### 7. DenialNavigator_ArchiveFiles
- **Trigger**: Scheduled (daily or weekly)
- **Function**: Archive processed files
- **Actions**:
  - Identifies files older than retention period
  - Moves to archive container or deletes
  - Updates Dataverse records
  - Maintains audit log

### Data Layer

#### Microsoft Dataverse
- **Purpose**: Primary data storage and business logic layer
- **Tables (Entities)**:
  - **Claims**: Main claim records
  - **Claim Lines**: Individual line items from claims
  - **Denials**: Denial records linked to claims
  - **Code Definitions**: CARC and RARC code lookup table
  - **Recommendations**: AI-generated recommendations
  - **Feedback**: User feedback on recommendations
  - **Files**: Metadata about uploaded files
- **Relationships**: One-to-many between Claims and Claim Lines, Denials, Recommendations
- **Business rules**: Validation rules, calculated fields, workflows
- **Security**: Row-level security, field-level security, business unit hierarchy

#### Code Definitions Table
- **Purpose**: CARC/RARC code reference data
- **Columns**:
  - **Name**: Code identifier (e.g., "CO-50", "PR-1")
  - **Code**: Numeric or alphanumeric code
  - **Description**: Full text explanation
  - **Type**: CARC or RARC
  - **Category**: Grouping (e.g., "Coverage", "Coding", "Authorization")
- **Source**: Imported from `rhail_codedefinitions.csv`
- **Record count**: 500+ code definitions
- **Updates**: Periodically updated to reflect industry changes

### Azure Backend Services

#### Azure OpenAI Service
- **Model**: GPT-4o
  - **Version**: 2024-05-13
  - **Deployment name**: Configured in Bicep template
  - **SKU**: Standard S0
  - **Capacity**: 90 (150,000 tokens per minute / 900 requests per minute)
- **Usage Scenarios**:
  1. **Parsing**: Extracts structured data from unstructured 835/837 text files
     - Input: Raw claim file text
     - Output: JSON with patient ID, claim ID, codes, amounts
  2. **Recommendations**: Generates actionable insights based on denial codes
     - Input: CARC/RARC codes + definitions + claim context
     - Output: Specific steps to resolve denial
- **Configuration**:
  - **RAI Policy**: Microsoft.Default (content filtering enabled)
  - **Authentication**: API Key (current) or Managed Identity (recommended)
  - **Public access**: Enabled (can be secured with VNet and Private Endpoints)

#### Azure AI Search Service
- **SKU**: Basic
- **Capacity**: 1 replica, 1 partition
- **Indexes**:
  1. **filerecs-autocreate**: Stores recommendation data for semantic search
     - Fields: recommendation text, claim ID, codes, timestamps
     - Search features: Full-text search, filtering
  2. **parse-autocreate**: Stores parsed claim file data
     - Fields: patient ID, claim ID, payer, amounts, dates
     - Search features: Full-text search, faceted navigation
- **Indexers**: Automated document processing
  - **Data source**: Azure Blob Storage containers
  - **Schedule**: Runs automatically when new files are added
  - **Configuration**: Set up by `SetupSearchService_v1.ps1` script
- **Features**:
  - **Semantic search**: Free tier enabled (enhances search relevance)
  - **Scoring profiles**: Custom relevance ranking
  - **Synonym maps**: Map related medical terms

#### Azure Blob Storage
- **Type**: Standard_RAGRS (Geo-redundant storage)
- **Kind**: StorageV2 (General-purpose v2)
- **Containers**:
  1. **parse**: Stores uploaded claim files for processing
     - Lifecycle: Files retained for configured period
     - Access: Private (accessed via connection string)
  2. **recs**: Stores AI-generated recommendation data
     - Format: JSON or text files
     - Indexed by Azure AI Search
  3. **archive** (optional): Archived processed files
- **Security**:
  - **Authentication**: Connection string with account key (current)
  - **Encryption at rest**: Enabled by default (Microsoft-managed keys)
  - **Encryption in transit**: HTTPS enforced
  - **Access tiers**: Hot (frequently accessed data)
- **Monitoring**: Diagnostic logs for read/write operations

---

## Technical Workflow

This section describes the end-to-end technical workflow from file upload to recommendation display.

### Step 1: User Uploads Claim File
- **Action**: User navigates to SharePoint library in Power App dashboard
- **File types**: 835 (remittance) or 837 (claim) text file
- **Upload**: File uploaded to SharePoint document library
- **Metadata**: SharePoint captures file name, modified date, uploader

### Step 2: Power Automate Detects New File
- **Trigger**: SharePoint "When a file is created or modified" trigger fires
- **Flow**: DenialNavigator_MainProcessFlow starts
- **Initial checks**:
  - Validates file type (must be .txt or compatible format)
  - Checks file size (must be within limits)
  - Logs file receipt in Dataverse

### Step 3: File Conversion and Upload
- **Content conversion**: Power Automate Content Conversion connector converts file
- **Upload to Blob Storage**:
  - File uploaded to `parse` container
  - File name includes timestamp for uniqueness
  - Blob metadata includes original file name and uploader
- **Status update**: Dataverse record updated to "Processing"

### Step 4: Claim File Parsing
- **Flow selection**:
  - If 835 file → calls DenialNavigator_Child_Parse835Claims
  - If 837 file → calls DenialNavigator_Child_Parse837Claims
- **Azure OpenAI parsing**:
  - Flow reads file content from Blob Storage
  - Constructs parsing prompt:
    ```
    Parse the following 835 claim file and extract:
    - Patient ID
    - Claim ID
    - Patient Name
    - CARC codes
    - RARC codes
    - Claim amounts
    [File content]
    ```
  - Calls Azure OpenAI API with GPT-4o model
  - Receives structured JSON response
- **Data extraction**:
  - **Patient ID**: Unique identifier for patient
  - **Claim ID**: Unique identifier for claim
  - **Patient Name**: Patient demographics
  - **CARC Codes**: Claim Adjustment Reason Codes (e.g., ["CO-50", "PR-1"])
  - **RARC Codes**: Remittance Advice Remark Codes (e.g., ["N56", "M80"])
  - **Amounts**: Billed, allowed, paid, adjusted amounts
- **Error handling**: If parsing fails, logs error and notifies user

### Step 5: Azure AI Search Indexing
- **Automatic trigger**: New file in `parse` container triggers indexer
- **Indexer execution**:
  - Reads blob content
  - Extracts metadata and text
  - Populates `parse-autocreate` index
- **Index update**: New document added to search index
- **Search availability**: Claim data immediately searchable

### Step 6: AI Recommendation Generation
- **Flow**: DenialNavigator_Child_GetRec is called after parsing completes
- **Query Dataverse**: Retrieves claims with denial codes (CARC/RARC present)
- **Code lookup**: Joins with Code Definitions table to get full descriptions
  - Example: CARC "CO-50" → "These are non-covered services because this is not deemed a 'medical necessity' by the payer."
- **Prompt construction**:
  ```
  You are an expert medical billing specialist. A claim was denied with the following codes:
  - CARC CO-50: These are non-covered services...
  - RARC N56: Decision based on medical necessity...
  
  Claim context:
  - Patient: John Doe
  - Service: Office visit
  - Amount: $150
  
  Provide specific, actionable recommendations to resolve this denial.
  ```
- **OpenAI API call**:
  - Model: GPT-4o
  - Temperature: 0.7 (balanced creativity and consistency)
  - Max tokens: Configured in flow (typically 500-1000 for recommendations)
- **Response parsing**: AI returns recommendation text
- **Storage**:
  - Recommendation saved to `recs` container in Blob Storage
  - File name: `rec_[ClaimID]_[Timestamp].txt` or JSON
  - Metadata includes claim ID, codes, timestamp

### Step 7: Recommendation Indexing
- **Automatic trigger**: New file in `recs` container triggers indexer
- **Indexer execution**: Reads recommendation blob and populates `filerecs-autocreate` index
- **Index update**: Recommendation searchable and linkable to claim

### Step 8: Data Sync to Dataverse
- **Flow updates**:
  - Claim record updated with recommendation ID/URL
  - Status changed to "Processed" or "Recommendations Available"
  - Timestamp fields updated
- **Relationship creation**: Recommendation linked to Claim via lookup field
- **Notification**: Optional email/Teams notification to user

### Step 9: User Views Claims in Power App
- **User action**: Opens Denial Navigator app
- **Navigation**: Goes to Claims view or dashboard
- **Data retrieval**: Power App queries Dataverse for claims
- **Display**:
  - List of claims with key details
  - Color-coded status indicators
  - Denial code badges (CARC/RARC)
- **Filtering**: User can filter by date, payer, status, denial code

### Step 10: User Views Recommendations
- **Selection**: User clicks on a claim to view details
- **Form loads**: Claim detail form opens
- **Recommendation display**:
  - AI-generated recommendations shown in dedicated section
  - Formatted for readability (bullet points, numbered steps)
  - Links to related codes and definitions
- **Actions**: User can:
  - Read and implement recommendations
  - Update claim status (e.g., "Appealed", "Resolved")
  - Add notes
  - Submit feedback

### Step 11: User Provides Feedback
- **Feedback UI**: User clicks "Submit Feedback" button
- **Feedback form**:
  - Rating: 1-5 stars or thumbs up/down
  - Comments: Free text field for detailed feedback
  - Usefulness: Did this help resolve the denial?
- **Submission**: Triggers DenialNavigator_AddFeedback flow
- **Storage**:
  - Appended to `SubmittedUserFeedback.txt` in Blob Storage
  - Format: `[Timestamp] | Claim: [ID] | Rating: [X] | Comments: [Text]`
  - Also logged to Dataverse Feedback table
- **Confirmation**: User sees success message

---

## Technologies Used

### Microsoft Power Platform

#### Power Apps (Model-Driven App Framework)
- **Version**: Latest (cloud-based, automatically updated)
- **License required**: Power Apps Premium (per user)
- **Features used**:
  - Model-driven app designer
  - Custom forms and views
  - Business process flows
  - Dashboards and charts
  - Mobile responsive design
- **Development tools**:
  - Power Apps Maker Portal (https://make.powerapps.com)
  - Power Apps CLI for solution packaging

#### Power Automate (Cloud Flows)
- **License**: Included with Power Apps Premium
- **Flow types**: Automated cloud flows (event-triggered)
- **Connectors used**:
  - SharePoint (file triggers)
  - Azure Blob Storage (file operations)
  - HTTP (Azure OpenAI API calls)
  - Content Conversion (file format conversion)
  - Dataverse (database operations)
- **Premium features**: HTTP connector, Dataverse connector
- **Limits**: Standard flow run limits apply (configurable)

#### Microsoft Dataverse
- **Database type**: Relational database as a service
- **Features**:
  - Custom tables and columns
  - Relationships (1:N, N:1, N:N)
  - Business rules and validation
  - Security roles and permissions
  - Audit logging
  - Data encryption at rest
- **Capacity**: Included with Power Apps license (additional storage available)
- **API access**: OData REST API, Web API, SDK for custom integrations

#### Connection References and Environment Variables
- **Connection References**: Abstraction layer for connector authentication
  - Allows solution portability across environments
  - Configured during solution import
- **Environment Variables**: Configuration values
  - Azure API keys and URLs
  - SharePoint site and library names
  - Index names
  - Updateable without modifying flows

### Azure Services

#### Azure OpenAI Service
- **Model**: GPT-4o
  - **Version**: 2024-05-13
  - **Context window**: 128,000 tokens
  - **Output tokens**: Configurable (typically 16,000 max for parsing)
- **SKU**: Standard S0
- **Capacity**: 90 units
  - **TPM (Tokens Per Minute)**: 150,000
  - **RPM (Requests Per Minute)**: 900
  - Quota can be increased via Azure Portal
- **Pricing** (as of 2024):
  - Input tokens: ~$2.50 per 1M tokens
  - Output tokens: ~$10 per 1M tokens
  - Typical usage: $10-100/month depending on volume
- **Features**:
  - Function calling (not currently used)
  - JSON mode (used for structured parsing)
  - System prompts for context
  - Temperature control for output variability

#### Azure AI Search
- **SKU**: Basic
  - **Price**: ~$75/month (fixed)
  - **Storage**: 2 GB
  - **Indexes**: Up to 15
  - **Replicas**: 1
  - **Partitions**: 1
- **Features**:
  - **Semantic search**: Free tier (enhances relevance)
  - **Indexers**: Automated document processing
  - **Data sources**: Azure Blob Storage, Azure SQL, Cosmos DB
  - **Query**: REST API, .NET SDK
- **Search capabilities**:
  - Full-text search
  - Faceted navigation
  - Filters and sorting
  - Scoring profiles for relevance tuning
  - Autocomplete and suggestions

#### Azure Blob Storage
- **Type**: Standard_RAGRS
  - **Replication**: Read-Access Geo-Redundant Storage
  - **Redundancy**: 6 copies across two regions
  - **Read access**: Secondary region available for read during outage
- **Kind**: StorageV2 (General-purpose v2)
- **Performance tier**: Standard (HDD-based)
- **Access tier**: Hot (for frequently accessed data)
- **Pricing** (approximate):
  - Storage: ~$0.02 per GB/month
  - Operations: Minimal (included in most scenarios)
  - Typical cost: $20-50/month depending on usage
- **Features**:
  - Blob versioning (optional)
  - Soft delete for recovery
  - Lifecycle management for archival
  - Blob index tags for metadata
  - Change feed for event tracking

### Development Tools

#### Infrastructure as Code: Bicep Templates
- **File**: `main.bicep`
- **Purpose**: Define Azure infrastructure declaratively
- **Resources defined**:
  - Storage Account with containers
  - Azure OpenAI Service with GPT-4o deployment
  - Azure AI Search Service with configuration
  - Deployment scripts for post-deployment tasks
- **Benefits**:
  - Repeatable deployments
  - Version control for infrastructure
  - Parameter-based customization
- **Compilation**: Bicep compiles to ARM templates

#### Deployment: PowerShell Scripts
- **File**: `AddResource.ps1`
- **Purpose**: Orchestrate deployment process
- **Actions**:
  - Azure CLI installation check
  - Login and subscription selection
  - Resource group creation
  - Bicep template deployment
  - Post-deployment indexer setup
- **Requirements**: PowerShell 5.1+ or PowerShell 7+

#### Version Control: Git/GitHub
- **Repository**: https://github.com/voltaire-toledo/Forked-RHAIL-Claims-Denial-Navigator
- **Branching**: Main branch for releases, feature branches for development
- **CI/CD**: (Optional) GitHub Actions for automated testing and deployment
- **Collaboration**: Issues, pull requests, code reviews

### SharePoint

#### Document Libraries
- **Purpose**: File management and intake
- **Integration**: Power Automate triggers on file events
- **Features**:
  - Version history
  - Metadata columns
  - Content types
  - Permissions inheritance
  - Search integration
- **Access**: SharePoint Online (Microsoft 365)

#### Content Types
- **Custom metadata**: Name, Message, Modified, ModifiedBy
- **Inherited from**: Document content type
- **Applied to**: File upload library

---

## Resource Requirements

### Azure Resources

#### Cost Breakdown (Monthly Estimates)
| Resource | SKU | Estimated Cost |
|----------|-----|----------------|
| Azure OpenAI Service | Standard S0, 90 capacity | $10 - $100 |
| Azure AI Search | Basic | $75 |
| Azure Blob Storage | Standard_RAGRS | $20 - $50 |
| **Total** | | **$105 - $225** |

**Notes**:
- OpenAI cost varies based on token usage (depends on file volume and complexity)
- Storage cost increases with data volume
- Costs shown are estimates; actual costs may vary by region and usage
- Cost optimization:
  - Archive old files to Cool or Archive tier
  - Use lifecycle policies to delete files after retention period
  - Monitor and optimize OpenAI token usage

#### Azure OpenAI
- **Quota**: Default 90K TPM (Tokens Per Minute) for GPT-4o
- **Increase requests**: Via Azure Portal > Quotas
- **Typical quota**: 150K - 300K TPM for production workloads
- **Request time**: 1-3 business days for quota increases
- **Limit**: Based on region availability and subscription limits

#### Azure AI Search
- **Limits (Basic SKU)**:
  - Storage: 2 GB
  - Indexes: 15
  - Indexers: 15
  - Data sources: 15
  - Documents per index: ~1 million (typical)
- **Upgrade path**: Standard S1 ($250/month) for higher limits

#### Azure Blob Storage
- **Capacity**: Unlimited (within cost constraints)
- **Throughput**: Adequate for most scenarios
- **Scale**: Automatically scales with demand
- **Best practices**:
  - Use lifecycle management to transition to Cool/Archive tiers
  - Enable soft delete for accidental deletion recovery
  - Monitor storage costs and usage patterns

### Licenses

#### Power Apps Premium License
- **Cost**: ~$40/user/month (Power Apps per user) or included in Microsoft 365 E5
- **Required for**:
  - Model-driven apps
  - Premium connectors (HTTP, Azure Blob Storage)
  - Dataverse access
- **Alternatives**:
  - Power Apps per app license: $10/user/month for single app access
  - Included licenses: Check if already included in Microsoft 365 E3/E5

#### Azure Subscription
- **Required permissions**: Contributor or Owner role
- **Billing**: Pay-as-you-go or Enterprise Agreement
- **Free trial**: $200 credit for 30 days (new accounts)

#### Microsoft 365 with SharePoint
- **Required for**: SharePoint document library
- **Typical plan**: Microsoft 365 Business Standard or higher
- **Cost**: ~$12.50/user/month (Business Standard)
- **Included in**: Most enterprise Microsoft 365 plans

### Compute/Performance

#### Azure OpenAI
- **TPM (Tokens Per Minute)**: 150,000
  - Sufficient for processing ~10-20 files concurrently
  - 1 file ≈ 5,000-10,000 tokens (varies by size and complexity)
- **RPM (Requests Per Minute)**: 900
  - Supports high-frequency API calls
  - Typical: 2-3 requests per file (header + claims + recommendations)
- **Latency**: Typically 1-5 seconds per API call
- **Throttling**: Automatic retry with exponential backoff recommended

#### Azure AI Search
- **Replicas**: 1 (Basic SKU)
  - Single point of availability
  - No high availability or load balancing
- **Partitions**: 1
  - Limited to 2 GB storage
- **Query performance**: Adequate for most use cases (<100ms for simple queries)
- **Indexing speed**: ~100-1000 documents per second (varies by size)

#### Azure Blob Storage
- **Unlimited capacity**: No hard limits on storage
- **Throughput**: Scalable (up to 20,000 requests per second per account)
- **Latency**: Typically <100ms for small file operations
- **Redundancy**: RAGRS provides 99.99% read availability

### Quotas

#### Default GPT-4o Quota
- **Default**: 90K TPM (Tokens Per Minute)
- **Calculation**: 90 capacity units × 1,000 TPM/unit = 90,000 TPM
- **RPM**: 900 requests per minute (derived from capacity)

#### Request Quota Increase
1. Navigate to Azure Portal > Azure OpenAI resource
2. Go to **Quotas** in the left menu
3. Click **Request quota increase**
4. Provide justification (e.g., "Production workload requires 300K TPM")
5. Submit request
6. Approval time: 1-3 business days (typically)

**Documentation**: https://learn.microsoft.com/en-us/azure/ai-foundry/openai/how-to/quota

#### Search Indexer Runs
- **Scheduling**: Can be scheduled (hourly, daily, etc.) or on-demand
- **On-demand**: Triggered by new files in Blob Storage
- **Limits**: No hard limit on indexer runs
- **Execution time**: Up to 24 hours for long-running indexers (not typical for this solution)

---

## Data Flow

This section describes how data flows through the system from ingestion to presentation.

### 1. Ingestion: SharePoint → Power Automate
- **Source**: User uploads file to SharePoint document library
- **Mechanism**: SharePoint file created/modified event
- **Trigger**: Power Automate "When a file is created or modified" trigger
- **Data transferred**: File metadata (name, size, modified date, uploader)
- **Format**: SharePoint REST API event payload
- **Flow start**: DenialNavigator_MainProcessFlow begins execution

### 2. Transformation: Power Automate → Azure OpenAI (Parsing)
- **Source**: File retrieved from SharePoint
- **Conversion**: Content Conversion connector transforms to text
- **Transfer**: File content sent to Azure OpenAI via HTTP POST
- **Endpoint**: `https://<openai-resource>.openai.azure.com/openai/deployments/<deployment>/chat/completions?api-version=2024-02-15-preview`
- **Request format**:
  ```json
  {
    "messages": [
      {"role": "system", "content": "You are a healthcare claims parser..."},
      {"role": "user", "content": "[File content]"}
    ],
    "max_tokens": 16000,
    "temperature": 0.3
  }
  ```
- **Response**: Structured JSON with parsed claim data
- **Parsing time**: 2-10 seconds per file

### 3. Storage: Parsed Data → Azure Blob Storage → Dataverse
- **Azure Blob Storage**:
  - Flow uploads original file to `parse` container
  - File name: `claim_[timestamp]_[original-name].txt`
  - Metadata tags: Uploader, upload date, file type
- **Dataverse**:
  - Flow creates records in Dataverse tables:
    - **Claim** record (patient ID, claim ID, amounts, dates)
    - **Claim Line** records (one per line item)
    - **Denial** records (one per CARC/RARC code)
  - Relationships established between records
  - Status set to "Parsed"
- **Data format**: JSON from OpenAI converted to Dataverse columns
- **Validation**: Business rules check data integrity

### 4. Indexing: Azure Blob Storage → Azure AI Search (Automated Indexers)
- **Trigger**: Indexer detects new blob in `parse` container
- **Mechanism**: Change detection (periodic polling or change feed)
- **Indexer execution**:
  - Reads blob content
  - Extracts text and metadata
  - Applies field mappings
  - Populates `parse-autocreate` index
- **Index update**: New document added to search index
- **Search availability**: Immediately searchable after indexing (typically <1 minute)
- **Schedule**: Runs every 5 minutes or on-demand

### 5. Intelligence: CARC/RARC Codes → Azure OpenAI (Recommendations)
- **Source**: Dataverse query for claims with denial codes
- **Code lookup**: Join with Code Definitions table
  - Input: CARC/RARC codes (e.g., ["CO-50", "N56"])
  - Output: Full descriptions and context
- **Prompt construction**: Combines codes + descriptions + claim context
- **OpenAI API call**:
  - Endpoint: Same as parsing
  - Temperature: 0.7 (higher for creative recommendations)
  - Max tokens: 500-1000
- **Response**: AI-generated recommendation text
- **Storage**:
  - Recommendation saved to `recs` container
  - File name: `rec_[ClaimID]_[timestamp].json`
  - Content: JSON with recommendation text, codes, claim reference
- **Indexing**: `filerecs-autocreate` indexer adds recommendation to search index
- **Dataverse update**: Claim record updated with recommendation link

### 6. Presentation: Dataverse → Power Apps (User Interface)
- **Data retrieval**: Power App queries Dataverse via OData API
- **Views**: Pre-configured views filter and sort claims
- **Forms**: Display detailed claim and recommendation data
- **Real-time**: Data refreshed on form load or manual refresh
- **Caching**: Power Apps caches data locally for performance
- **Offline**: Limited offline support (read-only cached data)
- **User actions**:
  - View claims and recommendations
  - Update claim status
  - Add notes
  - Submit feedback

### Data Flow Diagram (Text Representation)
```
User Upload (SharePoint)
    ↓
Power Automate (MainProcessFlow)
    ↓
Content Conversion
    ↓
Azure Blob Storage (parse container)
    ↓ ↓
    ↓ Azure AI Search Indexer → parse-autocreate index
    ↓
Azure OpenAI (Parse 835/837)
    ↓
Dataverse (Claims, Denials)
    ↓
Power Automate (GetRec)
    ↓
Code Definitions (CARC/RARC lookup)
    ↓
Azure OpenAI (Generate Recommendations)
    ↓
Azure Blob Storage (recs container)
    ↓ ↓
    ↓ Azure AI Search Indexer → filerecs-autocreate index
    ↓
Dataverse (Recommendations)
    ↓
Power Apps (User Interface)
    ↓
User (View & Feedback)
    ↓
SubmittedUserFeedback.txt (Blob Storage)
```

---

## Security & Compliance

### Data Residency
- **All data remains within organization's Azure tenant**
- **No data leaves organizational boundaries** (except to Microsoft-managed services)
- **Region selection**: Data stored in selected Azure region (e.g., East US 2)
- **Cross-region**: RAGRS replicates to paired region (read-only secondary)
- **Control**: Organization maintains full data ownership and control

### Access Controls

#### SharePoint
- **Authentication**: Microsoft 365 / Azure AD authentication
- **Authorization**: SharePoint permissions (site owners, members, visitors)
- **Library-level**: Permissions can be set per library
- **Item-level**: Permissions can be set per file (if needed)
- **Sharing**: Controlled by SharePoint sharing policies

#### Power Apps / Dataverse
- **Authentication**: Azure Active Directory (AAD) / Microsoft Entra ID
- **Authorization**: Dataverse security roles
  - Owner: Full access to records they own
  - Organization: Access to all records in the organization
  - Business Unit: Access to records in their business unit
  - Custom: Fine-grained permissions
- **Row-level security**: Users see only records they have access to
- **Field-level security**: Sensitive fields can be hidden from certain roles
- **Team-based**: Shared access via teams

#### Azure Resources (RBAC)
- **Authentication**: Azure AD
- **Authorization**: Role-Based Access Control (RBAC)
  - Owner: Full management access
  - Contributor: Create/manage resources, cannot grant access
  - Reader: View-only access
  - Custom roles: Fine-grained permissions
- **Resource-specific**:
  - Cognitive Services OpenAI User: API access only
  - Storage Blob Data Contributor: Read/write blobs
  - Search Service Contributor: Manage search resources

### Encryption

#### Data at Rest
- **Azure OpenAI**: Encrypted with Microsoft-managed keys (MMK)
- **Azure AI Search**: Encrypted with MMK
- **Azure Blob Storage**: Encrypted with MMK
  - Optional: Customer-managed keys (CMK) via Azure Key Vault
- **Dataverse**: Encrypted with MMK (SQL Transparent Data Encryption)

#### Data in Transit
- **HTTPS enforced**: All API calls use HTTPS/TLS 1.2+
- **Certificate validation**: Ensures secure connections
- **No clear-text transmission**: Credentials and data encrypted

### Compliance

#### Azure OpenAI RAI Policy
- **Policy**: Microsoft.Default
- **Content filters**:
  - Hate speech detection
  - Sexual content detection
  - Violence detection
  - Self-harm detection
- **Severity levels**: Low, Medium, High (configurable thresholds)
- **Custom policies**: Can be created for specific use cases

#### Public Network Access
- **Current configuration**: Enabled
  - Azure OpenAI, Search, Storage are publicly accessible
  - Access controlled by API keys and authentication
- **Recommended**: Disable public access and use Private Endpoints
  - Restricts access to VNet only
  - Prevents internet exposure

#### HIPAA Compliance
- **Azure Services**: Azure OpenAI, Dataverse, and Blob Storage are HIPAA-compliant when properly configured
- **Requirements**:
  - Business Associate Agreement (BAA) with Microsoft
  - Encryption at rest and in transit (enabled by default)
  - Audit logging enabled
  - Access controls in place
  - Data residency in approved regions
- **BAA**: Available for Azure Enterprise Agreements
- **Documentation**: https://learn.microsoft.com/en-us/azure/compliance/offerings/offering-hipaa-us

#### PHI (Protected Health Information) Handling
- **Data stored**: Patient names, IDs, claim details (contains PHI)
- **Best practices**:
  - De-identify data when possible (e.g., use patient IDs instead of names)
  - Limit access to authorized personnel only
  - Enable audit logging to track data access
  - Implement data retention and deletion policies
  - Train users on HIPAA compliance

#### Audit Logging
- **Azure Activity Log**: Tracks resource-level operations (who did what, when)
- **Dataverse Audit**: Tracks record-level changes (create, update, delete)
- **OpenAI Diagnostics**: Tracks API calls, tokens used, response times
- **Storage Analytics**: Tracks blob operations (read, write, delete)
- **Retention**: Configure retention periods (30-365+ days)
- **Integration**: Logs can be sent to Log Analytics, SIEM, or archived

#### Data Retention
- **Dataverse**: Indefinite (until manually deleted)
- **Blob Storage**: Configurable via lifecycle management policies
  - Example: Delete files after 90 days
  - Example: Move to Archive tier after 30 days
- **Audit logs**: Configurable retention (30-365+ days)

### Security Recommendations
For detailed security hardening recommendations, refer to:
- **INSTRUCTIONS.md**: Post-Deployment Security Recommendations section
- **AUTHX-Z.md**: Authentication, Authorization, and Security Best Practices

---

## Conclusion

Denial Navigator is a comprehensive, AI-powered solution that modernizes healthcare claims denial management. By combining Microsoft Power Platform, Azure AI services, and SharePoint, it provides:

- **Automation**: Reduces manual effort in parsing and analyzing claim files
- **Intelligence**: Leverages AI to generate actionable recommendations
- **Efficiency**: Streamlines the denial resolution workflow
- **Scalability**: Built on cloud-native services that scale with demand
- **Security**: Implements enterprise-grade security and compliance controls

This technical overview provides a foundation for understanding the architecture, workflows, and technologies. For deployment instructions, see **INSTRUCTIONS.md**. For authentication and authorization details, see **AUTHX-Z.md**.
