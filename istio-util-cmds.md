## delete evicted pods
 ki get pods | grep Evicted | awk '{print $1}' | xargs kubectl -n istio-system delete pod
 ki get secret | awk '{print $1}' | xargs kubectl -n istio-system delete secret
## minikube start with version:
    minikube start --kubernetes-version v1.10.1
    
     minikube start --memory=8192 --cpus=2 --kubernetes-version=v1.10.1 \
    --extra-config=controller-manager.cluster-signing-cert-file="/var/lib/localkube/certs/ca.crt" \
    --extra-config=controller-manager.cluster-signing-key-file="/var/lib/localkube/certs/ca.key"
    
    
    minikube start --memory=8192 --cpus=4 --kubernetes-version=v1.11.2 \
    --extra-config=controller-manager.cluster-signing-cert-file="/var/lib/localkube/certs/ca.crt" \
    --extra-config=controller-manager.cluster-signing-key-file="/var/lib/localkube/certs/ca.key"  