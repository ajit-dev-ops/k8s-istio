#!/usr/bin/env bash
#set -e

echo "Current KUBECONFIG: "  $KUBECONFIG
read -p "Make sure KUBECONFIG env varibale is pointing to local minikube, are you sure? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
 read -p "reinstall services..?" -n 1 -r
 if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd ././../istio-ingress/
    kubectl delete -f istio-ingress-example.yml
    kubectl delete -f istio-ingress-example-2.yml
    kubectl delete -f istio-no-side-car.yml
    kubectl delete -f istio-ingress-gateway.yml
    sleep 5

    echo --------------------------enabling 'default' namespace For istio automatic sidecar injection--------------------------
    kubectl label namespace default istio-injection=enabled --overwrite

    echo --------------------------DEMO:  Deploying an istio enabled nginx app to minikube--------------------------
    
    ./create-secrets-configs.sh
    kubectl apply -f istio-ingress-example.yml
    kubectl apply -f istio-ingress-example-2.yml
    kubectl apply -f istio-ingress-gateway.yml


    echo --------------------------DEMO:  Deploying an nginx app  - without istio - to minikube--------------------------
    kubectl create namespace my-ns
    kubectl apply -f istio-no-side-car.yml

    sleep 3
    echo --------------------------DEMO: Deploying ambassador INGRESS --------------------------
    kubectl create ns api-gateway
    kubectl apply -f ././../ambassador-with-istio/amb-on-minikube.yml
    kubectl -n api-gateway scale deploy ambassador --replicas=1

    echo DEMO: Initializing...waiting....30..secs.............................................!!!!!!
    sleep 30
 fi
    echo --------------------------DEMO: VERIFYING MTLS --------------------------
    echo --------------------------DEMO:  Running curl from 1 istio pod to access another pod--------------------------
    kubectl exec -it $(kubectl  get pods -l run=app-with-istio-1 -o jsonpath='{.items[0].metadata.name}') -c app-with-istio-1 \
     curl app-with-istio-2
    read -p "Press any key to continue..." -n 1 -r

    echo --------------------------DEMO:  Running curl from 1 NON-ISTIO-POD to access another pod - must not work--------------------------
    kubectl -n my-ns exec -it  $(kubectl -n my-ns get pods -l run=app-no-istio -o jsonpath='{.items[0].metadata.name}') -c app-no-istio \
      curl app-with-istio-1.default
    read -p "Press any key to continue..." -n 1 -r

    echo --------------------------DEMO: VERIFYING ISTIO INGRESS --------------------------
    minikubeIp=$(minikube ip)
    istioIngressPort=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
    echo ----Run following from posman
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
