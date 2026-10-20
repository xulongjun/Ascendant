# Ascendant

Engineering repository for the **Ascendant** interactive RPG-inspired CV.

## Project repositories
- Product Owner requirements, Features, PBIs, decisions: [Ascendant-Product](https://github.com/xulongjun/Ascendant-Product)
- Code, Terraform, GitHub Actions and future site: **Ascendant** (this repository)

## Intended platform
- Azure Static Web Apps Free (single **production** environment)
- Terraform for Azure resources, secured Azure Blob backend state
- GitHub Actions CI/CD
- Azure workload identity / GitHub OIDC for Terraform (no long-lived client secret)
- Website deployment authorization separately stored as a GitHub Actions Secret, if token-based approach is selected

## Milestone order
PBI-001 code repository foundation; PBI-002 governance; PBI-004 Terraform backend + identity; PBI-003 infrastructure; PBI-005/006 CI/CD; PBI-007 public production HTTPS verification. **No RPG interface or art until the infrastructure pipeline is live.**

## Security
Both GitHub repositories are PUBLIC. No plaintext secrets, .env, tfstate, deployment keys, personal addresses, nonpublic CV details, or confidential data. Store sensitive workflow values in GitHub Secrets and nonsensitive configuration in GitHub Variables. Publicly rendered CV details must be approved for publication.

## Current status
Repository initialized; Terraform, workflow and application code **not yet implemented**. Provisioning Azure resources requires separate PO authorization.
