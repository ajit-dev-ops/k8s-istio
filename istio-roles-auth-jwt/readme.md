## istio rbac roles general info

https://istio.io/docs/tasks/security/role-based-access-control/

## istio ingress with basic auth:
```yaml
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRole
metadata:
  name: argo-cds-gateway-auth-role
  namespace: argonauts
spec:
  rules:
  - services: ["*.argonauts.svc.cluster.local"]
    methods: ["*"]
    constraints:
    - key: "request.headers[Authorization]"
      values:
      - "Basic {{ .Values.secrets.auth  | b64enc }}" ## add here your team specific basic auth credential in base64
  - services:
    - merge-service.argonauts.svc.cluster.local
    - page-view-enricher.argonauts.svc.cluster.local
    - commerce-enricher.argonauts.svc.cluster.local
    methods: ["GET"]
    paths: ["/api-console/*"]
    constraints:
    - key: "request.headers[Authorization]"
      values:
      - "Basic xxxx="
```
Ref:
- https://istio.io/docs/reference/config/authorization/istio.rbac.v1alpha1/


## JWT:
its quite simple just set it up in istio resource names `policy`
https://github.com/istio/istio/tree/release-1.0/security/tools/jwt/samples

- not working: setting up claim verification in istio.
- tried using serviceRoles and servicerolebindings

Ref for jwt:
- https://istio.io/docs/tasks/security/authn-policy/
- https://jwt.io/#debugger


## Egress:
https://istio.io/docs/tasks/traffic-management/egress/