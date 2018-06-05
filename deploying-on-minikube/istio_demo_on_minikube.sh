#!/usr/bin/env bash
#set -e

echo "Current KUBECONFIG: "  $KUBECONFIG
read -p "Make sure KUBECONFIG env varibale is pointing to local minikube, are you sure? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
    #kubectl delete deployment my-nginx-with-istio-1
    #kubectl delete deployment my-nginx-with-istio-2
    #kubectl delete deployment my-nginx-no-istio -n my-ns
    #kubectl delete service my-nginx-with-istio-1
    #kubectl delete service my-nginx-with-istio-2
    #kubectl delete service my-nginx-no-istio -n my-ns
    #sleep 20

    echo --------------------------enabling 'default' namespace For istio automatic sidecar injection--------------------------
    kubectl label namespace default istio-injection=enabled --overwrite

    echo --------------------------DEMO:  Deploying an istio enabled nginx app to minikube--------------------------
    kubectl run my-nginx-with-istio-1 --image=ajitchahal/nginx-2
    kubectl run my-nginx-with-istio-2 --image=ajitchahal/nginx-2


    echo --------------------------DEMO:  Deploying an nginx app  - without istio - to minikube--------------------------
    kubectl create namespace my-ns
    kubectl run my-nginx-no-istio -n my-ns --image=ajitchahal/nginx-2
    kubectl expose deploy my-nginx-with-istio-1 --port=80 --target-port=80
    kubectl expose deploy my-nginx-with-istio-2 --port=80 --target-port=80
    kubectl expose deploy my-nginx-no-istio --port=80 --target-port=80 -n my-ns

    echo DEMO: Initializing...waiting....90..secs.............................................!!!!!!
    sleep 90

    echo --------------------------DEMO:  Running curl from 1 istio pod to access another pod--------------------------
    kubectl exec -it $(kubectl  get pods -l run=my-nginx-with-istio-1 -o jsonpath='{.items[0].metadata.name}') -c my-nginx-with-istio-1 \
     curl my-nginx-with-istio-2
    read -p "Press any key to continue..." -n 1 -r

    echo --------------------------DEMO:  Running curl from 1 NON-ISTIO-POD to access another pod - must not work--------------------------
    kubectl -n my-ns exec -it  $(kubectl -n my-ns get pods -l run=my-nginx-no-istio -o jsonpath='{.items[0].metadata.name}') -c my-nginx-no-istio \
      curl my-nginx-with-istio-1.default
    sleep 5

else
  echo Goodbye...!
fi
