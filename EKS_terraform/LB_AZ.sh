#!/bin/bash

SERVICE_NAME="app-service"
NAMESPACE="default"

LB_DNS_NAME=$(kubectl get svc "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
if [ -z "$LB_DNS_NAME" ]; then
    echo "Load Balancer DNS name not found for service $SERVICE_NAME in namespace $NAMESPACE."
    exit 1
fi
echo "Found Load Balancer DNS name: $LB_DNS_NAME"

LB_NAME=$(aws elb describe-load-balancers --query 'LoadBalancerDescriptions[?DNSName==`'"$LB_DNS_NAME"'`].LoadBalancerName' --output text)
if [ -z "$LB_NAME" ]; then
    echo "Load Balancer not found in AWS with DNS name $LB_DNS_NAME."
    exit 1
fi
echo "Found Load Balancer Name: $LB_NAME"

AZS=$(aws ec2 describe-availability-zones --query "AvailabilityZones[?State=='available'].ZoneName" --output text)

echo "Enabling all available Availability Zones for the Load Balancer: $LB_NAME"
for AZ in $AZS; do
    SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=availability-zone,Values=$AZ" "Name=tag:Name,Values=vpc*" --query "Subnets[0].SubnetId" --output text)
    
    if [ -z "$SUBNET_ID" ] || [ "$SUBNET_ID" == "None" ]; then
        echo "No matching subnets found for Availability Zone $AZ."
        continue
    fi

    echo "Adding subnet $SUBNET_ID in Availability Zone $AZ to the Load Balancer."

    aws elb attach-load-balancer-to-subnets --load-balancer-name "$LB_NAME" --subnets "$SUBNET_ID"
done

echo "Completed updating the Load Balancer with all available Availability Zones."


#!/bin/bash

SERVICE_NAME="ingress-nginx-controller"
NAMESPACE="ingress-nginx"

LB_DNS_NAME=$(kubectl get svc "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
if [ -z "$LB_DNS_NAME" ]; then
    echo "Load Balancer DNS name not found for service $SERVICE_NAME in namespace $NAMESPACE."
    exit 1
fi
echo "Found Load Balancer DNS name: $LB_DNS_NAME"

LB_NAME=$(aws elb describe-load-balancers --query 'LoadBalancerDescriptions[?DNSName==`'"$LB_DNS_NAME"'`].LoadBalancerName' --output text)
if [ -z "$LB_NAME" ]; then
    echo "Load Balancer not found in AWS with DNS name $LB_DNS_NAME."
    exit 1
fi
echo "Found Load Balancer Name: $LB_NAME"

AZS=$(aws ec2 describe-availability-zones --query "AvailabilityZones[?State=='available'].ZoneName" --output text)

echo "Enabling all available Availability Zones for the Load Balancer: $LB_NAME"
for AZ in $AZS; do
    SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=availability-zone,Values=$AZ" "Name=tag:Name,Values=vpc*" --query "Subnets[0].SubnetId" --output text)
    
    if [ -z "$SUBNET_ID" ] || [ "$SUBNET_ID" == "None" ]; then
        echo "No matching subnets found for Availability Zone $AZ."
        continue
    fi

    echo "Adding subnet $SUBNET_ID in Availability Zone $AZ to the Load Balancer."

    aws elb attach-load-balancer-to-subnets --load-balancer-name "$LB_NAME" --subnets "$SUBNET_ID"
done

echo "Completed updating the Load Balancer with all available Availability Zones."
