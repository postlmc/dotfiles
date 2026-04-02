---
description: This file describes the Terraform code style for the project.
applyTo: '**/*.{tf,tfvars,tfvars.json}'
---

# Terraform Instructions

## Core & Stucture
- Use variables; no hardcoded values
- Organize into reuseable, versioned modules (semver)
- File structure: `main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`
- Lock provider versions
- Tag all resources
- Limit `count`/`for_each` usage. Handle edge cases with null conditionals. Use `depends_on` sparingly.

## State Management
- Use remote, encryted backends (S3, Azure Blob, GCS) with state locking
- Isolate environments via workspaces or dedicated backends/state files
- Monitor for drift and backup state

## Security
- Never hardcode secrets. Use vaults or environment variables.
- Encrypt storage and communication
- Enforce granular RBAC/security groups

## Workflow & CI/CD
- Always run `terraform fmt`, `terraform validate`, `tflint`, and `terrascan`
- CI/CD: Require `terraform plan` approval before `apply`. Automate tests (`terratest`).
- Cache provider plugins locally to speed up CI
- Document modules with examples and explicit I/O definitions in READMEs

## Resources
- [Terraform Registry](https://registry.terraform.io/)
- [State Management](https://www.terraform.io/docs/state/index.html)
