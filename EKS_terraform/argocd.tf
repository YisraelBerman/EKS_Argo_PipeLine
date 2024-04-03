resource "kubernetes_namespace" "argocd" {
  depends_on = [module.eks, null_resource.kubeconfig]

  metadata {
    name = "argocd"
  }
}

resource "kubernetes_namespace" "nginx_ingress" {
  depends_on = [module.eks, null_resource.kubeconfig]

  metadata {
    name = "nginx-ingress"
  }
}

resource "helm_release" "argo_cd" {
  depends_on = [module.eks, kubernetes_namespace.argocd]
  name       = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "4.8.3" 

  namespace = "argocd"

  set {
    name  = "server.service.type"
    value = "NodePort"
  }

  set {
    name  = "server.ingress.enabled"
    value = "true"
  }

  set {
    name  = "server.ingress.hosts[0]"
    value = var.host_address
  }

  set {
    name  = "server.ingress.annotations.kubernetes\\.io/ingress\\.class"
    value = "nginx" 
  }

  set {
    name  = "server.ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/force-ssl-redirect"
    value = "false"
  }

  set {
    name  = "server.ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/ssl-redirect"
    value = "false"
  }

  set {
    name  = "server.extraArgs[0]"
    value = "--insecure"
  }
}

resource "helm_release" "nginx_ingress" {
  depends_on = [module.eks, null_resource.kubeconfig, kubernetes_namespace.nginx_ingress]

  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.8.3"
  namespace = "nginx-ingress"

}




resource "null_resource" "update_argocd" {
  depends_on = [
    module.eks, 
    null_resource.deploy_cluster_autoscaler, 
    kubernetes_namespace.argocd, 
    kubernetes_namespace.nginx_ingress
    ]

  triggers = {
    always = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = <<-EOT
      until kubectl get nodes; do sleep 5; done
      yes | ./configure_argocd.sh "${var.argo_repo_url}" "${var.argo_repo_username}" "${var.argo_repo_password}" "${var.host_address}"

    EOT
  }
}


