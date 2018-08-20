 

Prometheus is a pull-based metrics system. Where an application exposes a metrics endpoint which Prometheus periodically accesses and gathers metrics. 

Having applications deployed with ISTIO protected behind mTLS has an implication:

Applications deployed with istio-mtls can ONLY be accessed by applications deployed with istio-mtls. There is no way to bypass this security. This means Prometheusthe would not be able to access the application. 

Solution:
Follow the tommyknockers guide /x/qaMNFg
Expose metrics endpoint via a nginx side-car container which exposes metrics endpoint and does not expects mTLS.
Glossary:
side-car container:

A utility application deployed side by side in the same pod and is responsible for certain tasks on behalf of the main application.


Documentation: How to expose metrics endpoints
Step 1: Update the deployment manifest of the pod to include the following:
```yaml
spec:
  volumes:
  - name: cache-volume
    emptyDir: {}
  - name: config-volume
    configMap:
      name: argonauts-configs
```

.....
.....
 
- name: metrics-proxy-container
        imagePullPolicy: IfNotPresent #Always #
        image: repository.hybris.com:5007/argonauts/nginx-side-car:latest
        resources:
          limits:
            cpu: 100m
            memory: 15Mi
          requests:
            cpu: 50m
            memory: 10Mi
#        ports:
#        - containerPort: 9090 # Must not expose this port, as any exposed port would be monitored by istio, else ignored.
        volumeMounts:
        - mountPath: /etc/nginx/nginx.conf
          name: config-volume
          subPath: nginx.conf
          readOnly: true
(lightbulb) Docker file location: https://stash.hybris.com/projects/ARGO/repos/kubernetes-stack/browse/metrics/docker/nginx-side-car



Step 2: Update the service definition

```yaml
apiVersion: v1
kind: Service
metadata:
  name: identity-service
  labels:
    run: identity-app
    app: argo-monitoring-service # Label that is mapped to prometheus service monitor - kubernetes-stack repo
  annotations:
    #auth.istio.io/9090: NONE # This setting has no affect at all. todo test some time later.
    getambassador.io/config: |
      ---
      apiVersion: ambassador/v0
      kind:  Mapping
      name:  identity_mapping
      prefix: /identity-service/
      service: http://identity-service.tools:80
      tls: upstream
  namespace: tools
spec:
  selector:
    run: identity-app
  type: ClusterIP
  ports:
  - protocol: TCP
    port: 80 # port of service, it will be exposed to other pods inside the cluster
    targetPort: 8080 # port of container app running e.g. spring boot on 8080
    name: http
  - protocol: TCP
    port: 9090 # port of service, it will be exposed to other pods inside the cluster
    targetPort: 9090 # port of container app running e.g. spring boot on 8080
    name: prometheus
```

Step 3: Update the default nginx conf and override it with a k8s config-map resource (if needed)
```
user  nginx;
worker_processes  1;

#error_log  /cache/error.log warn;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;
#pid        /cache/nginx.pid;


events {
  worker_connections  1024;
}


http {
  include  /etc/nginx/mime.types;
  default_type  application/octet-stream;

  log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
  '$status $body_bytes_sent "$http_referer" '
  '"$http_user_agent" "$http_x_forwarded_for"';

  #access_log  /cache/access.log  main;

  sendfile        on;
  #tcp_nopush     on;

  keepalive_timeout  65;

  #gzip  on;
server {
  listen       9090;
  server_name  localhost;
    location / {
            proxy_bind $server_addr;
        proxy_pass http://localhost:8080/prometheus;
    }

    location /prometheus {
            proxy_bind $server_addr;
        proxy_pass http://localhost:8080/prometheus;
    }
    location /readiness {
            proxy_bind $server_addr;
        proxy_pass http://localhost:8080/ready;
    }
    location /liveness {
            proxy_bind $server_addr;
        proxy_pass http://localhost:8080/alive;
    }
}
}
```

Step 4: In case the override of nginx.conf is required (change namespace)
```bash
kubectl -n tools create configmap argonauts-configs --from-file=nginx.conf --dry-run -o yaml | kubectl apply -f -
```

Step 5: Verify if service monitor is correctly configured
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: argo-monitor
  namespace: monitoring
  labels:
    k8s-app: http
    prometheus: kube-prometheus #important for prometheus operator, label is a must
spec:
  jobLabel: k8s-app
  selector:
    matchLabels:
      app: argo-monitoring-service #each service that want to be monitored by prometheus must have it
  namespaceSelector:
    matchNames:
    - tools
  endpoints:
  - honorLabels: true
    interval: 30s
    port: prometheus
    path: /prometheus
    scheme: http
    tlsConfig:
      insecureSkipVerify: true
```



Step 6: verify if metrics are being exposed
```bash
05:56 $ kn port-forward svc/identity-service 9090:9090
Forwarding from 127.0.0.1:9090 -> 9090
```
.....
http://localhost:9090/prometheus

```
//# HELP com_hybris_yprofile_identity_web_rest_HealthEndpoint_isAlive Generated from Dropwizard metric import (metric=com.hybris.yprofile.identity.web.rest.HealthEndpoint.isAlive, type=com.codahale.metrics.Timer)
//# TYPE com_hybris_yprofile_identity_web_rest_HealthEndpoint_isAlive summary
com_hybris_yprofile_identity_web_rest_HealthEndpoint_isAlive{quantile="0.5",} 1.353475E-4
com_hybris_yprofile_identity_web_rest_HealthEndpoint_isAlive{quantile="0.75",} 1.6810525000000002E-4
com_hybris_yprofile_identity_web_rest_HealthEndpoint_isAlive{quantile="0.95",} 2.9743215000000003E-4
com_hybris_yprofile_identity_web_rest_HealthEndpoint_isAlive{quantile="0.98",} 3.344422799999999E-4
com_hybris_yprofile_identity_web_rest_HealthEndpoint_isAlive{quantile="0.99",} 4.1210555000000096E-4
com_hybris_yprofile_identity_web_rest_HealthEndpoint_isAlive{quantile="0.999",} 0.056941702324000205
com_hybris_yprofile_identity_web_rest_HealthEndpoint_isAlive_count 50598.0 
Step 7: verify if Prometheus can access the metrics
```

```bash
kubectl -n monitoring port-forward svc/kube-prometheus 9090:9090
Forwarding from 127.0.0.1:9090 -> 9090
Note: this command will only work with a kubectl client of 1.10.0 or greater
```

[SAP] SAP Hybris Profile > Istio-mTLS: Exposing metrics endpoint to Prometheus > image2018-8-3_6-8-10.png



 