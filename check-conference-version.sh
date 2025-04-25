#!/bin/bash
namespace="antmedia" 
service_name="ant-media-origin" 
port=5080
kubeconfig_path="/etc/conf.d/kubeconfig"
xml_url="https://oss.sonatype.org/service/local/repositories/snapshots/content/io/antmedia/ant-media-server/maven-metadata.xml"
last_updated=$(curl -s "$xml_url" | grep -oP '(?<=<lastUpdated>).*?(?=</lastUpdated>)')
pods=$(kubectl --kubeconfig="$kubeconfig_path" get pods -n "$namespace" -l app="$service_name" -o jsonpath='{.items[*].metadata.name}')
all_equal=true
echo "Latest Version: $last_updated"

# Clean the last_updated value for fair comparison
cleaned_last_updated=$(echo "$last_updated" | tr -d '[:space:]_-')
echo "Cleaned Latest Version: $cleaned_last_updated"

for pod in $pods; do
    build_number=$(kubectl --kubeconfig="$kubeconfig_path" exec -n "$namespace" "$pod" -- curl -s "http://localhost:$port/Conference/rest/circle/version" | grep -oP '(?<="buildNumber":")[^"]*')
    
    # Clean the build number for fair comparison
    formatted_build_number=$(echo "$build_number" | sed 's/_//')
    cleaned_build_number=$(echo "$formatted_build_number" | tr -d '[:space:]_-')
    
    echo "Pod: $pod, Original BuildNumber: $build_number"
    echo "Pod: $pod, Formatted BuildNumber: $formatted_build_number"
    echo "Pod: $pod, Cleaned BuildNumber: $cleaned_build_number"
    
    if [[ "$cleaned_last_updated" != "$cleaned_build_number" ]]; then
        echo "The version in pod $pod is different!"
        echo "Expected: $cleaned_last_updated"
        echo "Got: $cleaned_build_number"
        mismatched_pods+=("$pod ($formatted_build_number)")
        all_equal=false
    else
        echo "Pod $pod version matches."
    fi
    echo "----------------------------------------"
done

if [ "$all_equal" == false ]; then
    echo ""
    echo "CRITICAL - Some pods have wrong circle version."
    exit 2
else
    echo "OK - All pod versions match the reference build number."
    exit 0
fi
