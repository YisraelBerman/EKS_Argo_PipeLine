#!/bin/bash
REPO_URL=$1
REPO_USERNAME=$2
REPO_PASSWORD=$3
HOST_ADDRESS=$4



INGRESS_SERVICE_NAME="nginx-ingress-ingress-nginx-controller"
INGRESS_NAMESPACE="nginx-ingress"

echo "waiting for service to start"
sleep 60

AZS=$(aws ec2 describe-availability-zones --query "AvailabilityZones[?State=='available'].ZoneName" --output text)

INGRESS_LB_DNS_NAME=$(kubectl get svc "$INGRESS_SERVICE_NAME" -n "$INGRESS_NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    
INGRESS_LB_NAME=$(aws elb describe-load-balancers --query 'LoadBalancerDescriptions[?DNSName==`'"$INGRESS_LB_DNS_NAME"'`].LoadBalancerName' --output text)


for AZ in $AZS; do
    SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=availability-zone,Values=$AZ" "Name=tag:Name,Values=vpc*" --query "Subnets[0].SubnetId" --output text)
    
    if [ -z "$SUBNET_ID" ] || [ "$SUBNET_ID" == "None" ]; then
        echo "No matching subnets found for Availability Zone $AZ."
        continue
    fi


    aws elb attach-load-balancer-to-subnets --load-balancer-name "$INGRESS_LB_NAME" --subnets "$SUBNET_ID"
done


kubectl port-forward svc/argo-cd-argocd-server -n argocd 8080:443 &
PF_PID=$!
sleep 5

ARGOCD_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode)

argocd login localhost:8080 --username admin --password "$ARGOCD_PASS" --insecure

argocd repo add $REPO_URL --username $REPO_USERNAME --password $REPO_PASSWORD

kubectl apply -f argocd-app.yaml

kill $PF_PID

echo "waiting for service to start"
sleep 120

SERVICE_NAME="app-service"
NAMESPACE="default"


LB_DNS_NAME=$(kubectl get svc "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
 
LB_NAME=$(aws elb describe-load-balancers --query 'LoadBalancerDescriptions[?DNSName==`'"$LB_DNS_NAME"'`].LoadBalancerName' --output text)



for AZ in $AZS; do
    SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=availability-zone,Values=$AZ" "Name=tag:Name,Values=vpc*" --query "Subnets[0].SubnetId" --output text)
    
    if [ -z "$SUBNET_ID" ] || [ "$SUBNET_ID" == "None" ]; then
        echo "No matching subnets found for Availability Zone $AZ."
        continue
    fi

    aws elb attach-load-balancer-to-subnets --load-balancer-name "$LB_NAME" --subnets "$SUBNET_ID"
done

echo
echo
echo "-----------------------------------"
echo
echo "App DNS: $LB_DNS_NAME"
echo "ArgoCD DNS: $INGRESS_LB_DNS_NAME"
echo "ArgoCD password: $ARGOCD_PASS"
echo
echo "-----------------------------------"
echo
echo
