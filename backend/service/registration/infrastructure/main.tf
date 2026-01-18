provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = var.kubernetes_context
}

provider "kubectl" {
  config_path    = "~/.kube/config"
  config_context = var.kubernetes_context
}

resource "kubectl_manifest" "service_registration" {
  yaml_body = file("${path.module}/../manifests/workloaddeployment.yaml")
}
