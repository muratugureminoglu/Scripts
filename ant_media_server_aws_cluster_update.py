import boto3, time
#
# This script terminates the existing instances (expect MongoDB) and recreates them with a new image.
#
ec2_client = boto3.client('ec2')
autoscaling_client = boto3.client('autoscaling')

# Ant Media Server Enterprise Edition details
Name="AntMedia-AWS-Marketplace-EE-*"
Arch="x86_64"
Owner="679593333241"

# Don't forget to change your autoscale group names
origin_group_name = 'origin-auto-scaling-group'
edge_group_name = 'edge-auto-scaling-group'

# Get the latest AMI of Ant Media Server
def image_id():

    image_response = boto3.client('ec2').describe_images(
        Owners=[Owner],
        Filters=[
            {'Name': 'name', 'Values': [Name]},
            {'Name': 'architecture', 'Values': [Arch]},
            {'Name': 'root-device-type', 'Values': ['ebs']},
        ],
    )

    ami = sorted(image_response['Images'],
                 key=lambda x: x['CreationDate'],
                 reverse=True)
    return (ami[0]['ImageId'])

class AutoscaleSettings:
    def __init__(self, autoscaling_client, group_name):
        self.autoscaling_client = autoscaling_client
        self.group_name = group_name
        self.desired_capacity = None
        self.min_size = None
        self.max_size = None

    def retrieve_settings(self):
        response = self.autoscaling_client.describe_auto_scaling_groups(AutoScalingGroupNames=[self.group_name])
        auto_scaling_group = response['AutoScalingGroups'][0]

        self.desired_capacity = auto_scaling_group['DesiredCapacity']
        self.min_size = auto_scaling_group['MinSize']
        self.max_size = auto_scaling_group['MaxSize']
        self.launch_config_name = auto_scaling_group['LaunchConfigurationName']
        response_1 = autoscaling_client.describe_launch_configurations(
            LaunchConfigurationNames=[self.launch_config_name]
        )
        self.launch_configuration = response_1['LaunchConfigurations'][0]
    def update_autoscale(self):
        print ("#########", self.group_name, "#########")
        print("The instances are terminating.")
        terminate_instances = autoscaling_client.update_auto_scaling_group(
            AutoScalingGroupName=self.group_name,
            MinSize=0,
            DesiredCapacity=0,
            MaxSize=0,
        )
        time.sleep(10)
        print ("Creating new Launch Templates")
        create_new_launch_template = autoscaling_client.create_launch_configuration(
            LaunchConfigurationName=self.launch_config_name + '-updated',
            ImageId=str(image_id()),
            InstanceType=self.launch_configuration['InstanceType'],
        )
        time.sleep(5)
        print ("Updating the Auto-Scaling Groups")
        update_autoscale = autoscaling_client.update_auto_scaling_group(
            AutoScalingGroupName=self.group_name,
            LaunchConfigurationName=self.launch_config_name + '-updated'

        )
        time.sleep(10)
        print ("New instances are creating with the latest version of Ant Media Server EE")
        update_capacity = autoscaling_client.update_auto_scaling_group(
            AutoScalingGroupName=self.group_name,
            MinSize=self.min_size,
            DesiredCapacity=self.desired_capacity,
            MaxSize=self.max_size,
        )
        print("##################")


# Create an instance of the AutoscaleSettings class
origin_settings = AutoscaleSettings(autoscaling_client, origin_group_name)
edge_settings = AutoscaleSettings(autoscaling_client, edge_group_name)

# Get settings
origin_settings.retrieve_settings()
edge_settings.retrieve_settings()

# Update Auto-Scaling
origin_settings.update_autoscale()
edge_settings.update_autoscale()
