
# EKS ArgoCD & CodePipline

This project creates a AWS EKS infrastructure in Terraform, and runs a AWS CodePipline to update the application. 
The key components of the project are:
- AWS VPC
- AWS EKS
- AWS CodePipline
- AWS CodeCommit repositories
- ArgoCD


# Installation

The project is built of two parts:
- Infrastructure - the project uses Terraform to create the infrastructure. The two main resources are AWS EKS and a VPC. The EKS is for the web app and for an ArgoCD server that controls the app deployment.
- Pipeline - the Pipeline uses 2 repositories (one for source code and the second for the Helm chart the ArgoCD uses) and a registry (DockerHub - for the built image). The Pipeline gets triggered on every push to the source repo. The Pipeline builds the new image, tags it with the build number, and pushes it to DockerHub. Next, it updates the Helm repo with the new image tag. ArgoCD, which also on the EKS, synchronizes with the repo and updates the app to the new image.
## Infrastrucrute and setup
The project is built from three directories.



### 1. weather_helm
Create an AWS CodeCommit a repository and upload the directory to there. save URL and credentials.
### 2. EKS_terraform
#### A. Setup Terraform environment and create resources.

Configure the "terraform apply" command with the URL and credentials from the weather_helm repo, and with the host (for ArgoCD) you are using in route53. If wanted the variables can be added into the variables.tf file directly.
```bash
  cd EKS_terraform
  terraform init
  terraform apply -var="argo_repo_url=<Helm repo url>" -var="argo_repo_username=<username>" -var="argo_repo_password=<password> -var="host_address=<host>"

```
#### B. Attach LoadBalancers to route53.
In AWS in the loadbalancers section attach the two loadbalancers to route53. The ArgoCD loadbalancer should be attached to the host that was defined. The app loadbalancers can be attached to any host.

#### C. Option - not use route53.
The app is reachable with the loadbalancers DNS.
To connect to ArgoCD:
Get the password (it is also printed in the end of the output of the terraform apply)
```bash
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
  kubectl port-forward svc/argo-cd-argocd-server -n argocd 8080:443
```
In browser: "localhost:8080"
username: "admin"
password: <output from command>

*** Even when the terraform apply command is finished it takes a few more minutes for everything to work.

### 3. weather_app 
Create in AWS CodeCommit a repository and upload the directory to there.
Create a CodePipline and CodeBuild that will run on every push and use the buildspec.yml file that is in the directory.












## Usage
When a change is made to the application source files, in the weather-app directory, and pushed to the AWS CodeCommit repository a pipeline is triggered.
The pipeline will test the files in the repository. Then build an image and push it to DockerHub. After that, it will update the app's HELM chart, which will be synchronized by ArgoCD and update the EKS pods.



