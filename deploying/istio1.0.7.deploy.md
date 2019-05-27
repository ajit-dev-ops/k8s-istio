## installing as helm template  
https://preliminary.istio.io/docs/setup/kubernetes/install/helm/#option-1-install-with-helm-via-helm-template

## installing with helm tiller (discouraged)
https://preliminary.istio.io/docs/setup/kubernetes/install/helm/#option-2-install-with-helm-and-tiller-via-helm-install

##installing istio with istio-cni
https://github.com/istio/cni#usage
https://preliminary.istio.io/docs/setup/kubernetes/additional-setup/cni/


---
Security:

Run containers as non-root users 
How: by default, all docker processes run as root, create a user in a container and run all processes with it.
https://medium.com/@mccode/processes-in-containers-should-not-run-as-root-2feae3f0df3b


All PODs run without any [PSP](https://kubernetes.io/docs/concepts/policy/pod-security-policy/#create-a-policy-and-a-pod) attached to the SA, this means they can run privileged containers. 
Why: Because istio's side car injecter initContainers must run as [NET_ADMIN|https://github.com/istio/cni#istio-cni-plugin].
Solution: install istio CNI, along with istio, which removes the need for a privileged, NET_ADMIN container in the Istio users' application pods.
How to: https://preliminary.istio.io/docs/setup/kubernetes/additional-setup/cni/
Prerequisites: Checked with idefix all our clusters are CNI compliant. 
Cloud be done with istio 1.1.x upgrade https://github.com/istio/cni/releases
