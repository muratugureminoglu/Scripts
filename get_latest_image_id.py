#!/usr/bin/python3
#
# You can find the latest image ID for all zones with this script
#
# pip3 install boto3 
# python3 latest_ami.py
#
# Find Owner/Name/ImageLocation
# aws ec2 describe-images  --owners aws-marketplace --filters "Name=name,Values=*ubuntu*" | jq -r '.Images[] | "\(.OwnerId)\t\(.Name)\t\(.ImageLocation)"'
#

import boto3

#Name= "ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"
#Name= "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
Name="AntMedia-AWS-Marketplace-EE-*"
Arch="x86_64"
Owner="679593333241" 


def default_image(region):
	boto3.setup_default_session(region_name=region)
	response = boto3.client('ec2').describe_images(
	  Owners=[Owner],
	  Filters=[
	    {'Name': 'name', 'Values': [Name]},
	    {'Name': 'architecture', 'Values': [Arch]},
	    {'Name': 'root-device-type', 'Values': ['ebs']},
	  ],
	)

	amis = sorted(response['Images'],
	            key=lambda x: x['CreationDate'],
	            reverse=True)
	id = amis[0]['ImageId']
	print ("Region:"+region, "ImageId:"+id)

zone = boto3.client('ec2').describe_regions()
regions = zone['Regions']
for region in regions:
	try:
	    reg = region['RegionName']
	    default_image(reg)
	except:
		print ("Region:",reg, "ImageId:" +"NULL")

