#!/usr/bin/env bash

#openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=*.ajit.de"


kubectl create configmap ing-conf --from-file=nginx.conf --dry-run -o yaml | kubectl apply -f -

#https://archive.istio.io/v0.6/docs/tasks/traffic-management/ingress#configuring-secure-ingress-https
#Note: the secret must be called istio-ingress-certs in istio-system namespace, for it to be mounted on Istio Ingress.
kubectl create -n istio-system secret tls istio-ingressgateway-certs --key tls.key --cert tls.crt
