variable "kubernetes_context" {
  description = "Kubernetes context to use"
  type        = string
}

variable "openbao_address" {
  description = "OpenBao/Vault address"
  type        = string
}

variable "authentik_issuer_url" {
  description = "Authentik OIDC issuer URL for typewriter"
  type        = string
}

variable "authentik_jwks_url" {
  description = "Authentik JWKS URL for typewriter"
  type        = string
}
