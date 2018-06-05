#!/usr/bin/env bash
#set -e

echo "Current KUBECONFIG: "  $KUBECONFIG
Echo "Make sure KUBECONFIG env varibale is pointing to local minikube"

read -p "Minikube K8s on local machine will be deleted and installed again, are you sure? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
  	echo --------------------------deleting minikube--------------------------
    minikube delete

    echo --------------------------installing minikube with pre-requisites--------------------------
    minikube start \
    --extra-config=controller-manager.cluster-signing-cert-file="/var/lib/localkube/certs/ca.crt" \
    --extra-config=controller-manager.cluster-signing-key-file="/var/lib/localkube/certs/ca.key" \
    --extra-config=apiserver.admission-control="NamespaceLifecycle,LimitRanger,ServiceAccount,PersistentVolumeLabel,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota" \
    --kubernetes-version=v1.10.0

    echo --------------------------Downloading IStio source from gihub--------------------------
    #curl -L https://git.io/getLatestIstio | sh -
    export PATH=$PWD/bin:$PATH
    cd istio-0.8.0

    echo --------------------------installing istio with tls--------------------------
    kubectl apply -f install/kubernetes/istio-demo-auth.yaml

    kubectl get pods -n istio-system

    echo --------------------------sleeping For 60 seconds during istio get initialized--------------------------
    sleep 60
    kubectl get pods -n istio-system
	echo --------------------------enabling 'default' namespace For istio automatic sidecar injection--------------------------
    kubectl label namespace default istio-injection=enabled --overwrite

else
  echo Goodbye...!
fi
