# Ascendant

Engineering repository for the **Ascendant** interactive RPG-inspired CV.

## Project repositories
- Product Owner requirements, Features, PBIs, decisions: [Ascendant-Product](https://github.com/xulongjun/Ascendant-Product)
- Code, Terraform, GitHub Actions and the site: **Ascendant** (this repository)

## Platform
- Azure Static Web Apps Free, single production environment
- Terraform for the resource group and Static Web App, Azure Blob backend state
- GitHub Actions CI/CD
- Entra workload identity via GitHub OIDC for Terraform, no long-lived client secret
- Site upload uses a separate GitHub Actions secret, `AZURE_STATIC_WEB_APPS_API_TOKEN`

Architecture and the decisions for this layout are in `docs/ARCHITECTURE.md` and `docs/DECISIONS.md`.

## Milestone order
PBI-001 code repository foundation; PBI-002 governance; PBI-004 Terraform backend + identity; PBI-003 infrastructure; PBI-005/006 CI/CD; PBI-007 public production HTTPS verification. **No RPG interface or art until the infrastructure pipeline is live.**

## Security
Both GitHub repositories are PUBLIC. No plaintext secrets, .env, tfstate, deployment keys, personal addresses, nonpublic CV details, or confidential data. Store sensitive workflow values in GitHub Secrets and nonsensitive configuration in GitHub Variables. Publicly rendered CV details must be approved for publication.

## Current status
The production placeholder, Terraform, bootstrap script, and workflows are on `main`. No Azure resource has been created. Provisioning, including the paid state storage account, requires separate approval. The runbook is in `docs/ARCHITECTURE.md`.

## Local check

```powershell
./scripts/build.ps1
```

The script writes `dist/` and checks the placeholder title, the profile role-label contract, and that the artifact does not contain state or secret files.

## Layout

| Path | Role |
|---|---|
| `site/` | Production placeholder that ships |
| `contracts/` | Profile document for a later milestone; not deployed |
| `scripts/` | Build and HTTPS smoke check |
| `infra/terraform/` | Production resource group and Static Web App |
| `infra/bootstrap/` | One-time state storage and federated identity |
| `.github/workflows/ci.yml` | Pull-request checks, no cloud login |
| `.github/workflows/cd.yml` | Production upload from `main` |
| `.github/workflows/infra.yml` | Terraform plan or apply from `main` |
| `.github/workflows/oidc-probe.yml` | Prints the OpenID Connect subject to trust |
