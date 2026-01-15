## Multi-Account Structure

**Recommended Approach: AWS Control tower + Custom SCPs**

AWS Control Tower offers a straightforward way to set up and govern an AWS multi-account environment, following prescriptive best practices. AWS Control Tower orchestration extends the capabilities of AWS Organizations. AWS Control Tower applies preventive and detective controls (guardrails) to help keep your organizations and accounts from divergence from best practices (drift).

AWS Control Tower orchestration extends the capabilities of AWS Organizations.

**Proposed AWS Multi-Account Structure**

```
Root (Management) Account
│
├── Security OU
│   └── Audit Account
│
├── Log OU
│   └── Log Account
│
├── Development OU
│   ├── Staging Account
│   └── Integration Account
│
├── Production OU
│   └── Production Account
│
├── IT OU
│   └── IT Account
│
└── Sandbox OU
    └── POC Account
```

### Detailed Explanation

This structure organizes multiple AWS accounts in a hierarchical way, similar to how a company organizes departments. Here's what each part means:

**Root (Management) Account**
- This is the "parent" account that controls everything. Think of it as the headquarters of your AWS setup.
- It is the root account of the entire AWS organization - the master account that owns and controls all other accounts.
- **Account Management**: This account creates new AWS accounts and manages the overall structure of your organization.
- **Billing & Cost Management**: All costs from other accounts appear here in one central bill. This account manages billing for the entire organization.
- **Security Governance**: It sets up and manages security policies (called SCPs - Service Control Policies) that apply rules across all accounts, like preventing certain risky actions.
- **Cost Optimization**: It manages Savings Plans and Reserved Instances - these are ways to get discounts on AWS services by committing to use them for a longer period. Managing them centrally helps get better deals.
- **Marketplace Purchases**: When you buy software or services from the AWS Marketplace, those purchases are managed through this account.
- **Identity & Access Management**: Identity Centre (formerly AWS SSO) is configured here. This is the central place where you manage who can access which accounts and what they can do - like a master key system for all your AWS accounts.
- **AWS Credits Management**: Any credits, discounts, or promotional benefits from AWS are managed and applied through this account.
- **Service Control Policies (SCP) Management**: This account creates and manages SCPs, which are like company-wide rules that prevent accounts from doing certain things (for example, preventing anyone from accidentally deleting important resources).

**Important Restrictions on Root Account:**
- **No Workloads**: This account should never run any actual applications, websites, or services. It's purely for management purposes.
- **Restricted Access**: Only cloud administrators (the people who manage the AWS setup) should have access to this account. Regular developers or users don't need access here.
- **MFA Required**: Multi-Factor Authentication (MFA) is enforced on the root user. This means even if someone knows the password, they need a second verification (like a code from a phone) to log in, making it much more secure.

**Organizational Units (OUs)**
- OUs are like folders that group related accounts together. They help apply the same rules and policies to multiple accounts at once.
- For example, all accounts in the "Production OU" can have the same security rules applied automatically.

**Security OU → Audit Account**
- This account is like a security monitoring center. It watches all other accounts for security problems and provides centralized security visibility and compliance monitoring.
- **AWS Config**: This service is used to define custom rules that check if your AWS resources are configured correctly and following security best practices. For example, it can check if all S3 buckets are encrypted or if security groups are properly configured.
- **Amazon GuardDuty**: This is a threat detection service that continuously monitors all accounts in your organization for malicious activity, unauthorized access, or suspicious behavior. It acts like a security guard that never sleeps, watching for threats across your entire AWS setup.
- **AWS Security Hub**: This is a central dashboard that collects security findings from all accounts and provides an overall security score. Think of it as a security report card that shows how secure your entire organization is, with details about any issues found across all accounts.
- Security teams use this account to get a complete picture of security across the organization and ensure compliance with security standards.

**Log OU → Log Account**
- This is the "record keeper" account. It stores all activity logs from every other account in a centralized location.
- **AWS CloudTrail**: All events and logs from every account are stored here. CloudTrail records who did what, when, and from where - like a detailed audit trail of every action taken in your AWS accounts (logins, resource creation, configuration changes, etc.).
- **AWS Config Configuration History**: The history of how your AWS resources were configured over time is stored here at the organization level. This helps you see what changed and when, which is useful for troubleshooting and compliance.
- **Amazon GuardDuty Findings and Logs**: All the threat detection findings and logs from GuardDuty across the entire organization are stored here, providing a centralized view of security threats.
- **VPC Flow Logs**: Network traffic logs from all Virtual Private Clouds (VPCs) across accounts are stored here. This shows what network traffic is flowing through your systems, which is crucial for security analysis and troubleshooting network issues.
- This centralized logging is useful for troubleshooting problems, investigating security incidents, meeting compliance requirements, and having a complete record of all activities across your AWS organization.

**Development OU → Staging Account & Integration Account**
- **Staging Account**: This is where you test your application in an environment that looks exactly like production, but it's safe to break things. It's used for final testing before releasing to production.
- **Integration Account**: This is where different parts of your system are connected and tested together before going to production. It ensures that all components work well together.
- **Development Account**: This account hosts the AWS infrastructure for all development, staging, and UAT (User Acceptance Testing) environments. UAT is where business users test the application to make sure it meets their requirements before it goes to production.
- All of these are "practice" environments where developers can test without affecting real users. They allow teams to develop, test, and validate changes in a safe environment.

**Production OU → Production Account**
- This is where your real, live application runs that actual customers use.
- It hosts the AWS infrastructure for the production environment - the live system that serves real users and handles real business operations.

**IT OU → IT Account**
- This account hosts AWS infrastructure for the IT ecosystem - the tools and systems that the IT department uses to manage the organization.
- **VPN (Virtual Private Network)**: Infrastructure for secure remote access, allowing employees to securely connect to company resources from anywhere.
- **Firewall**: Network security infrastructure to protect and filter network traffic.
- **Asset Explorer Application**: Tools for tracking and managing IT assets across the organization.
- **System Endpoints**: Infrastructure for managing and connecting to various system endpoints and services.
- **User Management**: Systems and tools for managing user accounts, permissions, and access across the organization.
- It's separate from application accounts to keep IT tools isolated and secure, ensuring that IT management infrastructure doesn't interfere with or get affected by application workloads.

**Sandbox OU → POC Account**
- This account hosts AWS infrastructure for all POC projects - experimental work to test if new technologies, approaches, or ideas are viable before investing more resources.
- Developers can test new technologies or approaches here without any restrictions, allowing for innovation and experimentation.

**Why This Structure?**
- **Security**: If one account gets compromised, others are protected because they're separate.
- **Cost Management**: You can see exactly how much each environment (dev, staging, production) costs.
- **Compliance**: Different environments can have different rules - production has strict rules, sandbox can be more flexible.
- **Isolation**: Problems in one account (like a development mistake) won't affect others (like production).
- **Organization**: It's easier to manage and understand your AWS setup when accounts are grouped by purpose.