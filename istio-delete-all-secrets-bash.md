#!/usr/bin/env bash
set -e

DELETE_COMMANDS=$(kubectl get secret --all-namespaces | grep istio.io/key-and-cert | sed -E 's/^([^[:space:]]+)[[:space:]]+([^[:space:]]+).*/kubectl delete secret \2 -n \1/g')
for DELETE_COMMAND in ${DELETE_COMMANDS[@]}
do
	echo $DELETE_COMMAND
	# DELETE_COMMAND
done


all_namespaces=( `kubectl get ns -l istio-injection=enabled -o jsonpath='{..name}'` )
for namespace in "${all_namespaces[@]}"
do
   #echo "${element}"
   all_namespace_pods=( `kubectl -n ${namespace} get po -o jsonpath='{.items[*].metadata.name}'` )
   for pod in "${all_namespace_pods[@]}"
   do
      echo deleting $pod in $namespace
      #kubectl -n $namespace delete po $pod
   done
done
