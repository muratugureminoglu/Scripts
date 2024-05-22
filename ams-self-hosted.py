import boto3, os, time, json

def lambda_handler(event, context):

    listener_arn = os.environ['LISTENER_ARN']
    origin_asg = os.environ['ORIGIN_ASG']
    target_group_arn = os.environ['TARGETGROUP_ARN']
    alarm_name = 'AutoScalingGroupScaleDownAlarm'
    autoscaling_client = boto3.client('autoscaling')
    elb_client = boto3.client('elbv2')
    ec2_client = boto3.client("ec2")
    ssm_client = boto3.client('ssm')
    cloudwatch_client = boto3.client('cloudwatch')

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

    print(f"Auto Scaling Group name: {asg_origin_group_names}")
    origin_calculate_total_instance = autoscaling_client.describe_auto_scaling_groups(AutoScalingGroupNames=[asg_origin_group_names])
    origin_current_capacity = len(origin_calculate_total_instance['AutoScalingGroups'][0]['Instances'])
    instance = origin_calculate_total_instance['AutoScalingGroups'][0]['Instances']
    try:
        instance_id = instance[0]['InstanceId']
        print("Current capacity and Instance ID", {"origin_current_capacity": origin_current_capacity, "instance_id": instance_id})
    except IndexError:
        cloudwatch_set_ok(alarm_name)
        print("No instances found in Auto Scaling Group", asg_origin_group_names)
        return {
            'statusCode': 200,
            'body': json.dumps({"message": "No instances found in Auto Scaling Group"})
        }

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
    print(f"SSM command output: {smm_output}")
    #debug
    #print(invocation_response['StandardOutputContent'])
    #error = invocation_response['StandardErrorContent'].strip()

    if origin_current_capacity == 1:
        if smm_output == 'false':
            print("No live streams found. Updating Auto Scaling Group.")
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
            cloudwatch_set_ok(alarm_name)
            print(origin_response)
            return {
                'statusCode': 200,
                'body': 'Auto Scaling Group updated successfully!'
            }
        else:
            print("Live streams found.")
    else:
        print(f"Current capacity is not 1, it is {origin_current_capacity}. No updates needed.")
        
    cloudwatch_set_ok(alarm_name)
    return {
        'statusCode': 200,
        'body': 'Auto Scaling Group does not require update.'
    }


def cloudwatch_set_ok(alarm_name):
    try:
        cloudwatch_client = boto3.client('cloudwatch')
        cloudwatch_response = cloudwatch_client.set_alarm_state(
            AlarmName=alarm_name,
            StateValue='OK',
            StateReason='Updating alarm state to OK'
        )
        print("Alarm state updated to OK", cloudwatch_response)
        return cloudwatch_response
    except Exception as e:
        error_message = {
            "error": str(e),
            "function": "cloudwatch_set_ok",
            "alarm_name": alarm_name
        }
        print(json.dumps(error_message))
        raise e
