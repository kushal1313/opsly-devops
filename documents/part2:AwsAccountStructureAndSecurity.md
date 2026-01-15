## Multi-Account Structure

**Recommended Approach: AWS Control tower + Custom SCPs**

AWS Control Tower offers a straightforward way to set up and govern an AWS multi-account environment, following prescriptive best practices. AWS Control Tower orchestration extends the capabilities of AWS Organizations. AWS Control Tower applies preventive and detective controls (guardrails) to help keep your organizations and accounts from divergence from best practices (drift).

AWS Control Tower orchestration extends the capabilities of AWS Organizations.

**Proposed AWS Multi-Account Structure**

A multi-account strategy using AWS Organizations + Control Tower is recommended to enforce governance, security, and operational consistency.

**AWS Organization**

    1. Management Account(Root Account)
    2. Audit Account
    3. Log Account
    4. IT Account
    5. Sandbox Account
    6. Development Account
    7. Production Account

## Account-wise explaination

## 1. Management Account(Root Account)

**Purpose**
  - Root account of the organization
  - Account creation, Billing, and security governance

**Responsibilities**
  - For enabling AWS Organizations
  - Set up AWS Control Tower
  - Centralized billing & cost allocation
  - SCP (Service Control Policy) management

**Restrctions**
  - No workloads deployed here
  - Restricted access (Cloud admins only)
  - MFA enforced on root user

**2. Audit Account**

**Purpose**
  - For Centralized security visibility and compliance.
  - AWS Config for custom rule definition.
  - Amazon GuardDuty for threat detection at organization level.
  - AWS Security Hub which holds findings from all the accounts providing a security score.

**3. Log Account**

**Purpose**
  - AWS Cloudtrail events and logs of all the accounts stored here.
  - AWS Config configuration history logs are stored(Org-level).
  - Amazon GuardDuty findings and logs at organization level.
  - Storage of VPC Flow logs 

**4. IT Account**

**Purpose**
  - AWS infrastructure for IT eco system like VPN, Firewall, Assert Explorer application, System endpoints, User management.

**5. Sandbox Account**

**Purpose**
  - AWS infrastructure of all the POC's. 

**6. Development Account**

**Purpose**
  - AWS infrastructure of all the dev/staging/UAT environment exists in development account. 

**7. Production Account**

**Purpose**
  - AWS infrastructure of all the dev/integration/UAT environment exists in development account. 