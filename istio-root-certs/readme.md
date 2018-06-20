# Custom root cert for istio

Istio generates root and workload certs( for each namespace 1 in istio.default secret). Root cert is used to sign workload certs and are used in mTLS communication.
One can provide istio citadel root certs in **cacerts** secret, and istio would rather use these secret.
Such provided certs can be used to rotate certs on demand for enhanced security.

Note: any app can use certs in istio.default secret to talk to any app with mTLS, but it needs to refresh itself when the workload certs get rotated.
 


### Istio CA certs for mTLS
- https://istio.io/docs/tasks/security/plugin-ca-cert/ 
- https://archive.istio.io/v0.6/docs/tasks/security/plugin-ca-cert
- https://github.com/istio/istio/blob/master/security/samples/plugin_ca_certs/gen_certs.sh


## get a cert from istio.default workload certs
kg get secret istio.default -o json | jq -r '.data | "\(.["root-cert.pem"])"' | base64 --decode
kg get secret istio.default -o json | jq -r '.data | "\(.["key.pem"])"' | base64 --decode
kg get secret istio.default -o json | jq -r '.data | "\(.["cert-chain.pem"])"' | base64 --decode

## Reading a certificate 
https://github.com/istio/istio/issues/3155
openssl x509 -noout -text -in /etc/certs/cert-chain.pem

certificate TTL https://github.com/istio/istio/blob/master/security/cmd/istio_ca/main.go#L135


## Verifying a certificate:
openssl s_client -connect 10.109.162.113:80 -CAfile /etc/ambassador-client-certs/root-cert.pem -cert /etc/ambassador-client-certs/ambassador-chain.pem -key /etc/ambassador-client-certs/ambassador-key.pem

/application # openssl s_client -connect 10.109.162.113:80 -CAfile /etc/ambassador-client-certs/root-cert.pem -cert /etc/ambassador-client-certs/ambassador-chain.pem -key /etc/ambassador-client-certs/amba
ssador-key.pem -state -nbio 2>&1 | grep "^SSL"

```bash
SSL_connect:before/connect initialization
SSL_connect:SSLv2/v3 write client hello A
SSL_connect:error in SSLv2/v3 read server hello A
SSL_connect:SSLv3 read server hello A
SSL_connect:SSLv3 read server certificate A
SSL_connect:SSLv3 read server key exchange A
SSL_connect:SSLv3 read server certificate request A
SSL_connect:SSLv3 read server done A
SSL_connect:SSLv3 write client certificate A
SSL_connect:SSLv3 write client key exchange A
SSL_connect:SSLv3 write certificate verify A
SSL_connect:SSLv3 write change cipher spec A
SSL_connect:SSLv3 write finished A
SSL_connect:SSLv3 flush data
SSL_connect:error in SSLv3 read server session ticket A
SSL_connect:error in SSLv3 read server session ticket A
SSL3 alert read:fatal:unknown CA
SSL_connect:failed in SSLv3 read server session ticket A
SSL handshake has read 2479 bytes and written 1316 bytes
```

