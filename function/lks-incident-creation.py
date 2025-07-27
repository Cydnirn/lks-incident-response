import json
import boto3
import uuid
from datetime import datetime
import os

dynamodb = boto3.resource('dynamodb')
incidents_table = dynamodb.Table(os.environ['INCIDENTS_TABLE'])

def lambda_handler(event, context):
    """
    Creates incident from CloudWatch alarm event with metrics/logs data
    """
    try:
        print(f"Received event: {json.dumps(event)}")
        
        # Parse CloudWatch event (from Step Function or direct)
        if event.get('source') == 'cloudwatch_alarm':
            alarm_data = parse_stepfunction_event(event)
        else:
            alarm_data = parse_cloudwatch_event(event)
        
        # Determine incident properties
        incident_type = alarm_data.get('incident_type') or determine_incident_type(alarm_data['alarm_name'], alarm_data['metric_name'])
        severity = determine_severity(incident_type, alarm_data['threshold'])
        affected_services = determine_affected_services(alarm_data['instance_id'])
        environment = determine_environment(alarm_data['instance_id'])
        
        # Create incident record
        incident_id = f"INC-{datetime.utcnow().strftime('%Y%m%d')}-{str(uuid.uuid4())[:8].upper()}"
        
        incident = {
            'id': incident_id,
            'instance_id': alarm_data['instance_id'],
            'title': generate_title(incident_type, alarm_data['alarm_name']),
            'description': alarm_data['reason'],
            'report': generate_initial_report(alarm_data, incident_type),
            'severity': severity,
            'category': determine_category(incident_type),
            'insident_type': incident_type,
            'environment': environment,
            'actionStatus': 'auto',
            'status': 'open',
            'reporter': 'cloudwatch-alarm',
            'createdAt': datetime.utcnow().isoformat(),
            'emailSent': False,
            'affectedServices': affected_services,
            'tags': generate_tags(incident_type, environment)
        }
        
        # Add suggestions based on incident type and data
        incident['suggestions'] = generate_suggestions(incident_type, alarm_data)
        
        # Save to DynamoDB
        response = incidents_table.put_item(Item=incident)
        
        print(f"Created incident: {incident_id}")
        
        # Return data for next step in Step Function
        return {
            'statusCode': 200,
            'incident_id': incident_id,
            'instance_id': alarm_data['instance_id'],
            'incident_type': incident_type,
            'severity': severity,
            'environment': environment,
            'alarm_data': alarm_data,
            'incident': incident
        }
        
    except Exception as e:
        print(f"Error creating incident: {str(e)}")
        raise e


def parse_stepfunction_event(event):
    """Parse event from Step Function (CloudWatch alarm handler)"""
    return {
        'alarm_name': event.get('alarm_name', 'unknown'),
        'reason': event.get('reason', 'Alarm triggered'),
        'metric_name': event.get('metric_name', ''),
        'threshold': event.get('threshold', 0),
        'instance_id': event.get('instance_id', 'unknown'),
        'state': event.get('state', 'ALARM'),
        'incident_type': event.get('incident_type'),
        'metrics_data': event.get('metrics_data', {}),
        'logs_data': event.get('logs_data', {}),
        'timestamp': event.get('timestamp', datetime.utcnow().isoformat())
    }


def parse_cloudwatch_event(event):
    """Parse CloudWatch alarm event (legacy support)"""
    if 'source' in event and event['source'] == 'aws.cloudwatch':
        detail = event['detail']
        return {
            'alarm_name': detail['alarmName'],
            'reason': detail['reason'],
            'metric_name': detail.get('metricName', ''),
            'threshold': detail.get('threshold', 0),
            'instance_id': extract_instance_id(detail.get('dimensions', {})),
            'state': detail['state']['value'],
            'metrics_data': {},
            'logs_data': {}
        }
    else:
        # Handle direct invocation for testing
        return {
            'alarm_name': event.get('alarm_name', 'test-alarm'),
            'reason': event.get('reason', 'Test incident'),
            'metric_name': event.get('metric_name', 'CPUUtilization'),
            'threshold': event.get('threshold', 70),
            'instance_id': event.get('instance_id', 'i-1234567890abcdef0'),
            'state': 'ALARM',
            'metrics_data': {},
            'logs_data': {}
        }


def extract_instance_id(dimensions):
    """Extract instance ID from CloudWatch dimensions"""
    for dimension in dimensions:
        if dimension['name'] == 'InstanceId':
            return dimension['value']
    return 'unknown'


def determine_incident_type(alarm_name, metric_name):
    """Determine incident type from alarm name and metric"""
    alarm_lower = alarm_name.lower()
    metric_lower = metric_name.lower()
    
    if 'cpu_high' in alarm_lower or 'cpu' in metric_lower:
        return 'CPU_HIGH'
    elif 'mem_high' in alarm_lower or 'memory' in alarm_lower or 'mem' in metric_lower:
        return 'MEM_HIGH'
    elif 'app_crash' in alarm_lower or 'crash' in alarm_lower:
        return 'APP_CRASH'
    elif 'app_shutdown' in alarm_lower or 'shutdown' in alarm_lower:
        return 'APP_SHUTDOWN'
    elif 'app_error' in alarm_lower or 'error' in alarm_lower:
        return 'APP_ERROR'
    else:
        return 'OTHER'


def determine_severity(incident_type, threshold):
    """Determine severity based on incident type and threshold"""
    if incident_type in ['APP_CRASH', 'APP_SHUTDOWN']:
        return 'critical'
    elif incident_type in ['CPU_HIGH', 'MEM_HIGH']:
        if threshold >= 90:
            return 'critical'
        elif threshold >= 70:
            return 'high'
        else:
            return 'medium'
    elif incident_type == 'APP_ERROR':
        return 'high'
    else:
        return 'medium'


def determine_category(incident_type):
    """Determine category based on incident type"""
    if incident_type in ['CPU_HIGH', 'MEM_HIGH']:
        return 'infrastructure'
    elif incident_type in ['APP_CRASH', 'APP_SHUTDOWN', 'APP_ERROR']:
        return 'ci-cd'
    else:
        return 'other'


def determine_affected_services(instance_id):
    """Determine affected services from instance ID"""
    if instance_id == 'unknown':
        return ['unknown-service']
        
    ec2 = boto3.client('ec2')
    try:
        response = ec2.describe_instances(InstanceIds=[instance_id])
        if response['Reservations']:
            tags = response['Reservations'][0]['Instances'][0].get('Tags', [])
            for tag in tags:
                if tag['Key'] == 'Service':
                    return [tag['Value']]
        return [f"service-{instance_id}"]
    except Exception as e:
        print(f"Error getting affected services: {str(e)}")
        return [f"unknown-{instance_id}"]


def determine_environment(instance_id):
    """Determine environment from instance tags"""
    if instance_id == 'unknown':
        return 'production'
        
    ec2 = boto3.client('ec2')
    try:
        response = ec2.describe_instances(InstanceIds=[instance_id])
        if response['Reservations']:
            tags = response['Reservations'][0]['Instances'][0].get('Tags', [])
            for tag in tags:
                if tag['Key'] == 'Environment':
                    return tag['Value'].lower()
    except Exception as e:
        print(f"Error getting environment: {str(e)}")
    return 'production'  # Default to production


def generate_title(incident_type, alarm_name):
    """Generate incident title"""
    titles = {
        'CPU_HIGH': f'High CPU Usage - {alarm_name}',
        'MEM_HIGH': f'High Memory Usage - {alarm_name}',
        'APP_CRASH': f'Application Crash - {alarm_name}',
        'APP_SHUTDOWN': f'Service Shutdown - {alarm_name}',
        'APP_ERROR': f'Application Error - {alarm_name}',
        'OTHER': f'System Alert - {alarm_name}'
    }
    return titles.get(incident_type, f'Incident - {alarm_name}')


def generate_initial_report(alarm_data, incident_type):
    """Generate initial report with available data"""
    report_parts = [f"Incident auto-detected from CloudWatch alarm: {alarm_data['alarm_name']}"]
    
    # Add metrics data for CPU/MEM incidents
    if incident_type in ['CPU_HIGH', 'MEM_HIGH'] and alarm_data.get('metrics_data'):
        metrics = alarm_data['metrics_data']
        report_parts.append(f"Metric: {metrics.get('metric_name', 'Unknown')}")
        report_parts.append(f"Threshold: {metrics.get('threshold', 'Unknown')}")
        report_parts.append(f"Comparison: {metrics.get('comparison_operator', 'Unknown')}")
    
    # Add logs data for APP incidents
    elif incident_type.startswith('APP_') and alarm_data.get('logs_data'):
        logs = alarm_data['logs_data']
        if logs.get('total_events'):
            report_parts.append(f"Found {logs['total_events']} error events in logs")
            if logs.get('error_events'):
                report_parts.append("Recent error samples:")
                for event in logs['error_events'][:3]:  # Show first 3 errors
                    report_parts.append(f"- {event.get('message', '')[:100]}...")
    
    report_parts.append(f"Instance: {alarm_data['instance_id']}")
    report_parts.append(f"Triggered at: {alarm_data.get('timestamp', 'Unknown')}")
    
    return ". ".join(report_parts)


def generate_suggestions(incident_type, alarm_data):
    """Generate suggestions based on incident type and available data"""
    base_suggestions = {
        'CPU_HIGH': [
            'Check running processes consuming high CPU',
            'Scale up instance if needed',
            'Restart application services',
            'Review application performance'
        ],
        'MEM_HIGH': [
            'Check memory usage by processes',
            'Clear application cache',
            'Restart memory-intensive services',
            'Scale up instance memory'
        ],
        'APP_CRASH': [
            'Check application logs for crash reason',
            'Restart crashed application',
            'Check resource limits and dependencies',
            'Review recent deployments'
        ],
        'APP_SHUTDOWN': [
            'Check if shutdown was planned',
            'Restart the application service',
            'Check system resources',
            'Review application health'
        ],
        'APP_ERROR': [
            'Check application logs for error details',
            'Review recent deployments',
            'Check database connectivity',
            'Restart application services'
        ]
    }
    
    suggestions = base_suggestions.get(incident_type, ['Investigate the issue', 'Check system logs'])
    
    # Add data-specific suggestions
    if alarm_data.get('metrics_data'):
        metrics = alarm_data['metrics_data']
        if metrics.get('threshold', 0) > 90:
            suggestions.insert(0, 'URGENT: Threshold exceeded 90% - immediate action required')
    
    if alarm_data.get('logs_data') and alarm_data['logs_data'].get('error_events'):
        suggestions.insert(0, 'Check recent error logs for specific error messages')
    
    return suggestions


def generate_tags(incident_type, environment):
    """Generate tags for incident"""
    tags = [incident_type.lower(), environment, 'cloudwatch-auto']
    
    if incident_type in ['CPU_HIGH', 'MEM_HIGH']:
        tags.extend(['resource', 'performance'])
    elif incident_type in ['APP_CRASH', 'APP_SHUTDOWN']:
        tags.extend(['availability', 'application'])
    elif incident_type == 'APP_ERROR':
        tags.extend(['application', 'error'])
    
    return tags