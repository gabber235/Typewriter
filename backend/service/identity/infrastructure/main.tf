provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = var.kubernetes_context
}

provider "kubectl" {
  config_path    = "~/.kube/config"
  config_context = var.kubernetes_context
}

locals {
  wasmcloud_namespace = "wasmcloud"
}

resource "kubectl_manifest" "service_identity_secrets_external_secret" {
  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "service-identity-secrets"
      namespace = local.wasmcloud_namespace
    }
    spec = {
      refreshInterval = "8760h"
      secretStoreRef = {
        name = "openbao-backend"
        kind = "ClusterSecretStore"
      }
      target = {
        name           = "service-identity-secrets"
        creationPolicy = "Owner"
        template = {
          engineVersion = "v2"
          data = {
            "AUTHENTIK_URL"   = "{{ .url }}"
            "AUTHENTIK_TOKEN" = "{{ .token }}"
          }
        }
      }
      data = [
        {
          secretKey = "url"
          remoteRef = {
            key      = "authentik/api"
            property = "url"
          }
        },
        {
          secretKey = "token"
          remoteRef = {
            key      = "authentik/api"
            property = "token"
          }
        }
      ]
    }
  })
}

resource "kubectl_manifest" "service_identity_nats_secrets_external_secret" {
  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "service-identity-nats-secrets"
      namespace = local.wasmcloud_namespace
    }
    spec = {
      refreshInterval = "8760h"
      secretStoreRef = {
        name = "openbao-nats-backend"
        kind = "ClusterSecretStore"
      }
      target = {
        name           = "service-identity-nats-secrets"
        creationPolicy = "Owner"
      }
      data = [
        {
          secretKey = "NATS_SENTINEL_CREDS"
          remoteRef = {
            key      = "vault-plugin-secrets-nats/creds/operator/operator/account/WASMCLOUD/user/sentinel"
            property = "creds"
          }
        }
      ]
    }
  })
}

resource "kubectl_manifest" "service_identity_workload" {
  yaml_body = file("${path.module}/../manifests/workloaddeployment.yaml")

  depends_on = [
    kubectl_manifest.service_identity_secrets_external_secret,
    kubectl_manifest.service_identity_nats_secrets_external_secret
  ]
}
