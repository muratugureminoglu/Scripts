import boto3

# AWS credentials and region
aws_access_key = ''
aws_secret_key = ''
aws_region = ''

# Constants for instance limits
C5_XLARGE_EDGE_LIMIT = 150
C5_4XLARGE_EDGE_LIMIT = C5_XLARGE_EDGE_LIMIT * 4
C5_9XLARGE_EDGE_LIMIT = C5_XLARGE_EDGE_LIMIT * 7
C5_XLARGE_ORIGIN_LIMIT = 40
C5_4XLARGE_ORIGIN_LIMIT = C5_XLARGE_ORIGIN_LIMIT * 4
C5_9XLARGE_ORIGIN_LIMIT = C5_XLARGE_ORIGIN_LIMIT * 9

# Initialize AWS clients
autoscaling_client = boto3.client('autoscaling', aws_access_key_id=aws_access_key, aws_secret_access_key=aws_secret_key, region_name=aws_region)
ec2_client = boto3.client('ec2', aws_access_key_id=aws_access_key, aws_secret_access_key=aws_secret_key, region_name=aws_region)

# Find Auto Scaling Group names with specific prefixes
asg_names = autoscaling_client.describe_auto_scaling_groups()
asg_edge_name = [group for group in asg_names['AutoScalingGroups'] if 'EdgeGroup' in group['AutoScalingGroupName']]
asg_origin_name = [group for group in asg_names['AutoScalingGroups'] if 'OriginGroup' in group['AutoScalingGroupName']]
asg_edge_group_names = [group['AutoScalingGroupName'] for group in asg_edge_name][0]
asg_origin_group_names = [group['AutoScalingGroupName'] for group in asg_origin_name][0]

# Describe Auto Scaling Groups
edge_autoscaling_group = autoscaling_client.describe_auto_scaling_groups(AutoScalingGroupNames=[asg_edge_group_names])
origin_autoscaling_group = autoscaling_client.describe_auto_scaling_groups(AutoScalingGroupNames=[asg_origin_group_names])

# Get instance types and current instance counts
edge_instance_type = edge_autoscaling_group['AutoScalingGroups'][0]['Instances'][0]['InstanceType']
origin_instance_type = edge_autoscaling_group['AutoScalingGroups'][0]['Instances'][0]['InstanceType']
edge_current_instance_count = len(edge_autoscaling_group['AutoScalingGroups'][0]['Instances'])
origin_current_instance_count = len(origin_autoscaling_group['AutoScalingGroups'][0]['Instances'])

#instance_type='c5.xlarge'
current_instance_count=int(2)

# Set viewer and publisher counts
viewer_count = 300
publisher_count = 50

# Function to check and upgrade Auto Scaling Group capacity
def check_and_upgrade(count, current_instance_count, asg_name):
    if count > current_instance_count:
        response = autoscaling_client.update_auto_scaling_group(
            AutoScalingGroupName=asg_name,
            DesiredCapacity=count,
            MinSize=count
        )

# Check and upgrade Auto Scaling Group if instance type matches
if edge_instance_type == "c5.xlarge":
    edge_count = -(-viewer_count // C5_XLARGE_EDGE_LIMIT)
    print (edge_count)
    check_and_upgrade(edge_count, edge_current_instance_count,asg_edge_group_names)
if origin_instance_type == "c5.xlarge":
    origin_count = -(-publisher_count // C5_XLARGE_ORIGIN_LIMIT)
    print (origin_count)
    check_and_upgrade(origin_count, origin_current_instance_count,asg_origin_group_names)
if edge_instance_type == "c5.4xlarge":
    edge_count = -(-viewer_count // C5_4XLARGE_EDGE_LIMIT)
    print(edge_count)
    check_and_upgrade(edge_count, edge_current_instance_count,asg_edge_group_names)
if origin_instance_type == "c5.4xlarge":
    origin_count = -(-publisher_count // C5_4XLARGE_ORIGIN_LIMIT)
    print(origin_count)
    check_and_upgrade(origin_count, origin_current_instance_count,asg_origin_group_names)
if edge_instance_type == "c5.9xlarge":
    edge_count = -(-viewer_count // C5_9XLARGE_EDGE_LIMIT)
    print(edge_count)
    check_and_upgrade(edge_count, edge_current_instance_count,asg_edge_group_names)
if origin_instance_type == "c5.9xlarge":
    origin_count = -(-publisher_count // C5_9XLARGE_ORIGIN_LIMIT)
    print(origin_count)
    check_and_upgrade(origin_count, origin_current_instance_count,asg_origin_group_names)
