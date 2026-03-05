# Project Context: Denial Navigator

## Overview
Denial Navigator is an AI-powered tool designed to help rural hospitals resolve denied insurance claims. It parses 835/837 files, uses Azure OpenAI for analysis, and provides recommendations via a Power Apps interface.

## Repository Structure
- **`src/`**: Contains the unpacked Power Platform solution source code (`ClaimsDenialNavigatorSolution`). This is the source of truth for the app logic.
- **`azureresources/`**: PowerShell scripts (`AddResource.ps1`) and Bicep templates for provisioning Azure infrastructure.
- **`data/`**: Seed data, specifically `rhail_codedefinitions.csv` for CARC/RARC codes.
- **`docs/`**: Documentation.
    - **`VT-INSTALL-INSTRUCTIONS.md`**: **Single Source of Truth** for installation.
    - `vt-ABOUT.md`: Technical architecture and data flow.
    - `vt-AUTHX-Z.md`: Security and authentication.
    - `vt-CODE_DIFFERENCES.md`: Explains repo structure vs release artifacts.
- **`solution/`**: Legacy folder, contains only a README.
- **`Convert-Receipts.ps1`**: Utility script to convert PDFs to PNGs for agentic processing.

## Key Workflows

### 1. Installation
Follow `docs/VT-INSTALL-INSTRUCTIONS.md`.
1.  **Azure**: Deploy via `azureresources/AddResource.ps1`.
2.  **SharePoint**: Create library with `Name` and `Message` columns.
3.  **Build**: Pack solution from `src/` using `pac solution pack`.
4.  **Deploy**: Import `ClaimsDenialNavigator.zip` to Power Apps.
5.  **Config**: Set env vars, connections, and update Dashboard iFrame.
6.  **Seed**: Import CSV data to Dataverse.

### 2. Architecture
- **Frontend**: Model-Driven Power App with embedded SharePoint iFrame.
- **Orchestration**: Power Automate flows (MainProcessFlow, Parse835, GetRec).
- **AI/Backend**: Azure OpenAI (GPT-4o), Azure AI Search, Azure Blob Storage.
- **Data**: Microsoft Dataverse.

## Current State & Notes
- **Source Location**: Code moved to `src/`.
- **CLI**: Use `dotnet tool install --global Microsoft.PowerApps.CLI.Tool` or VS Code extension for `pac`.
- **PDFs**: Policy documents for RAG are external to the solution zip and must be uploaded to Azure Storage manually.
- **Status**: Documentation is being consolidated. `VT-INSTALL-INSTRUCTIONS.md` is the primary guide.

## Environment Variables
Required for Power Apps import:
`Azure Blob Storage Name`, `Azure Search Service API Key`, `Azure Search Service URL`, `AzureOpenAi API Key`, `AzureOpenAi API URL`, `Parse Index`, `Recs Index`, `Sharepoint Doc Site`, `Sharepoint Library Name`.