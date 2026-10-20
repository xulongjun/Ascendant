# Implementation decisions

Product decisions ADR-001 through ADR-008 are accepted in `Ascendant-Product` and are followed here. The rows below are decisions this repository had to make before code could exist.

| ID | Date | Status | Decision | Why |
|---|---|---|---|---|
| ADR-I01 | 2026-10-20 | Accepted | M1 publish artifact is static files. `scripts/build.ps1` copies `site/` to `dist/`. No frontend framework. | The product defers the framework until the interaction phase. The deploy contract is the `dist/` directory, so a later framework can replace the shell without a Terraform change. |
| ADR-I02 | 2026-10-20 | Accepted | Terraform uses Entra federation. Site upload uses the Static Web App deployment token. | An ARM login does not grant upload rights to the Static Web App. |
| ADR-I03 | 2026-10-20 | Accepted | Pull-request CI does not authenticate to Azure. Plan and apply run on `main` through `infra.yml` and the `production` environment. | A pull request can edit the workflow. A cloud credential on that workflow can be turned into an apply. |
| ADR-I04 | 2026-10-20 | Accepted | Free SKU and `preview_environments_enabled = false` are fixed in Terraform. `prevent_destroy` is set on the group and the site. | Preview environments and the Standard SKU are outside the approved spend and topology. |
| ADR-I05 | 2026-10-20 | Accepted | Names use `ascendant`, matching `xulongjun/Ascendant`. | The product name `ascendant-product` was a draft for a different repository. |
| ADR-I06 | 2026-10-20 | Accepted | Bootstrap creates the empty production resource group and the state account. Terraform imports the group and then owns it. The app registration is Contributor on that group only. | The group has to exist before its role assignment can be scoped. A subscription Contributor grant is wider than this project needs. |
| ADR-I07 | 2026-10-20 | Accepted | The federated subject is whatever `oidc-probe.yml` prints. Bootstrap will not invent it. | Repositories created after 2026-07-15 use `repo:OWNER@OWNER_ID/REPO@REPO_ID:environment:production`. Older repositories keep the name-only subject until they opt in. |
| ADR-I08 | 2026-10-20 | Accepted | Remote state is a Standard LRS storage account, shared keys disabled after bootstrap, Terraform authenticated with Entra. | The product requires remote state. The account is a paid resource and is called out so it is not created silently. |
