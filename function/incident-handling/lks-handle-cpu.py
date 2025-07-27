import json
import boto3

def resize_instance_handler(event, context):
    """
    Input: {"instance_id": "i-xxx", "incident_id": "INC-2025-001"}
    """
    ec2 = boto3.client('ec2')
    
    instance_id = event['instance_id']
    incident_id = event['incident_id']
    incident_type = event.get('incident_type', 'unknown')
    new_instance_type = "m5.large"
    
    try:
        # Get current instance info
        response = ec2.describe_instances(InstanceIds=[instance_id])
        instance = response['Reservations'][0]['Instances'][0]
        current_state = instance['State']['Name']
        current_type = instance['InstanceType']
        
        # Skip if already same type
        if current_type == new_instance_type:
            return {
                'instance_id': instance_id,
                'incident_id': incident_id,
                'incident_type': incident_type,
                'status': 'no_change',
                'instance_type': current_type,
                'state': current_state
            }
        
        # Stop if running
        if current_state == 'running':
            ec2.stop_instances(InstanceIds=[instance_id])
            # Wait for stopped state
            waiter = ec2.get_waiter('instance_stopped')
            waiter.wait(InstanceIds=[instance_id])
        
        # Modify instance type
        ec2.modify_instance_attribute(
            InstanceId=instance_id,
            InstanceType={'Value': new_instance_type}
        )
        
        # Start instance back
        if current_state == 'running':
            ec2.start_instances(InstanceIds=[instance_id])
        
        return {
            'instance_id': instance_id,
            'incident_id': incident_id,
            'incident_type': incident_type,
            'status': 'success',
            'old_instance_type': current_type,
            'new_instance_type': new_instance_type,
            'was_running': current_state == 'running'
        }
        
    except Exception as e:
        return {
            'instance_id': instance_id,
            'incident_id': incident_id,
            'incident_type': incident_type,
            'status': 'error',
            'error': str(e)
        }