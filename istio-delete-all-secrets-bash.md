```bash
#!/usr/bin/env bash
#set -e

/scripts/common.sh
#cat /root/.kube/config

all_namespaces=( `kubectl get ns -l istio-injection=enabled -o jsonpath='{..name}'` )
#for namespace in "${all_namespaces[@]}"
#do
#   #echo "${element}"
#   all_namespace_secrets=( `kubectl -n ${namespace} get secret -o jsonpath='{.items[?(@.type=="istio.io/key-and-cert")].metadata.name}'` )
#   for secret in "${all_namespace_secrets[@]}"
#   do
#      #echo deleting $secret in $namespace
#      kubectl -n $namespace delete secret $secret
#   done
#done


for namespace in "${all_namespaces[@]}"
do
   #echo "${element}"
   all_namespace_pods=( `kubectl -n ${namespace} get po -o jsonpath='{.items[*].metadata.name}'` )
   for pod in "${all_namespace_pods[@]}"
   do
      if [[ $pod != *"tiller"* ]] && [[ $pod != *"istio-post"* ]]; then
       is_istio_injected_pod=`kubectl -n ${namespace}  get po $pod -o yaml | grep 'image: istio/proxy' -c`
       #echo $is_istio_injected_pod
       if [[ $is_istio_injected_pod -gt 0 ]]; then
           #echo deleting $pod in $namespace
           kubectl -n $namespace delete po $pod --wait=false
           sleep 2
       fi
      fi
   done
done

#for namespace in "${all_namespaces[@]}"
#do
#  echo   kubectl -n $namespace delete pods --all
#  kubectl -n $namespace delete pods --all
#  echo "sleeping for 90 sec"
#  sleep 90
#done


#for debug purposes un-comment
#sleep 600



```
