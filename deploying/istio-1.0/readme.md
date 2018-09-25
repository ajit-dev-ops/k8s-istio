
##Helm params

## values file

https://istio.io/docs/tasks/security/mutual-tls/
enabling mtls
MeshPolicy
to set up all workloads to respond to mtls requests only.
destination rule
to set up client services to use mtls when calling destination services.
destination rules are also used for non-auth reasons such as setting up canarying, so if any destination rule created 
must set trafficPolicy tls mode to ISTIO_MUTUAL.
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL

#Changes since 0.8
gateway 
service entry
virtual service
