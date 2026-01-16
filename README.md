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

## 🔄 Pipeline Overview

The Jenkins pipeline consists of **three main stages**:

### Stage 1: Install Tools
- Installs **Trivy** (security scanner) and **Terraform** to the Jenkins agent
- Tools are cached in `/tmp/tools` for faster subsequent builds
- Ensures consistent tooling across all pipeline runs

### Stage 2: Infrastructure Security Scan (Trivy)
- Scans all Terraform (`.tf`) and Docker files for misconfigurations
- Checks against **HIGH** and **CRITICAL** severity levels
- Reports findings in a table format for easy review
- Does **not** block the build—allows visibility into issues

### Stage 3: Terraform Plan
- Initializes Terraform with AWS provider
- Generates an execution plan showing what infrastructure changes would occur
- Validates that the IaC is syntactically correct and deployable

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Install Tools  │───▶│  Security Scan  │───▶│ Terraform Plan  │
│   (Trivy, TF)   │    │    (Trivy)      │    │   (Validate)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

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

**Pipeline Status:** ✅ SUCCESS  
**Security Scan:** ✅ PASSED (0 Critical, 0 High)  
**Infrastructure:** ✅ Secure by Default
