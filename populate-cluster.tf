# Deliberately kept insecure in that it only uses HTTP Basic Auth. 
# We should fix this eventually, but good enough for testing for now.
provider "kubectl" {
  apply_retry_count = 3
  load_config_file = "false"

  host = "https://${google_container_cluster.primary.endpoint}"
  insecure = true
  username = "admin"
  password = var.password
}

provider "helm" {
  kubernetes {
    host = "https://${google_container_cluster.primary.endpoint}"
    insecure = true
    username = "admin"
    password = var.password
  }
}

data "kubectl_file_documents" "manifests" {
    content = file(var.bookinfo_apps_path)
}

data "helm_repository" "bitnami" {
  name = "bitnami"
  url  = "https://charts.bitnami.com/bitnami"
}

resource "helm_release" "rabbit" {
  name = "rabbitmq"
  repository = data.helm_repository.bitnami.metadata[0].name
  chart = "bitnami/rabbitmq"
  set {
    name = "rabbitmq.password"
    value = "qxevtnump90"
  }
}

resource "kubectl_manifest" "bookinfo" {
    for_each = toset(data.kubectl_file_documents.manifests.documents)
    yaml_body = each.value
}