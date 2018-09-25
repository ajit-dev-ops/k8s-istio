# Deploy istio to minikube and verify mTLS

### To deploy istio 0.8.0 on local minikube
  $ ./deploying-on-minikube/deploy-istio-1.0.1.sh

### To deploy istio 0.8.0 on local minikube
  $ ./deploying-on-minikube/deploy-istio-0.8.0.sh

 
### To deploy istio 0.6.0 on local minikube
  $ ./deploying-on-minikube/deploy-istio-0.6.0.sh


## Verifying mutual tls 
#### After istio is deployed and all pods are running in istio-system namespace run following script 
  $ ./deploying-on-minikube/test-istio-mtls/istio_demo_on_minikube-with-ambassador.sh 
