 

Having applications deployed with ISTIO protected behind mTLS has an implication:

Applications deployed with istio-mtls can ONLY be accessed by applications deployed with istio-mtls. There is no way to bypass this security.



This means even the k8s api or k8s kubelet cannot access the application. 
Kubelet is responsible for the health check of the applications and if it can not access health check endpoints it delays/avoids scheduling new instances of such an application. 
As we have noticed, this non-accessible applications also affect performance & discovery of istio-pilot.
This also means, liveness and readiness http endpoints are two such important but not reachable endpoints.
Besides K8s, also Prometheus and other monitoring setups would talk to the liveliness and readiness endpoints.
These endpoints are used by k8s to bestow resilience and self-healing features into the applications.
Solution:
We are using an nginx side-car container to mitigate similar issue, where prometheus was not able to reach metrics endpoint. Since the infrastructure is there we would use the same side car to expose liveness and rediness endpoints as well.
Glossary:
Readiness:

An application when deployed new, k8s api would access this endpoint to determine if the new instance is healthy and ready to be inducted to service load balancer. 
A 200ok response is such an indication.
An http error (400s/500s) will result in re-tries after configured time
Until a 200ok response, this new pod would not serve any requests, 
this is helpful with CI deployments for e.g. if this endpoint is making ping requests to backing services.
any egress issues would be detected 
Once a 200ok response this endpoint is not probed again 
Liveness:

An endpoint exposed by the application which returns 200ok if the application is healthy and can accept requests
an http error response means this instance would be taken out of service load balancer
after the re-tries are exhausted this pod would be restarted automatically.
Documentation: How to expose liveliness and readiness endpoints


Step 1: Update the deployment manifest of pod to include the following:
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

```yaml
- name: metrics-proxy-container
        imagePullPolicy: IfNotPresent #Always #
        image: ajitchahal/nginx-side-car:latest
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
```
(lightbulb) Docker file 
```
FROM nginx
COPY nginx.conf /etc/nginx/nginx.conf
```


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
Step 3: Update the deployment manifest with liveness and readiness endpoints

containers:
- name: identity-container
  livenessProbe:
    httpGet:
      path: /liveness
      port: 9090
    initialDelaySeconds: 30
    periodSeconds: 5
  readinessProbe:
    httpGet:
      path: /readiness
      port: 9090
    initialDelaySeconds: 30
    periodSeconds: 5
```

Step 4: Update the default nginx conf and override it with a k8s config-map resource (if needed)
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


Step 5: In case the override of nginx.conf is required (change namespace)
```bash
kubectl -n tools create configmap argonauts-configs --from-file=nginx.conf --dry-run -o yaml | kubectl apply -f -
```

Step 5: Update your java/node js application  

Implements two http endpoints in the application which would expose liveness and readiness probes. These two endpoints are not necessarily dumb and can be used to perform ping to all egress endpoints. 

Implementation criteria:
when a request is sent to readiness endpoint, the communication with all other involved services is checked (using ping) and only if initialization is finished successfully and all communication channels this service needs to operate are up (ping returned 200), the readiness endpoint will send a 200 response, 503 otherwise with a message body that explains what went wrong (initialization, some ping, ...)
```java
@Component
@Path("/")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class HealthEndpoint {

    private static final Logger LOG = LoggerFactory.getLogger(HealthEndpoint.class);

    @Autowired
    private ConsentService consentService;

    @Resource(name = "identityServiceFactory")
    private IdentityServiceFactory identityServiceFactory;

    @GET
    @Timed
    @Path("/alive")
    public void isAlive(@Suspended final AsyncResponse asyncResponse) {
        asyncResponse.resume(Response.ok().build());
    }

    @GET
    @Timed
    @Path("/ready")
    public void isReady(@Suspended final AsyncResponse asyncResponse) {

        /*is a placeholder for now just return ok, can be used to wait for other services/resources/config/prob to/to egress services to be available*/
        /*if all succeeds return 200 else return 4xx for e.g. asyncResponse.resume(new AccessForbiddenException("Forbidden"));*/

        try {
            consentService.ping();
            identityServiceFactory.pingNeo4j();
            asyncResponse.resume(Response.ok().build());
        } catch (Exception ex) {
            asyncResponse.resume(new InternalServiceException(ex.getMessage()));
        }
    }
}
```

Step 5: Test if liveness and readiness probes are working
```bash
kubectl -n tools describe po identity-deployment-676ddc59fd-wk8q8
```






 