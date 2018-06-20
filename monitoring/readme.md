### Explore istio prometheus monitoring


### options

- [Servicegraph](https://istio.io/docs/tasks/telemetry/servicegraph/)


### Prometheus with istio
An app with istio mtls is not accessible by prometheus, which is not running with mTLS.

Solution: expose a port for prometheus metrics which is not listed in **containerPort** in pod manifest. Such ports are monitored by istio envoy.
Also in service manifest add 
```yaml
annotations:
    auth.istio.io/9000: NONE   
```

Solution is described at:
https://github.wdf.sap.corp/kyma/concept-documentation/tree/master/prometheus-custom-metrics