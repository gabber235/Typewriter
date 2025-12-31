provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = var.kubernetes_context
}

provider "kubectl" {
  config_path    = "~/.kube/config"
  config_context = var.kubernetes_context
}

provider "vault" {
  address = var.openbao_address
}

locals {
  wasmcloud_namespace = "wasmcloud"
}

data "vault_generic_secret" "nats_typewriter_account_public_key" {
  path = "vault-plugin-secrets-nats/nkey/operator/operator/account/TYPEWRITER"
}

data "vault_generic_secret" "auth_callout_signing_key" {
  path = "vault-plugin-secrets-nats/nkey/operator/operator/account/TYPEWRITER/signing/auth-callout"
}

resource "kubectl_manifest" "auth_callout_secrets_external_secret" {
  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "auth-callout-secrets"
      namespace = local.wasmcloud_namespace
    }
    spec = {
      refreshInterval = "30m"
      secretStoreRef = {
        name = "openbao-nats-backend"
        kind = "ClusterSecretStore"
      }
      target = {
        name           = "auth-callout-secrets"
        creationPolicy = "Owner"
        template = {
          engineVersion = "v2"
          data = {
            "NATS_ISSUER_SEED"  = "{{ .accountSeed }}"
            "NATS_SIGNING_KEYS" = "{\"typewriter-panel\": \"{{ .signingKeySeed }}\", \"typewriter-services\": \"{{ .signingKeySeed }}\"}"
          }
        }
      }
      data = [
        {
          secretKey = "accountSeed"
          remoteRef = {
            key      = "vault-plugin-secrets-nats/nkey/operator/operator/account/WASMCLOUD/signing/default"
            property = "seed"
          }
        },
        {
          secretKey = "signingKeySeed"
          remoteRef = {
            key      = "vault-plugin-secrets-nats/nkey/operator/operator/account/TYPEWRITER/signing/auth-callout"
            property = "seed"
          }
        }
      ]
    }
  })

  depends_on = [data.vault_generic_secret.auth_callout_signing_key]
}

resource "kubernetes_config_map" "auth_callout_config" {
  metadata {
    name      = "auth-callout-config"
    namespace = local.wasmcloud_namespace
  }

  data = {
    ISSUERS = jsonencode([
      {
        id               = "typewriter-panel"
        issuer_url       = var.panel_issuer_url
        jwks_url         = var.panel_jwks_url
        nats_account_key = data.vault_generic_secret.nats_typewriter_account_public_key.data["publicKey"]
      },
      {
        id               = "typewriter-services"
        issuer_url       = var.services_issuer_url
        jwks_url         = var.services_jwks_url
        nats_account_key = data.vault_generic_secret.nats_typewriter_account_public_key.data["publicKey"]
      }
    ])
  }
}

resource "kubectl_manifest" "auth_callout_workload" {
  yaml_body = file("${path.module}/../manifests/workloaddeployment.yaml")

  depends_on = [
    kubectl_manifest.auth_callout_secrets_external_secret,
    kubernetes_config_map.auth_callout_config
  ]
}
