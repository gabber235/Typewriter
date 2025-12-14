output "workload_name" {
  description = "Name of the deployed WorkloadDeployment"
  value       = "auth-typewriter-permissions"
}

output "namespace" {
  description = "Namespace where auth-typewriter-permissions is deployed"
  value       = local.wasmcloud_namespace
}
