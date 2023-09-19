#!/bin/bash

#-------- k8s
kenv() { 
	kubectl exec -it $1 -- env
}

kcurl() {
	local POD CMD 
	PARAMS=$(getopt -o p:u: --name "$0" -- "$@")
	eval set -- "$PARAMS"
	while true
	do
		case "$1" in
			-p)
				POD="$2"
				shift 2
				;;
			-u)	URL="$2"
				shift 2
				;;
			--)
				shift
				break
				;;
		esac
	done	

	if [ -z "$POD" ]; then
		echo "Pod name is missing"
		return 1
	fi

	k debug -it $POD --image=curlimages/curl:latest -- curl -IL $URL
}

wp() {
	watch kubectl get pods -Lversion,release,branch $@
}

wpa() {
	watch kubectl get pods -Lversion,release,branch -lapp=$1 --all-namespaces
}
