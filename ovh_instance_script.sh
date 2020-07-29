#!/bin/bash
#OVH Installation Script

AUTH_URL="https://auth.cloud.ovh.net/v3/"
API_VERSION="3"
USER_DOMAIN_NAME="default"
PROJECT_DOMAIN_NAME="default"
TENANT_ID=""
TENANT_NAME=""
USERNAME=""
PASSWORD=""

os="openstack --os-auth-url $AUTH_URL --os-identity-api-version $API_VERSION --os-user-domain-name $USER_DOMAIN_NAME \
			  --os-project-domain-name $PROJECT_DOMAIN_NAME --os-tenant-id $TENANT_ID --os-tenant-name $TENANT_NAME  \
			  --os-username $USERNAME  --os-password $PASSWORD "

instance_type="b2-7"
instance_name="murat_test"
instance_os="Ubuntu 18.04"
key="ovh"
instance_region="DE1"

#install openstack
pkgs='python3-openstackclient python3-novaclient unzip'
if ! dpkg -s $pkgs >/dev/null 2>&1; then
  sudo apt-get install $pkgs -y -qq > /dev/null 2>&1 &
  echo "Installing packages..."
  wait $!
  echo "Packages installed."
fi

delete_instances() {

	$os --os-region-name $instance_region server delete $instance_name
}

create_instance() {

	$os --os-region-name "DE1" server create --flavor $instance_type --image "$instance_os" --network Ext-Net --key-name $key \
		--security-group default $instance_name > /dev/null
	sleep 10
	while [ -z $($os --os-region-name $instance_region server list --name $instance_name -f value -c Networks | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}") ]; do
		sleep 1	
	done
	ip=`$os --os-region-name $instance_region server list --name $instance_name -f value -c Networks | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"`

}


if [ ! -z $1 ]; then
	if [ $1 == "--delete" ]; then
	delete_instances
	if [ $? == "0" ]; then
		echo "The instance was deleted."		
		exit 1
	fi
fi
fi

create_instance

if [ $? == "0" ]; then
	echo "Instance was created.\nInstance IP Address: $ip"
else
	echo "The instance was not created."
fi
