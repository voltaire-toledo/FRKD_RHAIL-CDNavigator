# Denial Navigator - Authentication & Authorization Guide

## Table of Contents
1. [Built-In Authentication Mechanisms](#built-in-authentication-mechanisms)
2. [Viable Authentication Options & Enhancements](#viable-authentication-options--enhancements)
3. [Authorization Model](#authorization-model)
4. [Security Best Practices](#security-best-practices)
5. [Compliance Considerations](#compliance-considerations)
6. [Authentication Flow Diagrams](#authentication-flow-diagrams)

---

## Built-In Authentication Mechanisms

The Denial Navigator solution uses multiple authentication mechanisms across different layers of the architecture. This section describes the current, out-of-the-box authentication configuration.

### 1. Azure Active Directory (AAD) / Microsoft Entra ID

Microsoft Entra ID (formerly Azure Active Directory) is the primary identity and access management service for the entire solution.

#### Power Platform Layer

##### User Authentication
- **Authentication provider**: Microsoft Entra ID
- **Protocol**: OAuth 2.0 / OpenID Connect
- **Flow**: Authorization Code Flow with PKCE (Proof Key for Code Exchange)
- **Token types**:
  - **ID Token**: Contains user identity claims (name, email, user ID)
  - **Access Token**: Used for API calls to Dataverse and other resources
  - **Refresh Token**: Allows silent token renewal without re-authentication
- **Token lifetime**:
  - Access tokens: 1 hour (default)
  - Refresh tokens: 90 days (configurable)
  - ID tokens: 1 hour (default)

##### Single Sign-On (SSO)
- **Capability**: Enabled by default across Microsoft 365 services
- **Benefit**: Users authenticate once and access Power Apps, SharePoint, and Azure Portal without re-entering credentials
- **Implementation**: Shared authentication session via Azure AD
- **Conditional Access**: Can be applied to enforce additional security policies

##### Multi-Factor Authentication (MFA)
- **Support**: Fully supported and recommended for all users
- **Methods**:
  - Microsoft Authenticator app (push notification or TOTP)
  - SMS text message
  - Phone call
  - FIDO2 security keys
  - Third-party authenticator apps
- **Configuration**: Enabled via Azure AD > Security > MFA
- **Conditional Access**: Can require MFA for specific scenarios (e.g., access from outside corporate network)

For the complete authentication and authorization documentation, including:
- Detailed Azure resource authentication (OpenAI, AI Search, Blob Storage)
- SharePoint authentication
- Power Platform connection references
- Managed Identity implementation
- Azure API Management integration
- Virtual Network with Private Endpoints
- Service Principal configuration
- Azure Content Safety integration
- Authorization model (Dataverse security roles, Azure RBAC)
- Security best practices
- Compliance considerations (HIPAA, GDPR, data residency)
- Authentication flow diagrams

Please refer to the comprehensive security documentation available in the Azure Portal and Microsoft Learn documentation:

## Key Security Resources

### Authentication & Authorization
- [Microsoft Entra ID documentation](https://learn.microsoft.com/en-us/entra/identity/)
- [Power Platform security](https://learn.microsoft.com/en-us/power-platform/admin/security/)
- [Dataverse security concepts](https://learn.microsoft.com/en-us/power-platform/admin/wp-security-cds)

### Azure Services Security
- [Azure OpenAI security](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/managed-identity)
- [Azure AI Search security](https://learn.microsoft.com/en-us/azure/search/search-security-overview)
- [Azure Storage security](https://learn.microsoft.com/en-us/azure/storage/common/storage-security-guide)

### Network Security
- [Power Platform VNet support](https://learn.microsoft.com/en-us/power-platform/admin/vnet-support-setup-configure)
- [Azure Private Endpoints](https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-overview)

### Best Practices
- [Azure security best practices](https://learn.microsoft.com/en-us/azure/security/fundamentals/best-practices-and-patterns)
- [Zero Trust security model](https://learn.microsoft.com/en-us/security/zero-trust/)

---

## Quick Reference: Current Authentication Configuration

### User Authentication
- **Method**: Azure AD / Microsoft Entra ID
- **Protocol**: OAuth 2.0 / OpenID Connect
- **MFA**: Supported (should be enabled)
- **SSO**: Enabled across Microsoft 365

### Azure OpenAI
- **Current**: API Key authentication
- **Recommended**: Managed Identity or Service Principal
- **Keys**: Stored in environment variable `AzureOpenAI API Key`
- **Rotation**: Manual (every 90 days recommended)

### Azure AI Search
- **Current**: API Key authentication (Admin key)
- **Recommended**: Managed Identity
- **Keys**: Stored in environment variable `Azure Search Service API Key`
- **Rotation**: Manual (every 90 days recommended)

### Azure Blob Storage
- **Current**: Connection string with account key
- **Recommended**: Managed Identity or SAS tokens
- **Keys**: Embedded in connection string
- **Rotation**: Manual (every 90 days recommended)

### SharePoint
- **Method**: OAuth delegation via SharePoint connector
- **Authentication**: Inherits Microsoft 365 / Azure AD
- **Permissions**: Site and library-level permissions

### Dataverse
- **Authentication**: Azure AD (uses caller's identity)
- **Authorization**: Security roles (User, Business Unit, Organization levels)
- **Row-level security**: Enabled
- **Field-level security**: Available for sensitive data

---

## Security Recommendations Summary

### Immediate Actions (High Priority)
1. ✅ **Enable MFA** for all users accessing Power Platform and Azure Portal
2. ✅ **Rotate API keys** if they haven't been rotated in the last 90 days
3. ✅ **Review security role assignments** in Dataverse
4. ✅ **Enable diagnostic logging** on Azure OpenAI, Search, and Storage
5. ✅ **Configure Conditional Access** policies for Power Platform access

### Medium-Term Enhancements
1. 🔧 **Implement Managed Identity** for Azure resource authentication
2. 🔧 **Deploy Azure API Management** as a security gateway
3. 🔧 **Store secrets in Azure Key Vault** instead of environment variables
4. 🔧 **Configure Private Endpoints** for Azure services
5. 🔧 **Integrate Azure Content Safety** for input validation

### Long-Term Security Posture
1. 🎯 **Implement Virtual Network isolation** for all Azure resources
2. 🎯 **Enable Azure Defender** for advanced threat protection
3. 🎯 **Configure Data Loss Prevention** (DLP) policies
4. 🎯 **Conduct regular security audits** and penetration testing
5. 🎯 **Implement Zero Trust architecture** across all layers

---

## Compliance Quick Reference

### HIPAA Compliance Checklist
- [ ] Business Associate Agreement (BAA) executed with Microsoft
- [ ] Azure services deployed in HIPAA-compliant regions
- [ ] Encryption at rest enabled (default: ✅)
- [ ] Encryption in transit enforced (HTTPS only: ✅)
- [ ] Audit logging enabled on all services
- [ ] Access controls configured (MFA, RBAC, security roles)
- [ ] Data retention policies implemented
- [ ] Regular risk assessments conducted
- [ ] Staff trained on HIPAA requirements

### GDPR Compliance Checklist
- [ ] Data stored in EU regions (if processing EU resident data)
- [ ] User consent mechanisms implemented
- [ ] Data subject rights supported (access, rectify, erase)
- [ ] Data breach notification procedures in place
- [ ] Data Processing Agreement (DPA) with Microsoft
- [ ] Privacy impact assessment completed
- [ ] Data retention and deletion policies defined

---

## Authorization Quick Reference

### Dataverse Security Roles (Recommended)

**Claims Administrator**
- Full access to all tables and records
- Can customize solution
- Should be limited to 2-3 trusted users

**Claims Reviewer**
- Read access to all claims (Organization level)
- Write access to own claims (User level)
- Can create feedback
- Typical role for billing specialists

**Claims Viewer**
- Read-only access to claims (Business Unit level)
- Cannot modify data
- Typical role for auditors and executives

### Azure RBAC Roles (Recommended)

**For Administrators:**
- Contributor (resource group level)
- Cognitive Services OpenAI User (OpenAI resource)
- Storage Blob Data Contributor (Storage account)

**For Applications/Services:**
- Cognitive Services OpenAI User (via Managed Identity)
- Search Service Contributor (via Managed Identity)
- Storage Blob Data Contributor (via Managed Identity)

**For Auditors:**
- Reader (resource group level)
- No write permissions

---

## Troubleshooting Authentication Issues

### Issue: User cannot access Power App
**Possible causes:**
- User not assigned a Dataverse security role
- User not licensed for Power Apps
- Conditional Access policy blocking access

**Resolution:**
1. Verify user has Power Apps license
2. Assign appropriate security role in Dataverse
3. Check Conditional Access policies in Azure AD

### Issue: API key authentication failing
**Possible causes:**
- API key expired or rotated
- Environment variable not updated
- Network connectivity issues

**Resolution:**
1. Verify API key in Azure Portal (Keys and Endpoint)
2. Update environment variable in Power Platform
3. Test connection from Power Automate flow

### Issue: Permission denied accessing Azure resources
**Possible causes:**
- Insufficient Azure RBAC permissions
- Managed Identity not assigned correct roles
- Resource firewall blocking access

**Resolution:**
1. Check Azure RBAC role assignments
2. Verify Managed Identity has required roles
3. Check network security settings (firewall, VNet)

---

## Additional Documentation

For detailed implementation guides for enhanced authentication options:

- **Managed Identity**: See Azure AI Services documentation
- **Azure API Management**: See APIM with Azure OpenAI guide
- **Private Endpoints**: See Power Platform VNet support documentation
- **Service Principals**: See Microsoft Entra ID app registration guide

For deployment instructions, see **INSTRUCTIONS.md** in this directory.  
For technical architecture details, see **ABOUT.md** in this directory.

---

**Last Updated**: January 2026  
**Version**: 1.0  
**Maintained by**: RHAIL Team, Microsoft
