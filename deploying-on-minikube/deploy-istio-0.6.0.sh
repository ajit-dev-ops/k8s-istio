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
    --extra-config=controller-manager.ClusterSigningCertFile="/var/lib/localkube/certs/ca.crt" \
    --extra-config=controller-manager.ClusterSigningKeyFile="/var/lib/localkube/certs/ca.key" \
    --extra-config=apiserver.Admission.PluginNames=NamespaceLifecycle,LimitRanger,ServiceAccount,PersistentVolumeLabel,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota \
    --kubernetes-version=v1.9.0

    echo --------------------------Downloading IStio source from gihub--------------------------
    wget https://github.com/istio/istio/releases/download/0.6.0/istio-0.6.0-linux.tar.gz -O - | tar -xz

    export PATH=$PWD/bin:$PATH
    cd istio-0.6.0

    echo --------------------------installing istio with tls--------------------------
    kubectl apply -f install/kubernetes/istio-auth.yaml

    echo --------------------------sleeping For 2 minutes during istio get initialized--------------------------
    sleep 120
    kubectl get pods -n istio-system

	echo --------------------------Enabling automatic sidecar--------------------------
     ./install/kubernetes/webhook-create-signed-cert.sh \
      --service istio-sidecar-injector \
      --namespace istio-system \
      --secret sidecar-injector-certs
    kubectl apply -f install/kubernetes/istio-sidecar-injector-configmap-release.yaml
    cat install/kubernetes/istio-sidecar-injector.yaml | \
         ./install/kubernetes/webhook-patch-ca-bundle.sh > \
         install/kubernetes/istio-sidecar-injector-with-ca-bundle.yaml
    kubectl apply -f install/kubernetes/istio-sidecar-injector-with-ca-bundle.yaml

    echo waiting..20 secs.................................................!!!!!!
    sleep 20
    kubectl -n istio-system get deployment -listio=sidecar-injector

	echo --------------------------enabling 'default' namespace For istio automatic sidecar injection--------------------------
    kubectl label namespace default istio-injection=enabled --overwrite
else
  echo Goodbye...!
fi
