import boto3

aws_access_key = ''
aws_secret_key = ''
aws_region = ''

C5_XLARGE_EDGE_LIMIT = 150
C5_4XLARGE_EDGE_LIMIT = C5_XLARGE_EDGE_LIMIT * 4
C5_9XLARGE_EDGE_LIMIT = C5_XLARGE_EDGE_LIMIT * 7
C5_XLARGE_ORIGIN_LIMIT = 40
C5_4XLARGE_ORIGIN_LIMIT = C5_XLARGE_ORIGIN_LIMIT * 4
C5_9XLARGE_ORIGIN_LIMIT = C5_XLARGE_ORIGIN_LIMIT * 9


autoscaling_client = boto3.client('autoscaling', aws_access_key_id=aws_access_key, aws_secret_access_key=aws_secret_key, region_name=aws_region)
ec2_client = boto3.client('ec2', aws_access_key_id=aws_access_key, aws_secret_access_key=aws_secret_key, region_name=aws_region)

# Find automatically ASG names
asg_names = autoscaling_client.describe_auto_scaling_groups()
asg_edge_name = [group for group in asg_names['AutoScalingGroups'] if 'EdgeGroup' in group['AutoScalingGroupName']]
asg_origin_name = [group for group in asg_names['AutoScalingGroups'] if 'OriginGroup' in group['AutoScalingGroupName']]
asg_edge_group_names = [group['AutoScalingGroupName'] for group in asg_edge_name][0]
asg_origin_group_names = [group['AutoScalingGroupName'] for group in asg_origin_name][0]

edge_autoscaling_group = autoscaling_client.describe_auto_scaling_groups(AutoScalingGroupNames=[asg_edge_group_names])
origin_autoscaling_group = autoscaling_client.describe_auto_scaling_groups(AutoScalingGroupNames=[asg_origin_group_names])

edge_instance_type = edge_autoscaling_group['AutoScalingGroups'][0]['Instances'][0]['InstanceType']
origin_instance_type = edge_autoscaling_group['AutoScalingGroups'][0]['Instances'][0]['InstanceType']

edge_current_instance_count = len(edge_autoscaling_group['AutoScalingGroups'][0]['Instances'])
origin_current_instance_count = len(origin_autoscaling_group['AutoScalingGroups'][0]['Instances'])

#instance_type='c5.xlarge'
current_instance_count=int(2)

viewer_count = 200
publisher_count = 1

def edge_check_and_upgrade(edge_count, current_instance_count):
    if edge_count > current_instance_count:
        edge = autoscaling_client.update_auto_scaling_group(
            AutoScalingGroupName=asg_edge_group_names,
            DesiredCapacity=edge_count
        )

def origin_check_and_upgrade(origin_count, current_instance_count):
    if origin_count > current_instance_count:
        origin = autoscaling_client.update_auto_scaling_group(
            AutoScalingGroupName=asg_origin_group_names,
            DesiredCapacity=origin_count
        )

if edge_instance_type == "c5.xlarge":
    if viewer_count >= 1 and viewer_count <= C5_XLARGE_EDGE_LIMIT * 10:
        edge_count = -(-viewer_count // C5_XLARGE_EDGE_LIMIT)
        print (edge_count)
    edge_check_and_upgrade(edge_count, edge_current_instance_count)
elif origin_instance_type == "c5.xlarge":
    if publisher_count >= 1 and publisher_count <= C5_XLARGE_ORIGIN_LIMIT * 3:
        origin_count = -(-publisher_count // C5_XLARGE_ORIGIN_LIMIT)
        print (origin_count)
    origin_check_and_upgrade(origin_count, origin_current_instance_count)
elif edge_instance_type == "c5.4xlarge":
    if viewer_count >= C5_XLARGE_EDGE_LIMIT * 10 + 1 and viewer_count <= C5_4XLARGE_EDGE_LIMIT * 10:
        edge_count = -(-viewer_count // C5_4XLARGE_EDGE_LIMIT)
        print(edge_count)
    if publisher_count >= C5_XLARGE_ORIGIN_LIMIT * 3 + 1 and publisher_count <= C5_4XLARGE_ORIGIN_LIMIT * 3:
        origin_count = -(-publisher_count // C5_4XLARGE_ORIGIN_LIMIT)
        print(origin_count)
    edge_check_and_upgrade(edge_count, current_instance_count)
elif origin_instance_type == "c5.4xlarge":
    if publisher_count >= C5_XLARGE_ORIGIN_LIMIT * 3 + 1 and publisher_count <= C5_4XLARGE_ORIGIN_LIMIT * 3:
        origin_count = -(-publisher_count // C5_4XLARGE_ORIGIN_LIMIT)
        print(origin_count)
    origin_check_and_upgrade(origin_count, current_instance_count)
elif edge_instance_type == "c5.9xlarge":
    if viewer_count >= C5_4XLARGE_EDGE_LIMIT * 10 + 1:
        edge_count = -(-viewer_count // C5_9XLARGE_EDGE_LIMIT)
        print(edge_count)
    if publisher_count >= C5_4XLARGE_ORIGIN_LIMIT * 3 + 1:
        origin_count = -(-publisher_count // C5_9XLARGE_ORIGIN_LIMIT)
        print(origin_count)
    edge_check_and_upgrade(edge_count, current_instance_count)
elif origin_instance_type == "c5.9xlarge":
    if publisher_count >= C5_4XLARGE_ORIGIN_LIMIT * 3 + 1:
        origin_count = -(-publisher_count // C5_9XLARGE_ORIGIN_LIMIT)
        print(origin_count)
    origin_check_and_upgrade(origin_count, current_instance_count)
else:
    print("exit")
