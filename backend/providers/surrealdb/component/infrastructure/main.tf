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

resource "kubectl_manifest" "surrealdb_component_workload" {
  yaml_body = file("${path.module}/../manifests/workloaddeployment.yaml")
}
