#!/usr/bin/env bash
#set -e

echo "Current KUBECONFIG: "  $KUBECONFIG
read -p "Make sure KUBECONFIG env varibale is pointing to local minikube, are you sure? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
 read -p "reinstall services..?" -n 1 -r
 if [[ $REPLY =~ ^[Yy]$ ]]; then
    kubectl delete -f app-with-istio-1.yml
    kubectl delete -f app-with-istio-1.yml
    kubectl delete -f app-no-istio.yml
    kubectl delete -f istio-ingress-gateway.yml
    sleep 5

    echo --------------------------enabling 'commontools' namespace For istio automatic sidecar injection--------------------------
    kubectl create namespace commontools
    kubectl label namespace commontools istio-injection=enabled --overwrite

    echo --------------------------DEMO:  Deploying an istio enabled nginx app to minikube--------------------------
    ./create-secrets-configs.sh
    kubectl apply -f app-with-istio-1.yml
    kubectl apply -f app-with-istio-2.yml
    kubectl apply -f istio-ingress-gateway.yml


    echo --------------------------DEMO:  Deploying an nginx app  - without istio - to minikube--------------------------

    kubectl apply -f app-no-istio.yml

    sleep 3
    echo --------------------------DEMO: Deploying ambassador INGRESS --------------------------
    kubectl create ns api-gateway
    kubectl apply -f .././../ambassador-with-istio/amb-on-minikube.yml

    echo DEMO: Initializing...waiting....30..secs.............................................!!!!!!
    sleep 30
 fi
    echo --------------------------DEMO: VERIFYING MTLS --------------------------
    echo --------------------------DEMO:  Running curl from 1 istio pod to access another pod--------------------------
    kubectl -n commontools exec -it $(kubectl -n commontools  get pods -l run=app-with-istio-1 -o jsonpath='{.items[0].metadata.name}') -c app-with-istio-1 \
     curl app-with-istio-2
    read -p "Press any key to continue..." -n 1 -r

    echo --------------------------DEMO:  Running curl from 1 NON-ISTIO-POD to access another pod - must not work--------------------------
    kubectl -n commontools exec -it  $(kubectl -n commontools get pods -l run=app-no-istio -o jsonpath='{.items[0].metadata.name}') -c app-no-istio \
      curl app-with-istio-1
    read -p "Press any key to continue..." -n 1 -r

    echo --------------------------DEMO: VERIFYING ISTIO INGRESS --------------------------
    minikubeIp=$(minikube ip)
    istioIngressPort=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
    echo ----Run following from postman
    echo "https://$minikubeIp:$istioIngressPort/   -H 'Host: app-1.ajit.de'"
    read -p "Press any key to continue..." -n 1 -r

    echo .
    echo .
    echo .
    echo --------------------------DEMO: VERIFYING ambassador INGRESS --------------------------

    ambIngressPort=$(kubectl -n api-gateway get service ambassador -o jsonpath='{.spec.ports[?(@.name=="ambassador")].nodePort}')
    echo running  "curl http://$minikubeIp:$ambIngressPort/hello/    "
    curl "http://$minikubeIp:$ambIngressPort/hello/   "
    read -p "Press any key to continue..." -n 1 -r

else
  echo Goodbye...!
fi
