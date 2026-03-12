# Codebase & Release Analysis

## Overview
This document outlines the structural and content differences between the current development branch (`@MS-Copy`) and the Version 1 release tag (`@Version1`).

## 1. Structural Differences

| Feature | @MS-Copy (Main Branch) | @Version1 (Release Tag) |
| :--- | :--- | :--- |
| **State** | **Unpacked / Source Code** | **Packed / Distribution** |
| **Solution Folder** | Contains raw solution components: `AppModules`, `Entities`, `Workflows`, `WebResources`, etc. | Contains the importable solution package: `ClaimsDenialNavigatorSolution.zip` |
| **Use Case** | The `solution_1.15.0.33/` directory is the verified source for packing the solution. | Deployment to UAT or Production environments via Solution Import. |

## 1.1 The "Deployment Bundle" Confusion
The developer's video demonstrates a `.zip` file that contains PDFs and Azure container subdirectories. 
- **The Bundle**: A manual collection of the Solution Zip + Azure Assets + Docs.
- **The Repo**: Contains the source to build the Solution Zip. Azure assets (PDFs) must be managed separately in the `azureresources` or `data` workflows.

## 2. Discrepancies Identification

### Solution File Naming
- **Documentation (`README.md` / `INSTRUCTIONS.md`)**: References `RHAILUnmanaged.zip`.
- **Actual Artifact (`@Version1`)**: Contains `ClaimsDenialNavigatorSolution.zip`.
- **Correction**: The documentation has been updated to use `ClaimsDenialNavigator.zip` as the standard filename, packed from the `solution_1.15.0.33/` directory.

### Azure Resource Deployment
- **Script (`AddResource.ps1`)**: Validated against `main.bicep`.
- **Outputs**: The script correctly expects outputs (`searchServicesName`, `dataSourceConnectionString`, etc.) that `main.bicep` provides.
- **Indices**: The `SetupSearchService_v1.ps1` script correctly aligns with the index definitions in `IndexResource` folder.

## 3. Environment Variable Verification
The following 9 environment variables are required by the solution and verified present in the source code:

1. `rhail_AzureOpenAIAPIKey`
2. `rhail_AzureOpenAiAPIURL`
3. `rhail_AzureSearchIndexAPIKey`
4. `rhail_AzureSearchIndexURL`
5. `rhail_AzureStorageAccountName`
6. `rhail_FileParsingIndex` (Default: `parse-autocreate`)
7. `rhail_FileRecommendationIndex` (Default: `filerecs-autocreate`)
8. `rhail_SharepointDocSite`
9. `rhail_SharepointLibraryName`

## 4. Conclusion
The codebase is consistent with the instructions provided in `INSTRUCTIONS.md`, with the exception of the solution filename. `MS-Copy` serves as the valid source of truth for the solution's logic (Flows, Entities), while `Version1` provides the deployable artifact.
