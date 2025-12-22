output "workload_name" {
  description = "Name of the deployed WorkloadDeployment"
  value       = "organization-members"
}

output "namespace" {
  description = "Namespace where organization-members is deployed"
  value       = local.wasmcloud_namespace
}
