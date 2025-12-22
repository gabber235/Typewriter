output "workload_name" {
  description = "Name of the deployed WorkloadDeployment"
  value       = "organizations"
}

output "namespace" {
  description = "Namespace where organizations is deployed"
  value       = local.wasmcloud_namespace
}
