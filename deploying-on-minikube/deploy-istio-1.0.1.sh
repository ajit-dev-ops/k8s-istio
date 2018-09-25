#!/usr/bin/env bash
#set -e

echo "Current KUBECONFIG: "  $KUBECONFIG
Echo "Make sure KUBECONFIG env varibale is pointing to local minikube"

read -p "delete Minikube K8s on local machine and install again? y/n" -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
  	echo --------------------------deleting minikube--------------------------
    minikube delete

    echo --------------------------installing minikube with pre-requisites--------------------------
    minikube --memory 8192 --cpus 2 start \
    --extra-config=controller-manager.cluster-signing-cert-file="/var/lib/localkube/certs/ca.crt" \
    --extra-config=controller-manager.cluster-signing-key-file="/var/lib/localkube/certs/ca.key" \
    --extra-config=apiserver.admission-control="NamespaceLifecycle,LimitRanger,ServiceAccount,PersistentVolumeLabel,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota" \
    --kubernetes-version=v1.10.0
fi
    echo --------------------------Downloading IStio source from gihub--------------------------
    #curl -L https://git.io/getLatestIstio | sh -
    DIRECTORY="istio-1.0.1"
    if [ ! -d "./$DIRECTORY" ]; then
        echo ------------------ Downloading istio --------------
        wget https://github.com/istio/istio/releases/download/1.0.1/istio-1.0.1-linux.tar.gz -O - | tar -xz
    fi
    export PATH=$PWD/bin:$PATH

    echo ---------- Generating helm file --------------
    helm template istio-1.0.1/install/kubernetes/helm/istio --set global.proxy.includeIPRanges="10.44.0.0/16"  --set global.mtls.enabled="true" > istio-minikube.yml

    echo --------------------------installing istio with tls--------------------------
    kubectl apply -f istio-minikube.yml

    kubectl get pods -n istio-system

    echo --------------------------sleeping For 60 seconds during istio get initialized--------------------------
    sleep 60
    kubectl get pods -n istio-system
	echo --------------------------enabling 'default' namespace For istio automatic sidecar injection--------------------------
    kubectl label namespace default istio-injection=enabled --overwrite
    echo ---------------wait till all istio pods are running....
    kubectl get pods -n istio-system -w

    echo Goodbye...!

