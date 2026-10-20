# Ascendant

Implementation repository for the Ascendant CV site. Product scope, features, and PBIs live in `Ascendant-Product`.

The site is a static production placeholder for Azure Static Web Apps. Profile content is not in this tree. Architecture and the decisions that produced this layout are in `docs/ARCHITECTURE.md` and `docs/DECISIONS.md`.

No Azure resource is provisioned by cloning this repository.

## Local check

```powershell
./scripts/build.ps1
```

The script writes `dist/` and checks the placeholder title, the profile role-label contract, and that the artifact does not contain state or secret files.

## Layout

| Path | Role |
|---|---|
| `site/` | Files that ship to production |
| `contracts/` | Profile document for a later milestone; not deployed |
| `scripts/` | Build and HTTPS smoke check |
| `infra/terraform/` | Production resource group and Static Web App |
| `infra/bootstrap/` | One-time state storage and federated identity |
| `.github/workflows/ci.yml` | Pull-request checks, no cloud login |
| `.github/workflows/cd.yml` | Production upload from `main` |
| `.github/workflows/infra.yml` | Terraform plan or apply from `main` |
| `.github/workflows/oidc-probe.yml` | Prints the OpenID Connect subject to trust |

Bootstrap and apply create real Azure resources, including a paid storage account for Terraform state. Run them only after that spend is approved. The runbook is in `docs/ARCHITECTURE.md`.
