output "workload_name" {
  description = "Name of the deployed WorkloadDeployment"
  value       = "surrealdb-test-component"
}

output "namespace" {
  description = "Namespace where surrealdb-test-component is deployed"
  value       = local.wasmcloud_namespace
}
