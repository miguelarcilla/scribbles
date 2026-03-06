export interface MicrosoftCertification {
  id: string;
  title: string;
  url: string;
  credentialTypes: string[];
  searchKey: string;
}

export const MICROSOFT_CERTIFICATIONS_SOURCE_URL = 'https://learn.microsoft.com/api/contentbrowser/search/credentials';
export const MICROSOFT_CERTIFICATIONS_SOURCE_DATE = '2026-03-06';

interface RawMicrosoftCertification {
  title: string;
  url: string;
  credentialTypes: string[];
}

function slugify(input: string): string {
  return input
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 80);
}

function normalizeSearchKey(input: string): string {
  return input.trim().toLowerCase().replace(/[^a-z0-9]+/g, ' ');
}

const RAW_MICROSOFT_CERTIFICATIONS: RawMicrosoftCertification[] = [
  { title: 'GitHub Actions', url: '/credentials/certifications/github-actions/', credentialTypes: ['certification', 'fundamentals'] },
  { title: 'GitHub Administration', url: '/credentials/certifications/github-administration/', credentialTypes: ['certification', 'fundamentals'] },
  { title: 'GitHub Advanced Security', url: '/credentials/certifications/github-advanced-security/', credentialTypes: ['certification', 'fundamentals'] },
  { title: 'GitHub Copilot', url: '/credentials/certifications/github-copilot/', credentialTypes: ['certification', 'fundamentals'] },
  { title: 'GitHub Foundations', url: '/credentials/certifications/github-foundations/', credentialTypes: ['certification', 'fundamentals'] },
  { title: 'Microsoft 365 Certified: Administrator Expert', url: '/credentials/certifications/m365-administrator-expert/', credentialTypes: ['certification', 'role-based'] },
  { title: 'Microsoft 365 Certified: Collaboration Communications Systems Engineer Associate', url: '/credentials/certifications/m365-collaboration-communications-systems-engineer/', credentialTypes: ['certification', 'role-based'] },
  { title: 'Microsoft 365 Certified: Copilot and Agent Administration Fundamentals', url: '/credentials/certifications/copilot-and-agent-administration-fundamentals/', credentialTypes: ['certification', 'fundamentals'] },
  { title: 'Microsoft 365 Certified: Endpoint Administrator Associate', url: '/credentials/certifications/modern-desktop/', credentialTypes: ['certification', 'role-based'] },
  { title: 'Microsoft 365 Certified: Fundamentals', url: '/credentials/certifications/microsoft-365-fundamentals/', credentialTypes: ['certification', 'fundamentals'] },
  { title: 'Microsoft 365 Certified: Teams Administrator Associate', url: '/credentials/certifications/m365-teams-administrator-associate/', credentialTypes: ['certification', 'role-based'] },{ title: 'Microsoft Certified: AI Business Professional', url: '/credentials/certifications/ai-business-professional/', credentialTypes: ['certification', 'business'] },
  { title: 'Microsoft Certified: AI Transformation Leader', url: '/credentials/certifications/ai-transformation-leader/', credentialTypes: ['certification', 'business'] },
  { title: 'Microsoft Certified: Agentic AI Business Solutions Architect', url: '/credentials/certifications/agentic-ai-business-solutions-architect/', credentialTypes: ['certification', 'role-based'] },
  { title: 'Microsoft Certified: Azure AI Engineer Associate', url: '/credentials/certifications/azure-ai-engineer/', credentialTypes: ['certification', 'role-based'] },
  { title: 'Microsoft Certified: Azure AI Fundamentals', url: '/credentials/certifications/azure-ai-fundamentals/', credentialTypes: ['certification', 'fundamentals'] },
  { title: 'Microsoft Certified: Azure Administrator Associate', url: '/credentials/certifications/azure-administrator/', credentialTypes: ['certification', 'role-based'] },
  { title: 'Microsoft Certified: Azure Cosmos DB Developer Specialty', url: '/credentials/certifications/azure-cosmos-db-developer-specialty/', credentialTypes: ['certification', 'specialty'] },
  { title: 'Microsoft Certified: Azure Data Fundamentals', url: '/credentials/certifications/azure-data-fundamentals/', credentialTypes: ['certification', 'fundamentals'] },
  { title: 'Microsoft Certified: Azure Data Scientist Associate', url: '/credentials/certifications/azure-data-scientist/', credentialTypes: ['certification', 'role-based'] },
  { title: 'Microsoft Certified: Azure Database Administrator Associate', url: '/credentials/certifications/azure-database-administrator-associate/', credentialTypes: ['certification', 'role-based'] },
  { title: 'Microsoft Certified: Azure Developer Associate', url: '/credentials/certifications/azure-developer/', credentialTypes: ['certification', 'role-based'] },
  { title: 'Microsoft Certified: Azure Fundamentals', url: '/credentials/certifications/azure-fundamentals/', credentialTypes: ['certification', 'fundamentals'] },
  { title: 'Microsoft Certified: Azure Network Engineer Associate', url: '/credentials/certifications/azure-network-engineer-associate/', credentialTypes: ['certification', 'role-based'] },
  { title: 'Microsoft Certified: Azure Security Engineer Associate', url: '/credentials/certifications/azure-security-engineer/', credentialTypes: ['certification', 'role-based'] },
  { title: 'Microsoft Certified: Azure Solutions Architect Expert', url: '/credentials/certifications/azure-solutions-architect/', credentialTypes: ['certification', 'role-based'] },
  { title: 'Microsoft Certified: Azure Virtual Desktop Specialty', url: '/credentials/certifications/azure-virtual-desktop-specialty/', credentialTypes: ['certification', 'specialty'] },
  { title: 'Microsoft Certified: Azure for SAP Workloads Specialty', url: '/credentials/certifications/azure-for-sap-workloads-specialty/', credentialTypes: ['certification', 'specialty'] },
  { title: 'Microsoft Certified: Cybersecurity Architect Expert', url: '/credentials/certifications/cybersecurity-architect-expert/', credentialTypes: ['certification', 'role-based'] },
  { title: 'Microsoft Certified: DevOps Engineer Expert', url: '/credentials/certifications/devops-engineer/', credentialTypes: ['certification', 'role-based'] },
  { title: 'Microsoft Certified: Dynamics 365 Business Central Developer Associate', url: '/credentials/certifications/d365-business-central-developer-associate/', credentialTypes: ['certification', 'role-based'] },
  { title: 'Microsoft Certified: Dynamics 365 Business Central Functional Consultant Associate', url: '/credentials/certifications/d365-business-central-functional-consultant-associate/', credentialTypes: ['certification', 'role-based'] },
  { title: 'Microsoft Certified: Dynamics 365 Customer Experience Analyst Associate', url: '/credentials/certifications/d365-customer-experience-analyst-associate/', credentialTypes: ['certification', 'role-based'] },
  { title: 'Microsoft Certified: Dynamics 365 Customer Service Functional Consultant Associate', url: '/credentials/certifications/d365-functional-consultant-customer-service-v3/', credentialTypes: ['certification', 'role-based'] },
  { title: 'Microsoft Certified: Dynamics 365 Field Service Functional Consultant Associate', url: '/credentials/certifications/d365-functional-consultant-field-service/', credentialTypes: ['certification', 'role-based'] },
  { title: 'Microsoft Certified: Dynamics 365 Finance Functional Consultant Associate', url: '/credentials/certifications/d365-functional-consultant-financials/', credentialTypes: ['certification', 'role-based'] },
  { title: 'Microsoft Certified: Dynamics 365 Supply Chain Management Functional Consultant Associate', url: '/credentials/certifications/d365-functional-consultant-supply-chain-management/', credentialTypes: ['certification', 'role-based'] },
  { title: 'Microsoft Certified: Dynamics 365 Supply Chain Management Functional Consultant Expert', url: '/credentials/certifications/d365-supply-chain-management-functional-consultant-expert/', credentialTypes: ['certification', 'role-based'] },
  { title: 'Microsoft Certified: Dynamics 365: Finance and Operations Apps Developer Associate', url: '/credentials/certifications/d365-finance-and-operations-apps-developer-associate/', credentialTypes: ['certification', 'role-based'] },
  { title: 'Microsoft Certified: Dynamics 365: Finance and Operations Apps Solution Architect Expert', url: '/credentials/certifications/d365-finance-and-operations-apps-solution-architect-expert/', credentialTypes: ['certification', 'role-based'] },
  { title: 'Microsoft Certified: Fabric Analytics Engineer Associate', url: '/credentials/certifications/fabric-analytics-engineer-associate/', credentialTypes: ['certification', 'role-based'] },
  { title: 'Microsoft Certified: Fabric Data Engineer Associate', url: '/credentials/certifications/fabric-data-engineer-associate/', credentialTypes: ['certification', 'role-based'] },
  { title: 'Microsoft Certified: Identity and Access Administrator Associate', url: '/credentials/certifications/identity-and-access-administrator/', credentialTypes: ['certification', 'role-based'] },
  { title: 'Microsoft Certified: Information Security Administrator Associate', url: '/credentials/certifications/information-security-administrator/', credentialTypes: ['certification', 'role-based'] },
  { title: 'Microsoft Certified: Operationalizing Machine Learning and Generative AI Solutions (beta)', url: '/credentials/certifications/operationalizing-machine-learning-and-generative-ai-solutions/', credentialTypes: ['certification', 'role-based'] },
  { title: 'Microsoft Certified: Power Automate RPA Developer Associate', url: '/credentials/certifications/power-automate-rpa-developer-associate/', credentialTypes: ['certification', 'role-based'] },
  { title: 'Microsoft Certified: Power BI Data Analyst Associate', url: '/credentials/certifications/data-analyst-associate/', credentialTypes: ['certification', 'role-based'] },
  { title: 'Microsoft Certified: Power Platform Developer Associate', url: '/credentials/certifications/power-platform-developer-associate/', credentialTypes: ['certification', 'role-based'] },
  { title: 'Microsoft Certified: Power Platform Functional Consultant Associate', url: '/credentials/certifications/power-platform-functional-consultant-associate/', credentialTypes: ['certification', 'role-based'] },
  { title: 'Microsoft Certified: Power Platform Fundamentals', url: '/credentials/certifications/power-platform-fundamentals/', credentialTypes: ['certification', 'fundamentals'] },
  { title: 'Microsoft Certified: Power Platform Solution Architect Expert', url: '/credentials/certifications/power-platform-solution-architect-expert/', credentialTypes: ['certification', 'role-based'] },
  { title: 'Microsoft Certified: Security Operations Analyst Associate', url: '/credentials/certifications/security-operations-analyst/', credentialTypes: ['certification', 'role-based'] },
  { title: 'Microsoft Certified: Security, Compliance, and Identity Fundamentals', url: '/credentials/certifications/security-compliance-and-identity-fundamentals/', credentialTypes: ['certification', 'fundamentals'] },
  { title: 'Microsoft Certified: Windows Server Hybrid Administrator Associate', url: '/credentials/certifications/windows-server-hybrid-administrator/', credentialTypes: ['certification', 'role-based'] }
];

export const microsoftCertifications: MicrosoftCertification[] = RAW_MICROSOFT_CERTIFICATIONS.map((certification) => ({
  ...certification,
  id: slugify(certification.title),
  searchKey: normalizeSearchKey(certification.title),
}));