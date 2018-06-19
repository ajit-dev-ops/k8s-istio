
### Istio CA certs for mTLS
- https://istio.io/docs/tasks/security/plugin-ca-cert/
- https://github.com/istio/istio/blob/master/security/samples/plugin_ca_certs/gen_certs.sh


Verifying a certificate:
openssl s_client -connect 10.109.162.113:80 -CAfile /etc/ambassador-client-certs/root-cert.pem -cert /etc/ambassador-client-certs/ambassador-chain.pem -key /etc/ambassador-client-certs/ambassador-key.pem

/application # openssl s_client -connect 10.109.162.113:80 -CAfile /etc/ambassador-client-certs/root-cert.pem -cert /etc/ambassador-client-certs/ambassador-chain.pem -key /etc/ambassador-client-certs/amba
ssador-key.pem -state -nbio 2>&1 | grep "^SSL"

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