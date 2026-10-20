# Engineering baseline — PBI-001

## Repositories
- Product: https://github.com/xulongjun/Ascendant-Product
- Engineering: https://github.com/xulongjun/Ascendant

## Local checkout (optional, no ZIP)
```powershell
cd D:\source\Cleancode_Consulting\Useless-Product
git clone https://github.com/xulongjun/Ascendant-Product.git
git clone https://github.com/xulongjun/Ascendant.git
```

If either folder already exists, run `git status` and `git remote -v` rather than recloning or overwriting.

## Security first
Both repositories are public. See Product `docs/SECURITY.md`. No private information or credentials committed; production secret values in GitHub Actions Secrets, public/nonsecret identifiers in Variables if approved.

## Structure now on main
```text
Ascendant/
  .github/workflows/    # ci, cd, infra plan/apply, oidc probe
  infra/terraform/      # production resource group and Static Web App
  infra/bootstrap/      # one-time state storage and federated identity
  site/                 # production placeholder, not the RPG interface
  contracts/            # profile schema, not deployed
  docs/                 # architecture, decisions, this baseline
```

`src/` stays absent until a later milestone needs a framework. The placeholder build copies `site/` to `dist/`.

## Infrastructure milestone handoff
1. PO approves access scope, subscription and cost controls.
2. PBI-004 bootstrap Azure Storage state and least-privilege GitHub OIDC.
3. PBI-003 Terraform Azure Static Web Apps Free and RG.
4. PBI-005 validate plans/build on PR, PBI-006 deploy production from main.
5. PBI-007 verify public HTTPS smoke test, update/redeploy and rollback.

This repository baseline creates **no** cloud resources and does **not** enable Actions deployment.


> Git policy: direct commits to `main` by PO instruction (2026-10-20); no mandatory PR.
