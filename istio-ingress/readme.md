# Working istio ingress gateway example with mTLS enabled services

Istio release cycle explained
https://github.com/istio/istio/blob/master/release/README.md

### As of 06.June.2018 - playing with istio 0.8.0 + 
<span style="color:red"> Ingress only works with following daily release</span>

https://gcsweb.istio.io/gcs/istio-prerelease/daily-build/release-0.8-20180531-09-15/

<hr/>
Reference Issue:
https://github.com/istio/istio/issues/5686

### Links to documentation

https://istio.io/docs/tasks/traffic-management/ingress -> 
https://istio.io/docs/reference/config/istio.networking.v1alpha3#HTTPRoute
https://preliminary.istio.io/docs/tasks/traffic-management/ingress/ 
gateway - https://istio.io/docs/reference/config/istio.networking.v1alpha3/#Server.TLSOptions.TLSmode

## Goals of this exercise: 

1. Deploy istio with mTLS enabled.
[$ kubectl apply -f install/kubernetes/istio-demo-auth.yaml](https://istio.io/docs/setup/kubernetes/quick-start/#minikube)

2. Deploy a web app  (simple nginx instance) - istio-ingress-example.yml

3. Expose app over istio ingress gateway.

4. Routing must be HOST header based and not sub-path based

5. if *.ajit.de works  - 
 its a wild card domain 
 Answer: Yes this is configured in gateway and common to namespace but not to whole k8s cluster. Such wilde card rule canonly be defined one in whole cluster, but it affects only 1 cluster for routing rules.

## How to steps:

1. Create a secret with Certificates for istio gateway

    Generating certificates:
    
    ```bash
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=*.ajit.de"
    
    kubectl create -n istio-system secret tls istio-ingressgateway-certs --key /tmp/tls.key --cert /tmp/tls.crt 
    ```
2. Restart istio gateway container & Wait.......  60-120 seconds to istio get initialized...  

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


## Gateway Caveats

### Wildcard gateway can be defined only once 
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: istio-my-gateway
  namespace: test1
spec:
  selector:
    istio: ingressgateway # use Istio default gateway implementation
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      serverCertificate: /etc/istio/ingressgateway-certs/tls.crt
      privateKey: /etc/istio/ingressgateway-certs/tls.key
    hosts:
    - "*.ajit.de"
```  

So a wildcard gateway as defined above can only be defined once in whole K8s cluster, it is not allowed to be replicated across namespaces.
Therefore if the domain is unique to a namespace its a good idea to define this Gateway once and then any no. of virtual services can be defined in the same namespace.
But if any virtual service is defined in another namespace matching same wildcard domain then istio ingress will not resolve this service.


Issue link
https://github.com/istio/istio/issues/5517

### Specific domain gateway can be defined in each namespace
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: istio-my-gateway
  namespace: test1
spec:
  selector:
    istio: ingressgateway # use Istio default gateway implementation
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      serverCertificate: /etc/istio/ingressgateway-certs/tls.crt
      privateKey: /etc/istio/ingressgateway-certs/tls.key
    hosts:
    - "my-tls-2.ajit.de"
    - "my-tls.ajit.de"
```

A Gatwway such as above can be defined once in a namespace and all the domains can be assembled here. For other namespace more such gatways would be defined.
For each such domain 1 vertual service must be created though. for e.g. 
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: istio-my-vs-2
spec:
  hosts:
  - "my-tls-2.ajit.de"
  gateways:
  - istio-my-gateway
  http:
  - match:
    route:
    - destination:
        port:
          number: 8080
        host: my-nginx-with-istio-2 # name of the K8s service in same ns
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: istio-my-vs-2
spec:
  hosts:
  - "my-tls.ajit.de"
  gateways:
  - istio-my-gateway
  http:
  - match:
    route:
    - destination:
        port:
          number: 8080
        host: my-nginx-with-istio # name of the K8s service in same ns

```


**Summary either use wild card domain gateway once in whole K8s cluster or use one gateway per namespace with list of all domains.**

