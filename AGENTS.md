# Ascendant — Engineering Agent Instructions

Before implementation, read the approved PBI and Feature in [Ascendant-Product](https://github.com/xulongjun/Ascendant-Product), particularly `docs/WORKFLOW.md`, `docs/ARCHITECTURE.md`, `docs/SECURITY.md` and `docs/DECISIONS.md`.

1. Implement only an explicitly approved PBI, directly on main with a scoped commit.
2. This is the **engineering** repo: app, `infra/terraform/`, `.github/workflows/`, operational runbooks. Product specifications live elsewhere.
3. The product is a truthful career-focused original RPG CV, not a clone of another game. Role: Senior .NET / Azure / DevOps Engineer; do not claim Architect.
4. **Infrastructure first:** `site/` is the production placeholder only. No portraits, game visuals, RPG interface, or backend until the deployment foundation milestone is completed.
5. Azure: exactly one production Static Web Apps environment initially, no preview/staging. Apply, IAM/RBAC edits, deployment, resource deletion or spending require explicit PO authorization.
6. Use Terraform remote Azure Blob state, OIDC for Azure ARM, secure site deployment authentication separately. Never commit state, private tfvars, secrets, local Azure profiles, `.env`, credentials, private CV data.
7. Use GitHub Secrets for sensitive values; Variables for nonsecret settings. A GitHub Secret must not be embedded in a public browser bundle.
8. Use commit CI and review evidence; never claim success without an actual run, site URL and acceptance when required.
9. No force push, rewriting history or unexpected existing work.


> Git policy: direct commits to `main` by PO instruction (2026-10-20); no mandatory PR.
