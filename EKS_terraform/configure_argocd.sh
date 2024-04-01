#!/bin/bash
REPO_URL=$1
REPO_USERNAME=$2
REPO_PASSWORD=$3
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argo-cd-argocd-server -n argocd --timeout=600s

attempt=0
max_attempts=10
port_forwarded=false

while [ $attempt -lt $max_attempts ]; do
    kubectl port-forward svc/argo-cd-argocd-server -n argocd 8080:443 &
    PF_PID=$!
    sleep 5

    if nc -zv localhost 8080; then
        echo "Port forwarding established."
        port_forwarded=true
        break
    else
        echo "Failed to establish port forwarding, retrying..."
        kill $PF_PID
        attempt=$((attempt+1))
        sleep 20
    fi
done

if [ "$port_forwarded" = false ]; then
    echo "Failed to establish port forwarding after $max_attempts attempts."
    exit 1
fi


ARGOCD_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode)

argocd login localhost:8080 --username admin --password "$ARGOCD_PASS" --insecure

argocd repo add $REPO_URL --username $REPO_USERNAME --password $REPO_PASSWORD

kubectl apply -f argocd-app.yaml

kill $PF_PID

echo
echo "-----------------------------------"
echo "ArgoCD password: $ARGOCD_PASS"
echo "-----------------------------------"
echo
