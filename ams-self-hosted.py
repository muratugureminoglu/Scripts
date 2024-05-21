import boto3, time, json, os

def lambda_handler(event, context):
    listener_arn = os.environ['LISTENER_ARN']
    origin_asg = os.environ['ORIGIN_ASG']
    target_group_arn = os.environ['TARGETGROUP_ARN']
    autoscaling_client = boto3.client('autoscaling')
    elb_client = boto3.client('elbv2')
    ec2_client = boto3.client("ec2")
    ssm_client = boto3.client('ssm')

    script = """
    #/usr/bin/env bash -x
    sed -i 's|INSTALL_DIRECTORY="$1"|INSTALL_DIRECTORY="/usr/local/antmedia"|g' /usr/local/antmedia/conf/jwt_generator.sh
    . /usr/local/antmedia/conf/jwt_generator.sh
    generate_jwt
    REST_URL="http://localhost:5080/rest/v2/applications-info"
    curl -s -L "$REST_URL" --header "ProxyAuthorization: $JWT_KEY" -o /tmp/curl_output.txt
    jq '[.[] | select(.liveStreamCount > 0)] | length > 0' /tmp/curl_output.txt
    """

    asg_names = autoscaling_client.describe_auto_scaling_groups()
    asg_origin_name = [group for group in asg_names['AutoScalingGroups'] if
                       origin_asg in group['AutoScalingGroupName']]
    asg_origin_group_names = [group['AutoScalingGroupName'] for group in asg_origin_name][0]

    origin_calculate_total_instance = autoscaling_client.describe_auto_scaling_groups(AutoScalingGroupNames=[asg_origin_group_names])
    origin_current_capacity = len(origin_calculate_total_instance['AutoScalingGroups'][0]['Instances'])
    instance = origin_calculate_total_instance['AutoScalingGroups'][0]['Instances']
    instance_id = instance[0]['InstanceId']

    smm_response = ssm_client.send_command(
        DocumentName ='AWS-RunShellScript',
        Parameters = {'commands': [script]},
        InstanceIds = [instance_id]
    )

    command_id = smm_response['Command']['CommandId']

    while True:
        time.sleep(2)
        invocation_response = ssm_client.get_command_invocation(
            CommandId=command_id,
            InstanceId=instance_id,
        )
        if invocation_response['Status'] not in ['Pending', 'InProgress']:
            break

    smm_output = invocation_response['StandardOutputContent'].strip()

    #debug
    #print(invocation_response['StandardOutputContent'])
    #error = invocation_response['StandardErrorContent'].strip()

    if origin_current_capacity == 1:
        if smm_output == 'false':
            origin_response = autoscaling_client.update_auto_scaling_group(
                AutoScalingGroupName=asg_origin_group_names,
                MinSize=0,
                DesiredCapacity=0
            )

            create_rule = elb_client.create_rule(
                Actions=[
                    {
                        'Type': 'forward',
                        'TargetGroupArn': target_group_arn
                    }
                ],
                Conditions=[
                    {
                        'Field': 'path-pattern',
                        'Values': ['*']
                    }
                ],
                ListenerArn=listener_arn,
                Priority=1
            )

            print(origin_response)
            return {
                'statusCode': 200,
                'body': 'Auto Scaling Group updated successfully!'
            }
    else:
        return {
            'statusCode': 200,
            'body': 'Auto Scaling Group does not require update.'
        }
