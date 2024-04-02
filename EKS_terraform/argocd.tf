resource "null_resource" "install_argocd" {
  depends_on = [module.eks, null_resource.deploy_cluster_autoscaler]

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



