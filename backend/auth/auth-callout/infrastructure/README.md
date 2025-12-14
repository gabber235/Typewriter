# Auth Callout Infrastructure

This directory contains Terraform configuration for deploying the `auth-callout` wasmCloud component and its required infrastructure.

## Overview

The auth-callout component is responsible for NATS authentication callouts. It validates JWTs from Authentik and issues NATS user credentials.

## Resources Created

- **ExternalSecret** (`auth-callout-secrets`): Syncs NATS issuer and signing keys from OpenBao to Kubernetes
- **ConfigMap** (`auth-callout-config`): Contains issuer configuration (URLs, account keys)
- **WorkloadDeployment** (`auth-callout`): The wasmCloud component deployment

## Prerequisites

1. OpenBao/Vault must be running and accessible
2. The `openbao-backend` ClusterSecretStore must exist
3. NATS must be deployed with the TYPEWRITER account configured
4. The wasmcloud namespace must exist (created by `v2/9_wasmcloud`)

## Configuration

### Required Variables

| Variable | Description |
|----------|-------------|
| `kubernetes_context` | Kubernetes context to use |
| `openbao_address` | OpenBao/Vault address |
| `authentik_issuer_url` | Authentik OIDC issuer URL |
| `authentik_jwks_url` | Authentik JWKS URL |
| `nats_auth_issuer_seed` | NATS auth issuer NKey seed |
| `nats_auth_signing_keys` | JSON map of issuer ID to signing key seed |

### Generating NATS Keys

Generate the required NKeys using the `nk` tool:

```bash
# Generate issuer key (account type)
nk -gen account
# Output: SAAA... (seed - keep secret)
# Output: AAAA... (public key)

# Generate signing key (user type) for each issuer
nk -gen user
# Output: SUAA... (seed - keep secret)
# Output: UAAA... (public key)
```

Set the seeds in your tfvars file:

```hcl
nats_auth_issuer_seed  = "SAAA..."
nats_auth_signing_keys = "{\"typewriter\": \"SUAA...\"}"
```

## Usage

### Using Task

```bash
# Initialize terraform
task init

# Plan changes
task plan

# Apply changes
task apply

# Destroy resources
task destroy
```

### Using Terraform Directly

```bash
# Initialize
terraform init

# Plan (local environment)
terraform plan -var-file=terraform.tfvars.local

# Apply (local environment)
terraform apply -var-file=terraform.tfvars.local

# Destroy
terraform destroy -var-file=terraform.tfvars.local
```

### From Component Root

```bash
# Deploy via the backend Taskfile
cd ..
task deploy  # Uses terraform:apply

# Or for full dev cycle
task dev  # build, push, deploy
```

## Secrets Structure in OpenBao

The terraform creates secrets at `secret/nats/auth-callout`:

```json
{
  "issuer_seed": "SAAA...",
  "signing_keys": "{\"typewriter\": \"SUAA...\"}"
}
```

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│    OpenBao      │────>│  ExternalSecret  │────>│ K8s Secret      │
│ secret/nats/... │     │                  │     │ auth-callout-   │
└─────────────────┘     └──────────────────┘     │ secrets         │
                                                 └────────┬────────┘
                                                          │
                                                          v
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│ Terraform       │────>│  ConfigMap       │────>│ wasi:config/    │
│ (issuer config) │     │  auth-callout-   │     │ store           │
│                 │     │  config          │     │ (component)     │
└─────────────────┘     └──────────────────┘     └─────────────────┘
```

## Troubleshooting

### ExternalSecret not syncing

Check the ExternalSecret status:

```bash
kubectl get externalsecret -n wasmcloud auth-callout-secrets -o yaml
```

Verify the ClusterSecretStore exists:

```bash
kubectl get clustersecretstore openbao-backend
```

### Config values not reaching component

Verify the ConfigMap:

```bash
kubectl get configmap -n wasmcloud auth-callout-config -o yaml
```

Check the WorkloadDeployment status:

```bash
kubectl get workloaddeployment -n wasmcloud auth-callout -o yaml
```
