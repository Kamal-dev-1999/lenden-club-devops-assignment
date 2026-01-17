# DevSecOps Pipeline Project Documentation

> **Author:** Kamal Chandramani Tripathi  
> **Date:** January 16, 2026  
> **Repository:** [lenden-club-devops-assignment](https://github.com/Kamal-dev-1999/lenden-club-devops-assignment)

---

## 📋 Project Overview

This project demonstrates a complete **DevSecOps CI/CD pipeline** that automatically scans Infrastructure as Code (IaC) for security vulnerabilities before deployment. The pipeline follows the **"Shift Left"** security approach—catching and fixing security flaws early in the development cycle rather than in production.

### Tech Stack
| Component | Technology |
|-----------|------------|
| Application | Node.js / Express |
| Containerization | Docker |
| Infrastructure | Terraform (AWS) |
| CI/CD | Jenkins |
| Security Scanner | Trivy |

---

## 🏗️ Architecture Overview

### High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              DEVELOPER WORKSTATION                               │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                          │
│  │   app.js    │    │  Dockerfile │    │   main.tf   │                          │
│  │  (Node.js)  │    │  (Docker)   │    │ (Terraform) │                          │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘                          │
│         └──────────────────┼──────────────────┘                                  │
│                            ▼                                                     │
│                    ┌──────────────┐                                              │
│                    │   git push   │                                              │
│                    └──────┬───────┘                                              │
└───────────────────────────┼─────────────────────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                   GITHUB                                         │
│                    ┌──────────────────────────┐                                  │
│                    │  lenden-club-devops-     │                                  │
│                    │  assignment (main)       │                                  │
│                    └────────────┬─────────────┘                                  │
└─────────────────────────────────┼───────────────────────────────────────────────┘
                                  ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           JENKINS CI/CD PIPELINE                                 │
│                                                                                  │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐              │
│  │  STAGE 1        │    │  STAGE 2        │    │  STAGE 3        │              │
│  │  Install Tools  │───▶│  Security Scan  │───▶│  Terraform Plan │              │
│  │  ┌───────────┐  │    │  ┌───────────┐  │    │  ┌───────────┐  │              │
│  │  │  Trivy    │  │    │  │  Trivy    │  │    │  │ terraform │  │              │
│  │  │  Terraform│  │    │  │  config . │  │    │  │   init    │  │              │
│  │  └───────────┘  │    │  └───────────┘  │    │  │   plan    │  │              │
│  └─────────────────┘    └────────┬────────┘    │  └───────────┘  │              │
│                                  │             └────────┬────────┘              │
│                                  ▼                      │                        │
│                         ┌───────────────┐               │                        │
│                         │ SCAN REPORT   │               │                        │
│                         │ - HIGH        │               │                        │
│                         │ - CRITICAL    │               │                        │
│                         └───────────────┘               │                        │
└─────────────────────────────────────────────────────────┼───────────────────────┘
                                                          ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              AWS CLOUD (us-east-1)                               │
│                                                                                  │
│  ┌───────────────────────────────────────────────────────────────────────────┐  │
│  │                        VPC (10.0.0.0/16)                                   │  │
│  │  ┌─────────────────────────────────────────────────────────────────────┐  │  │
│  │  │                    Public Subnet (10.0.1.0/24)                       │  │  │
│  │  │                                                                      │  │  │
│  │  │   ┌─────────────────────────────────────────────────────────────┐   │  │  │
│  │  │   │                EC2 Instance (t2.micro)                      │   │  │  │
│  │  │   │   ┌─────────────────┐    ┌─────────────────────────────┐   │   │  │  │
│  │  │   │   │     Docker      │    │    Security Features:       │   │   │  │  │
│  │  │   │   │  ┌───────────┐  │    │    ✅ IMDSv2 Required       │   │   │  │  │
│  │  │   │   │  │  Node.js  │  │    │    ✅ EBS Encrypted         │   │   │  │  │
│  │  │   │   │  │   App     │  │    │    ✅ Restricted SSH        │   │   │  │  │
│  │  │   │   │  │  :3000    │  │    │    ✅ VPC-only Egress       │   │   │  │  │
│  │  │   │   │  └───────────┘  │    └─────────────────────────────┘   │   │  │  │
│  │  │   │   └─────────────────┘                                       │   │  │  │
│  │  │   └─────────────────────────────────────────────────────────────┘   │  │  │
│  │  │                              │                                       │  │  │
│  │  └──────────────────────────────┼───────────────────────────────────────┘  │  │
│  │                                 │                                          │  │
│  │  ┌──────────────────────────────┼───────────────────────────────────────┐  │  │
│  │  │              Security Group (devsecops-secure-sg)                    │  │  │
│  │  │                              │                                       │  │  │
│  │  │   INGRESS:                   │      EGRESS:                          │  │  │
│  │  │   ├─ SSH (22) ← Trusted IP   │      └─ All ← VPC CIDR only           │  │  │
│  │  │   ├─ HTTP (80) ← 0.0.0.0/0   │         (10.0.0.0/16)                 │  │  │
│  │  │   ├─ HTTPS (443) ← 0.0.0.0/0 │                                       │  │  │
│  │  │   └─ App (3000) ← 0.0.0.0/0  │                                       │  │  │
│  │  └──────────────────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────────────────┘  │
│                                      │                                          │
│  ┌──────────────┐    ┌───────────────┴───────────────┐                          │
│  │   Internet   │◀───│       Internet Gateway        │                          │
│  │   Gateway    │    │      (devsecops-igw)          │                          │
│  └──────────────┘    └───────────────────────────────┘                          │
└─────────────────────────────────────────────────────────────────────────────────┘
                            │
                            ▼
                    ┌───────────────┐
                    │    USERS      │
                    │  Access App   │
                    │  on :3000     │
                    └───────────────┘
```

### Component Description

| Component | Purpose |
|-----------|---------|
| **GitHub Repository** | Source control for all IaC and application code |
| **Jenkins Pipeline** | Automates security scanning and infrastructure validation |
| **Trivy Scanner** | Detects misconfigurations in Terraform and Dockerfile |
| **Terraform** | Provisions and manages AWS infrastructure |
| **AWS VPC** | Isolated network environment (10.0.0.0/16) |
| **EC2 Instance** | Hosts the Dockerized Node.js application |
| **Security Group** | Firewall rules controlling inbound/outbound traffic |
| **Docker Container** | Runs Node.js app as non-root user |

---

## 🔴 Error Log Phase (Build #14)

The initial security scan revealed **multiple vulnerabilities** in our infrastructure code:

### Scan Summary
| File | Type | Misconfigurations |
|------|------|-------------------|
| main.tf | Terraform | 3 CRITICAL |
| Dockerfile | Docker | 1 HIGH |

### Critical Findings (AVD-AWS-0104)

**Issue:** Security group egress rules allowed unrestricted outbound traffic to `0.0.0.0/0`

```
main.tf:125 - cidr_blocks = ["0.0.0.0/0"]  ❌
main.tf:134 - cidr_blocks = ["0.0.0.0/0"]  ❌
main.tf:143 - cidr_blocks = ["0.0.0.0/0"]  ❌
```

**Risk:** Attackers could exfiltrate data to any IP address on the internet if the instance is compromised.

### High Severity Findings

| ID | Issue | Risk |
|----|-------|------|
| **AVD-AWS-0107** | SSH open to `0.0.0.0/0` | Brute force attacks from anywhere |
| **AVD-AWS-0131** | EBS volume not encrypted | Data at rest exposed |
| **AVD-AWS-0028** | IMDSv1 allowed | SSRF attacks can steal credentials |
| **AVD-AWS-0164** | Subnet auto-assigns public IPs | Unintended internet exposure |
| **AVD-DS-0002** | Docker running as root | Container escape vulnerability |

---

## 🛠️ Remediation & Fixes

The following changes were implemented to achieve **Zero Critical** status:

### 1. Restricted Egress Traffic (CRITICAL → Fixed)
```hcl
# BEFORE: Unrestricted egress
egress {
  cidr_blocks = ["0.0.0.0/0"]  ❌
}

# AFTER: VPC-only egress
egress {
  description = "Allow all outbound within VPC"
  cidr_blocks = ["10.0.0.0/16"]  ✅
}
```

### 2. Restricted SSH Access (HIGH → Fixed)
```hcl
# BEFORE: SSH from anywhere
cidr_blocks = ["0.0.0.0/0"]  ❌

# AFTER: SSH from trusted IP range only
cidr_blocks = [var.allowed_ssh_cidr]  ✅  # Default: "10.0.0.0/8"
```

### 3. Enabled EBS Encryption (HIGH → Fixed)
```hcl
root_block_device {
  encrypted = true  ✅
}
```

### 4. Enforced IMDSv2 (HIGH → Fixed)
```hcl
metadata_options {
  http_tokens = "required"  ✅  # Forces IMDSv2
}
```

### 5. Disabled Auto Public IP on Subnet (HIGH → Fixed)
```hcl
map_public_ip_on_launch = false  ✅
```

### 6. Docker Non-Root User (HIGH → Fixed)
```dockerfile
# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodeuser -u 1001 -G nodejs

# Switch to non-root user
USER nodeuser  ✅
```

---

## ✅ Final Outcome (Build #15)

After applying all remediation steps, the final Trivy scan shows:

### Scan Results
```
┌─────────────────┬────────────┬───────────────────┐
│     Target      │    Type    │ Misconfigurations │
├─────────────────┼────────────┼───────────────────┤
│ main.tf         │ terraform  │         0         │  ✅
├─────────────────┼────────────┼───────────────────┤
│ Dockerfile      │ dockerfile │         0         │  ✅
└─────────────────┴────────────┴───────────────────┘
```

### Security Posture Improvement

| Metric | Before (Build #14) | After (Build #15) |
|--------|-------------------|-------------------|
| Critical Issues | 3 | **0** ✅ |
| High Issues | 5 | **0** ✅ |
| Total Misconfigurations | 8 | **0** ✅ |

---

## 📁 Project Structure

```
├── app.js                 # Node.js Express application
├── package.json           # Node.js dependencies
├── Dockerfile             # Container configuration (hardened)
├── docker-compose.yml     # Docker Compose setup
├── main.tf                # Terraform infrastructure (hardened)
├── variables.tf           # Terraform variables
├── outputs.tf             # Terraform outputs
├── user_data.sh           # EC2 bootstrap script
├── Jenkinsfile            # CI/CD pipeline definition
└── README.md              # This documentation
```

---

## 🎯 Assignment Goals Met

| Requirement | Status |
|-------------|--------|
| Create vulnerable IaC intentionally | ✅ Completed |
| Detect vulnerabilities with security scanner | ✅ Trivy detected 8 issues |
| Document the security risks | ✅ Explained in this README |
| Remediate all Critical/High issues | ✅ Zero issues remaining |
| Implement "Secure by Default" configuration | ✅ All best practices applied |
| Demonstrate Shift-Left security approach | ✅ Pipeline catches issues pre-deploy |

---

## 📚 References

- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [AWS Security Best Practices](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)

---

## 🤖 GenAI Usage Log

This section documents how Generative AI (GitHub Copilot - Claude Opus 4.5) was used throughout this project, in compliance with assignment transparency requirements.

### AI Assistance Summary

| Task Category | AI Contribution | Human Verification |
|---------------|-----------------|-------------------|
| Code Generation | Generated boilerplate code | Reviewed and tested all code |
| Security Fixes | Suggested remediation patterns | Validated against AWS/Trivy docs |
| Documentation | Structured README format | Edited for accuracy |
| Troubleshooting | Debugged Jenkins pipeline errors | Verified fixes in live environment |

### Detailed Usage Log

#### 1. Project Setup & Scaffolding
| Prompt | AI Output | Outcome |
|--------|-----------|---------|
| "Create a simple Node.js web application with Docker setup for DevSecOps" | Generated `app.js`, `package.json`, `Dockerfile`, `docker-compose.yml` | ✅ Used as base, tested locally |
| "Create Terraform code with intentional SSH vulnerability" | Generated `main.tf`, `variables.tf`, `outputs.tf` with `0.0.0.0/0` SSH rule | ✅ Used to demonstrate vulnerability detection |

#### 2. Infrastructure Development
| Prompt | AI Output | Outcome |
|--------|-----------|---------|
| "Update Terraform to create VPC, subnet, internet gateway" | Generated complete VPC infrastructure code | ✅ Successfully deployed to AWS |
| "Fix EC2 key pair issues" | Provided troubleshooting steps and variable configuration | ✅ Resolved deployment error |

#### 3. Jenkins Pipeline Development
| Prompt | AI Output | Outcome |
|--------|-----------|---------|
| "Create Jenkinsfile for CI/CD pipeline with security scanning" | Generated declarative pipeline with 3 stages | ✅ Modified for Jenkins environment |
| "Fix Jenkins permission denied errors with apt-get" | Suggested using `/tmp/tools` directory with PATH update | ✅ Pipeline executed successfully |
| "Fix unzip overwrite prompt issue" | Added `-o` flag and file existence checks | ✅ Build #13 passed |

#### 4. Security Remediation
| Prompt | AI Output | Outcome |
|--------|-----------|---------|
| "Explain why unrestricted SSH access is dangerous" | Provided risk explanation with real-world examples (Capital One breach) | ✅ Used in documentation |
| "Fix all Trivy security findings" | Generated hardened `main.tf` and `Dockerfile` | ✅ Build #15: 0 Critical, 0 High |

#### 5. Documentation
| Prompt | AI Output | Outcome |
|--------|-----------|---------|
| "Generate project documentation with pipeline overview and remediation steps" | Created structured README with tables and code blocks | ✅ Edited for assignment requirements |

### AI Tools Used

| Tool | Model | Purpose |
|------|-------|---------|
| GitHub Copilot | Claude Opus 4.5 | Code generation, debugging, documentation |
| VS Code Integration | Copilot Chat | Interactive problem-solving |

### Learning Outcomes from AI Assistance

1. **Terraform Best Practices**: Learned about IMDSv2, EBS encryption, and security group hardening
2. **Docker Security**: Understood importance of non-root users in containers
3. **Jenkins Pipeline**: Gained experience with declarative pipelines and tool installation
4. **Shift-Left Security**: Understood how to integrate security scanning early in CI/CD

### Human Contributions

While AI assisted with code generation and suggestions, the following were done manually:

- ✅ AWS account setup and credential configuration
- ✅ Jenkins server installation and plugin configuration
- ✅ Git repository creation and branch management
- ✅ Testing and validation of all deployed infrastructure
- ✅ Final review and approval of all code changes
- ✅ Decision-making on security trade-offs (e.g., VPC-only egress vs. internet access)

### Ethical Considerations

- All AI-generated code was reviewed before use
- Security recommendations were validated against official documentation
- No sensitive data (credentials, keys) was shared with AI
- AI suggestions were treated as starting points, not final solutions

---

**Pipeline Status:** ✅ SUCCESS  
**Security Scan:** ✅ PASSED (0 Critical, 0 High)  
**Infrastructure:** ✅ Secure by Default
