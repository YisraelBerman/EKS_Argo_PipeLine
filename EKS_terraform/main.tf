provider "aws" {
  region = var.region
}
provider "helm" {
  kubernetes {
    config_path = "~/.kube/config" 
  }
}
provider "kubernetes" {
  
  config_path = "~/.kube/config" 
  
}


data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  cluster_name = "eks-${var.clustername}-project"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "vpc-${var.clustername}-project"

  cidr = "10.0.0.0/16"
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.4.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }

}

resource "aws_launch_template" "eks_nodes" {
  name_prefix   = "${local.cluster_name}-node-"
  image_id      = "ami-0757bdb3268077f9f"  
  instance_type = "t3.large"  

}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.3"

  cluster_name    = local.cluster_name
  cluster_version = "1.25"

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    one = {
      name = "node-group"

      launch_template = {
        id      = aws_launch_template.eks_nodes.id
        version = aws_launch_template.eks_nodes.latest_version
      }
      min_size     = 2
      max_size     = 4
      desired_size = 2

      tags = {
        "k8s.io/cluster-autoscaler/${local.cluster_name}" = "owned"
        "k8s.io/cluster-autoscaler/enabled"               = "true"
      }
    }

  }
}
resource "null_resource" "kubeconfig" {
  depends_on = [module.eks]
  

  provisioner "local-exec" {
    command = <<-EOT
      aws eks --region ${var.region} update-kubeconfig \
      --name eks-${var.clustername}-project
      until kubectl get nodes; do echo 'Waiting for kubeconfig to be ready...'; done
    EOT
  }
}

#Autoscaller
resource "aws_iam_policy" "cluster_autoscaler" {
  name        = "AmazonEKSClusterAutoscalerPolicy"
  description = "Policy for allowing the cluster autoscaler to modify EC2 instances"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeTags",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "ec2:DescribeLaunchTemplateVersions"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
}
resource "aws_iam_policy_attachment" "cluster_autoscaler" {
  name       = "eks-cluster-autoscaler-attachment"
  roles      = [module.eks.eks_managed_node_groups.one.iam_role_name]
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
}
resource "null_resource" "deploy_cluster_autoscaler" {
  depends_on = [module.eks]

  provisioner "local-exec" {
    command = <<-EOT
      until kubectl get nodes; do sleep 5; done
      kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
      kubectl -n kube-system annotate deployment.apps/cluster-autoscaler cluster-autoscaler.kubernetes.io/safe-to-evict="false"
      kubectl -n kube-system set image deployment.apps/cluster-autoscaler cluster-autoscaler=k8s.gcr.io/autoscaling/cluster-autoscaler:v1.25.0
      kubectl -n kube-system set env deployment/cluster-autoscaler --env="AWS_REGION=${var.region}" --env="CLUSTER_NAME=eks-${var.clustername}-project"
    EOT
  }
}



