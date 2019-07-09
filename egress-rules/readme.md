# Caveats
 ### instead of egress 1 can allow all traffic while deploying istio
 ### or 1 can use a service and custom endpoint resources to point to an external service, [docs](https://docs.openshift.org/latest/dev_guide/integrating_external_services.html#defining-a-service-for-an-external-database)
# Writing egress rules for an istio enabled pod and mTLS enabled side car injected.

## egress gateway to collect egress metrics
- https://istio.io/docs/tasks/traffic-management/egress/egress-gateway/



## Goals
1. Access an https & https service external to K8s 
2. Redeploy app and see if egress till functions properly
3. Test if the hack of accessing https services is still required
   e.g. in istio 0.6.0 http://api.ajit.de:443/test-service was required.
4. Verify if same ServiceEntry rules are to be defined in each namespace? 

## Results
1. A **serviceEntry resource** is required to be defined : Works
2. In istio 0.6.0 the egress rules were not working but all is fine using 0.8.0
deleted a deployment and redeployed it, all the external traffic is reachable
3. Note: all apps can call https endpoint normally
for e.g. https://google.com
4. ServiceEntry rules are global to K8s they are required to be defined only once in any namespace.

 
## Links

https://istio.io/docs/reference/config/istio.networking.v1alpha3/#HTTPRoute.retries 
https://istio.io/docs/tasks/traffic-management/egress/
https://istio.io/docs/reference/config/istio.networking.v1alpha3/#OutlierDetection
