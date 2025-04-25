#!/bin/bash
namespace="antmedia" 
service_name="ant-media-origin" 
port=5080
kubeconfig_path="/etc/conf.d/kubeconfig"

# Get all pod names in the namespace that match the service name
pods=$(kubectl --kubeconfig="$kubeconfig_path" get pods -n "$namespace" -l "app=$service_name" -o jsonpath='{.items[*].metadata.name}')

# Initialize variables
critical_pods=()
all_ok=true

echo "Checking HTTP status for each pod..."
echo "----------------------------------------"

for pod in $pods; do
    status=$(kubectl --kubeconfig="$kubeconfig_path" exec -n "$namespace" "$pod" -- curl -s -o /dev/null -w "%{http_code}" http://localhost:$port/Conference/rest/circle/version)
    
    echo "Pod: $pod - Status: $status"
    
    if [[ "$status" != "200" ]]; then
        echo "ERROR: Pod $pod returned status $status instead of 200!"
        critical_pods+=("$pod")
        all_ok=false
    else
        echo "Pod $pod status OK."
    fi
    echo "----------------------------------------"
done

if [ "$all_ok" == false ]; then
    echo ""
    echo "CRITICAL - The following pods returned non-200 status:"
    for critical_pod in "${critical_pods[@]}"; do
        echo "- $critical_pod"
    done
    exit 2
else
    echo "OK - All pods returned status 200."
    exit 0
fi
