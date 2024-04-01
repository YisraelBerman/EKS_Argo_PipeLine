

resource "null_resource" "local_command" {
  depends_on = [module.eks]
  

  provisioner "local-exec" {
    command = <<-EOT
      aws eks --region ${var.region} update-kubeconfig \
      --name eks-${var.clustername}-project
    EOT
  }
}



resource "null_resource" "cluster_ready" {
  depends_on = [module.eks]

  provisioner "local-exec" {
    command = "until kubectl get nodes; do sleep 5; done"
  }
}


resource "null_resource" "install_argocd" {
  depends_on = [null_resource.cluster_ready]

  provisioner "local-exec" {
    command = <<-EOT
      helm repo add argo https://argoproj.github.io/argo-helm
      helm repo update
      helm install argo-cd argo/argo-cd -n argocd --create-namespace -f argovalues.yaml

    EOT
  }
}



resource "null_resource" "configure_argocd" {
    depends_on = [null_resource.install_argocd]
 
  provisioner "local-exec" {
    command = <<-EOT
      
      yes | ./configure_argocd.sh "${var.argo_repo_url}" "${var.argo_repo_username}" "${var.argo_repo_password}"
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}





resource "null_resource" "install_nginx_ingress" {
  depends_on = [module.eks, null_resource.cluster_ready, null_resource.configure_argocd]
  
  provisioner "local-exec" {
    command = <<-EOT
      kubectl create namespace ingress-nginx --dry-run=client -o yaml | kubectl apply -f - 
      kubectl apply -f ingress_nginx.yaml
      
    EOT
      }

}


resource "null_resource" "configure_az_lb" {
    depends_on = [null_resource.install_argocd, null_resource.install_nginx_ingress]

  provisioner "local-exec" {
    command = <<-EOT
      
      ./LB_AZ.sh
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}

resource "null_resource" "argocd_ingress" {
  depends_on = [null_resource.install_argocd, null_resource.install_nginx_ingress]

  provisioner "local-exec" {
    command = <<-EOT
      sleep 60
      sed -i 's/HOST_PLACEHOLDER/${var.host_address}/g' ./argocd_ingress.yaml
      kubectl apply -f ./argocd_ingress.yaml
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
  
}
