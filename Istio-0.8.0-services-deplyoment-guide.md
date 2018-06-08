## Istio 0.8.0 - service deployment guide

### Whats changed since istio 0.6.0
**Deprecated Resources:**

- Ingress
- Egress Rule
:bulb: do not deploy these again.


**Newly introduced Resources:**

- Gateway - Define TLS/domain etc. (Formerly was part of ingress)
- VirtualService - Define routes (Formerly was part of ingress)
- ServiceEntry (Formerly EgressRule)


### Enabling Automatic side-car Injection 
kubectl label namespace argonautsmunich istio-injection=enabled


### Explicitly avoiding side-car injection in a particular deployment: 
```yaml
spec:
 template:
   metadata:
     annotations:
       sidecar.istio.io/inject: “false”
```

### Kubernetes Deployment:
:bulb: Important: Make sure each container explicitly exposes all ports it needs to communicate on, for e.g. via containerPort property in the following snippet.  

```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    run: my-nginx-with-istio-4
  name: my-nginx-with-istio-4
spec:
  replicas: 1
  selector:
    matchLabels:
      run: my-nginx-with-istio-4
  template:
    metadata:
      labels:
        run: my-nginx-with-istio-4
    spec:
     volumes:
      - name: config-volume
        configMap:
          name: ing-conf
     containers:
      - image: ajitchahal/nginx-2
        imagePullPolicy: Always
        name: my-nginx-with-istio-4
        ports:
        - containerPort: 80
          name: http
        volumeMounts:
        - mountPath: /etc/nginx/nginx.conf
          name: config-volume
          subPath: nginx.conf
```

### Kubernetes Service:
:bulb: Important: Port names http|https are reserved words with istio, services must name ports exposed to be able to discovered by istio-discovery.

for e.g. in the following snippet: name: http

```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    run: my-nginx-with-istio-4
    app: v1
  name: my-nginx-with-istio-4
spec:
  ports:
  - port: 8080
    protocol: TCP
    targetPort: http
    name: http
  selector:
    run: my-nginx-with-istio-4
  type: ClusterIP
```

### Ingress configuration 


♣ Prerequisites for an ingress rule to work with an mTLS enabled istio application/service:
 Application and its service in K8s must expose http protocol 
Istio ingress rule would use http port only


:bulb: Important:

The backend service port must be referred by its name and not by its port number.  for e.g.  in the following snippet:  servicePort: http 
Gateway is common to a namespace 
for each hostname a new VirtualService resource needs to created

#### Istio ingress definition

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: istio-my-gateway
  namespace: argonautsmunich
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
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: istio-my-vs
  namespace: argonautsmunich
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
        host: my-nginx-with-istio
```

### Egress configuration 
:bulb: In K8s application the external SSL  urls are used as normal e.g. https://api.ajit.de/httpbin/    

All the services (for e.g. yass proxy api) external to ISTIO must be access enabled, with a ServiceEntry rule. The rules are not attached to an individual service/app but are common to all namespaces.


```yaml
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: google-ext
spec:
  hosts:
  - www.google.com
  ports:
  - number: 443
    name: https
    protocol: HTTPS
---
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: httpbin-ext
spec:
  hosts:
  - httpbin.org
  ports:
  - number: 80
    name: http
    protocol: HTTP
```