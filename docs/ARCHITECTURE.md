# Ascendant implementation architecture

Status: designed and encoded in this repository on 2026-10-20. No Azure resource has been created, and no deployment has run.

Product governance stays in `Ascendant-Product`. This repository (`xulongjun/Ascendant`) is the implementation. The product draft name `ascendant-product` is not used for resources.

## What is being built

A public CV, read by recruiters, hosted as one production static site. Milestone M1 publishes a neutral placeholder. Later milestones replace the page content from an approved profile document. The site does not gain an API, a database, or an account system.

```text
pull request
  -> ci.yml
       site build (site/ -> dist/)
       terraform fmt / init -backend=false / validate

main, site changes
  -> cd.yml  (GitHub environment: production)
       build dist/
       upload with the Static Web App deployment token
       HTTPS smoke check for the placeholder title

main, manual
  -> infra.yml  (GitHub environment: production)
       OpenID Connect to Entra ID
       terraform plan, or plan then apply

one time, on an operator machine, after approval
  -> infra/bootstrap/bootstrap.ps1
       state storage, empty production resource group,
       app registration, one federated credential
```

## Planes

**Experience.** `site/` is the only publishable input. `scripts/build.ps1` copies it to `dist/` and refuses secret-shaped files. `dist/` is the only deploy artifact. `contracts/profile.schema.json` is the future profile document. It is not copied into `dist/`. The placeholder page does not invent employment history, and its role labels are not part of the page.

**Delivery.** GitHub Actions on `main` uploads `dist/` with `Azure/static-web-apps-deploy`, `skip_app_build: true`. The deployment token is the GitHub environment secret `AZURE_STATIC_WEB_APPS_API_TOKEN`. Pull requests do not deploy and do not receive a GitHub token permission that can assume the Azure identity.

**Control.** Terraform in `infra/terraform/` owns the production resource group and one Static Web App. Remote state is an Azure Blob that Terraform does not own. Bootstrap creates that blob, then the app is imported into state once. Provider `hashicorp/azurerm` `5.10.0`. Terraform CLI `1.16.6`.

## Azure resources

| Resource | Name | Who creates it | Cost |
|---|---|---|---|
| State resource group | `rg-ascendant-tfstate` | bootstrap script | resource group itself has no charge |
| Storage account and `tfstate` container | `stascendant` + approved suffix | bootstrap script | Standard LRS. This is a paid resource, expected to stay small. Approval is required before `-Apply`. |
| Production resource group | `rg-ascendant-prd` | bootstrap creates the empty group; Terraform imports and then owns it | no charge for the group |
| Static Web App | `swa-ascendant-prd-<suffix>` | Terraform | Free SKU, hardcoded |

Tags: `project=ascendant`, `environment=prod`, `managed-by=terraform` on Terraform resources and `managed-by=bootstrap` on bootstrap resources.

Region default is `westeurope`, set in `infra/terraform/prod.tfvars`.

The Static Web App is Free, `preview_environments_enabled` is false, and both resources set `prevent_destroy`. Removing them is a reviewed code change followed by an operator destroy, not a workflow input.

There is no API, database, App Service plan, Key Vault, CDN, custom domain, or Log Analytics workspace in this design.

## Identity

Two separate credentials.

1. **Terraform.** Entra app registration `sp-ascendant-terraform`, no client secret. One federated credential trusts the GitHub Actions subject for the `production` environment. Bootstrap prints the two legal subjects (immutable form for repositories created after 2026-07-15, and the older name-based form). `-Apply` accepts `-ConfirmSubject` only when it equals one of those two, and only after `oidc-probe.yml` has printed the subject this repository actually issues.
2. **Site upload.** Static Web App deployment token, stored as a GitHub environment secret. Terraform's `api_key` output is sensitive and is not printed by the infra workflow. An operator copies it into GitHub once, and rotates it in Azure when required.

The app registration's rights are `Contributor` on `rg-ascendant-prd` and `Storage Blob Data Contributor` on the state storage account. It cannot register resource providers. The Terraform provider sets `resource_provider_registrations = "none"`. Bootstrap registers `Microsoft.Web` with the operator's own login.

State access uses `use_azuread_auth`. After the container exists, shared key access on the storage account is turned off.

Pull-request workflows do not log in to Azure. A pull request in this repository can change workflow files, so a plan job with a cloud credential would be a path to `apply`. Plan and apply run from `infra.yml` on `main`, inside the `production` environment.

## Content seam

`contracts/profile.schema.json` allows three role labels: Senior .NET Developer, Azure Developer, DevOps Engineer. A skill, once present, needs evidence. The build checks that this allowed set does not drift. Real profile data is a later milestone and is not in the placeholder.

## Rollback

Site rollback is a revert commit on `main`. That push runs `cd` again and uploads the restored `dist/`. `workflow_dispatch` on `cd` republishes the current `main` tip; it does not deploy an older ref, because the job is limited to `refs/heads/main`. Infra rollback is a forward Terraform change. `prevent_destroy` blocks deletion until a pull request removes it.

## Operator order

Do not start this order without approval. The storage account can incur a charge.

1. Create the GitHub environment `production` on `xulongjun/Ascendant`. Limit deployment branches to `main`. Required reviewers are appropriate while the first apply is still new.
2. Run the `oidc-probe` workflow on `main` and keep the printed `sub`.
3. Dry-run `infra/bootstrap/bootstrap.ps1`, compare subjects, then re-run with `-Apply` and that subject.
4. Put the printed identifiers into the `production` environment variables: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `TF_STATE_STORAGE_ACCOUNT`, `NAME_SUFFIX`. The state resource group and container names are fixed in `infra.yml` as `rg-ascendant-tfstate` and `tfstate`.
5. Import `azurerm_resource_group.prd` into the remote state, then run `infra` with action `plan`, then `apply`.
6. Copy the Static Web App deployment token into the environment secret `AZURE_STATIC_WEB_APPS_API_TOKEN`.
7. Merge a change under `site/` and confirm `cd` plus the smoke check.

Nothing in steps 1–7 has been executed.
