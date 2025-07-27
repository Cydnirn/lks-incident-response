import json
import boto3
import os
from datetime import datetime
from botocore.exceptions import ClientError

def cloudwatch_alarm_handler(event, context):
    """
    Simple CloudWatch Alarm handler - identify incident type and trigger Step Function
    """
    
    try:
        print(f"Received alarm event: {json.dumps(event)}")
        
        # Process SNS message from CloudWatch
        for record in event.get('Records', []):
            sns_message = record.get('Sns', {})
            subject = sns_message.get('Subject', '')
            message_body = sns_message.get('Message', '{}')
            
            # Parse alarm data
            try:
                alarm_data = json.loads(message_body)
            except:
                print(f"Failed to parse alarm message: {message_body}")
                continue
            
            # Only process ALARM state
            if alarm_data.get('NewStateValue') != 'ALARM':
                print(f"Ignoring non-ALARM state: {alarm_data.get('NewStateValue')}")
                continue
            
            # Process the alarm
            process_alarm(alarm_data, subject)
        
        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Alarms processed successfully'})
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }


def process_alarm(alarm_data, subject):
    """
    Process alarm and trigger Step Function
    """
    try:
        alarm_name = alarm_data.get('AlarmName', '')
        alarm_description = alarm_data.get('AlarmDescription', '')
        reason = alarm_data.get('NewStateReason', '')
        
        print(f"Processing alarm: {alarm_name}")
        
        # Identify incident type
        incident_type = identify_incident_type(alarm_name, subject, alarm_description)
        
        # Skip if not allowed incident type
        if not incident_type:
            print(f"Alarm type not allowed, skipping: {alarm_name}")
            return
        
        # Extract instance/resource info
        instance_id = extract_instance_id(alarm_data)
        
        # Get data based on incident type
        # APP_* incidents get logs data, others get metrics data
        if incident_type.startswith('APP_'):
            data_payload = {
                'logs_data': extract_logs_data(alarm_data, alarm_name, incident_type)
            }
        else:
            data_payload = {
                'metrics_data': extract_metrics_data(alarm_data)
            }
        
        # Trigger Step Function with create_incident input format
        step_function_payload = {
            'source': 'cloudwatch_alarm',
            'alarm_name': alarm_name,
            'alarm_description': alarm_description,
            'reason': reason,
            'incident_type': incident_type,
            'instance_id': instance_id,
            'timestamp': alarm_data.get('StateChangeTime', datetime.utcnow().isoformat()),
            'metric_name': alarm_data.get('Trigger', {}).get('MetricName', ''),
            'threshold': alarm_data.get('Trigger', {}).get('Threshold', 0),
            'state': 'ALARM'
        }
        
        # Add logs or metrics data based on incident type
        step_function_payload.update(data_payload)
        
        trigger_step_function(step_function_payload)
        
    except Exception as e:
        print(f"Error processing alarm: {str(e)}")
        raise e


def identify_incident_type(alarm_name, subject, description):
    """
    Identify incident type - only allow specific alarm types
    Allowed: CPU_HIGH, MEM_HIGH, APP_CRASH, APP_ERROR, APP_SHUTDOWN
    """
    text = f"{alarm_name} {subject} {description}".upper()
    
    # Only allow these specific incident types
    if 'CPU_HIGH' in text or any(word in text for word in ['CPU', 'PROCESSOR']):
        return 'CPU_HIGH'
    elif 'MEM_HIGH' in text or any(word in text for word in ['MEMORY', 'MEM', 'RAM']):
        return 'MEM_HIGH'
    elif 'APP_CRASH' in text or ('APP' in text and 'CRASH' in text):
        return 'APP_CRASH'
    elif 'APP_ERROR' in text or ('APP' in text and any(word in text for word in ['ERROR', 'EXCEPTION', 'FAIL'])):
        return 'APP_ERROR'
    elif 'APP_SHUTDOWN' in text or ('APP' in text and any(word in text for word in ['SHUTDOWN', 'STOP', 'DOWN'])):
        return 'APP_SHUTDOWN'
    else:
        # If not one of the allowed types, ignore the alarm
        return None


def extract_instance_id(alarm_data):
    """
    Extract instance ID from alarm dimensions
    """
    try:
        dimensions = alarm_data.get('Trigger', {}).get('Dimensions', [])
        
        for dim in dimensions:
            if dim.get('name') in ['InstanceId', 'Instance']:
                return dim.get('value')
        
        return None
    except:
        return None


def extract_metrics_data(alarm_data):
    """
    Extract metrics information from alarm
    """
    try:
        trigger = alarm_data.get('Trigger', {})
        
        metrics_data = {
            'metric_name': trigger.get('MetricName'),
            'namespace': trigger.get('Namespace'),
            'statistic': trigger.get('Statistic'),
            'threshold': trigger.get('Threshold'),
            'comparison_operator': trigger.get('ComparisonOperator'),
            'evaluation_periods': trigger.get('EvaluationPeriods'),
            'period': trigger.get('Period'),
            'dimensions': trigger.get('Dimensions', [])
        }
        
        return {k: v for k, v in metrics_data.items() if v is not None}
        
    except Exception as e:
        print(f"Error extracting metrics: {str(e)}")
        return {}


def extract_logs_data(alarm_data, alarm_name, incident_type):
    """
    Get recent application logs for APP_* incidents
    """
    try:
        logs_client = boto3.client('logs')
        
        # Determine log group based on incident type and alarm name
        log_group_name = None
        
        # Common application log group patterns
        app_log_groups = [
            f"/aws/lambda/{alarm_name.lower()}",
            f"/aws/ecs/{alarm_name.lower()}",
            f"/aws/ec2/application",
            "/var/log/application",
            "/var/log/app.log",
            "/aws/apigateway/execution",
            f"/application/{incident_type.lower()}"
        ]
        
        # Try to find existing log group
        for log_group in app_log_groups:
            try:
                response = logs_client.describe_log_groups(
                    logGroupNamePrefix=log_group.split('/')[:-1] if '/' in log_group else log_group, 
                    limit=1
                )
                if response.get('logGroups'):
                    log_group_name = log_group
                    break
            except:
                continue
        
        if not log_group_name:
            print(f"No log group found for {incident_type}")
            return {
                'error': 'Log group not found',
                'searched_patterns': app_log_groups[:3]
            }
        
        # Get recent log events (last 30 minutes for app issues)
        end_time = int(datetime.utcnow().timestamp() * 1000)
        start_time = end_time - (30 * 60 * 1000)  # 30 minutes ago
        
        response = logs_client.filter_log_events(
            logGroupName=log_group_name,
            startTime=start_time,
            endTime=end_time,
            limit=100,
            filterPattern='ERROR EXCEPTION FAIL CRASH'  # Focus on error logs
        )
        
        events = response.get('events', [])
        if events:
            return {
                'log_group': log_group_name,
                'total_events': len(events),
                'error_events': [
                    {
                        'timestamp': event.get('timestamp'),
                        'message': event.get('message', '')[:1000]  # Limit message length
                    }
                    for event in events[-20:]  # Last 20 error events
                ],
                'time_range': {
                    'start': datetime.fromtimestamp(start_time/1000).isoformat(),
                    'end': datetime.fromtimestamp(end_time/1000).isoformat()
                }
            }
        
        return {
            'log_group': log_group_name,
            'message': 'No error events found in recent logs'
        }
        
    except Exception as e:
        print(f"Error extracting application logs: {str(e)}")
        return {
            'error': f'Failed to extract logs: {str(e)}'
        }


def trigger_step_function(alarm_payload):
    """
    Trigger Step Function with alarm data
    """
    try:
        stepfunctions = boto3.client('stepfunctions')
        state_machine_arn = os.environ.get('STEP_FUNCTION_ARN')
        
        if not state_machine_arn:
            print("STEP_FUNCTION_ARN not configured")
            return False
        
        # Prepare input for Step Function
        step_function_input = {
            'source': 'cloudwatch_alarm',
            'alarm_data': alarm_payload,
            'incident_type': alarm_payload['incident_type'],
            'instance_id': alarm_payload.get('instance_id'),
            'timestamp': alarm_payload['timestamp']
        }
        
        # Start execution
        execution_name = f"alarm-{alarm_payload['incident_type']}-{int(datetime.utcnow().timestamp())}"
        
        response = stepfunctions.start_execution(
            stateMachineArn=state_machine_arn,
            name=execution_name,
            input=json.dumps(step_function_input)
        )
        
        print(f"Step Function triggered: {response['executionArn']}")
        return True
        
    except ClientError as e:
        print(f"Step Function error: {str(e)}")
        raise e