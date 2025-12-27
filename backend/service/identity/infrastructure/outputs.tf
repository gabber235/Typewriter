output "secrets_name" {
  description = "Name of the Kubernetes Secret containing service-identity secrets"
  value       = "service-identity-secrets"
}

output "workload_name" {
  description = "Name of the deployed WorkloadDeployment"
  value       = "service-identity"
}

output "namespace" {
  description = "Namespace where service-identity is deployed"
  value       = local.wasmcloud_namespace
}
