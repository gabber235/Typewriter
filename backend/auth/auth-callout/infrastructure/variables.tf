variable "kubernetes_context" {
  description = "Kubernetes context to use"
  type        = string
}

variable "openbao_address" {
  description = "OpenBao/Vault address"
  type        = string
}

variable "panel_issuer_url" {
  description = "Authentik OIDC issuer URL for typewriter-panel"
  type        = string
}

variable "panel_jwks_url" {
  description = "Authentik JWKS URL for typewriter-panel"
  type        = string
}

variable "services_issuer_url" {
  description = "Authentik OIDC issuer URL for typewriter-services"
  type        = string
}

variable "services_jwks_url" {
  description = "Authentik JWKS URL for typewriter-services"
  type        = string
}
