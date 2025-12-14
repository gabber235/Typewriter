output "config_map_name" {
  description = "Name of the ConfigMap containing auth-callout configuration"
  value       = kubernetes_config_map.auth_callout_config.metadata[0].name
}

output "secrets_name" {
  description = "Name of the Kubernetes Secret containing auth-callout secrets"
  value       = "auth-callout-secrets"
}

output "workload_name" {
  description = "Name of the deployed WorkloadDeployment"
  value       = "auth-callout"
}

output "namespace" {
  description = "Namespace where auth-callout is deployed"
  value       = local.wasmcloud_namespace
}
