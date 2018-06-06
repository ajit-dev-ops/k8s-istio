# working ingress example with mTLS enabled services

Istio release cycle explained
https://github.com/istio/istio/blob/master/release/README.md

### As of 06.June.2018 - playing with istio 0.8.0 + 
<span style="color:red"> Ingress only works with daily release</span>

https://gcsweb.istio.io/gcs/istio-prerelease/daily-build/release-0.8-20180531-09-15/

Reference Issue:
https://github.com/istio/istio/issues/5686

###Links to documentation

https://istio.io/docs/tasks/traffic-management/ingress -> 
https://istio.io/docs/reference/config/istio.networking.v1alpha3#HTTPRoute
https://preliminary.istio.io/docs/tasks/traffic-management/ingress/ 


## Goals of this exercise: 

1. Deploy istio with mTLS enabled.
[$ kubectl apply -f install/kubernetes/istio-demo-auth.yaml](https://istio.io/docs/setup/kubernetes/quick-start/#minikube)

2. Deploy a web app  (simple nginx instance) - istio-ingress-example.yml

3. Expose app over istio ingress gateway.

4. Routing must be HOST header based and not sub-path based

##How to steps:

1. Create a secret with Certificates for istio gateway

    Generating certificates:
    
    ```bash
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=*.ajit.de"
    
    kubectl create -n istio-system secret tls istio-ingressgateway-certs --key /tmp/tls.key --cert /tmp/tls.crt 
    ```
2. Restart istio gateway container & Wait.......  60-120 seconds to istio get initialized...  (???)

3. Deploy istio-ingress-example.yml in a namespace with side-car auto injection enabled
  
      ```bash
      
        kubectl label namespace default istio-injection=enabled
        kubectl apply -f istio-ingress-example.yml
      
      ```
      
4. On minikube prompt run:
    ```bash
    minikube ip
    
    kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}'
    
    ```
    
    for e.g. then run (using postman)
    ```bash
    curl "https://192.168.99.100:31390/" -H 'Host: my-tls.ajit.de'
    ```

5. Note: with curl the above request results in ssl protocol error therefore use paw or postman. to fix ?

