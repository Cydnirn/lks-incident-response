import json
import boto3
import os
from datetime import datetime
from botocore.exceptions import ClientError

def notif_success_handler(event, context):
    """
    Handle successful incident resolution - update incident status and send notifications
    
    Input event structure:
    {
        "incident_id": "INC-2025-001",
        "instance_id": "i-1234567890abcdef0", 
        "insident_type": "CPU_HIGH",
        "status": "success",
        "report": "Service restarted successfully",
        "severity": "high"
    }
    """
    
    try:
        # Extract data from event
        incident_id = event.get('incident_id')
        instance_id = event.get('instance_id')
        insident_type = event.get('insident_type', 'OTHER')
        report = event.get('report', 'Incident resolved successfully')
        severity = event.get('severity', 'medium')
        
        if not incident_id:
            raise ValueError("incident_id is required")
        
        print(f"Processing successful resolution for incident: {incident_id}")
        
        # Update DynamoDB incident status
        update_incident_status(incident_id, report)
        
        # Send SNS notification
        send_success_notification(incident_id, instance_id, insident_type, report, severity)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Incident resolved successfully',
                'incident_id': incident_id,
                'status': 'solved'
            })
        }
        
    except Exception as e:
        print(f"Error processing success notification: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': f'Failed to process success notification: {str(e)}',
                'incident_id': event.get('incident_id', 'unknown')
            })
        }


def update_incident_status(incident_id, report):
    """
    Update incident status to solved
    """
    try:
        dynamodb = boto3.resource('dynamodb')
        table_name = os.environ.get('INCIDENT_TABLE', 'incident')
        table = dynamodb.Table(table_name)
        
        current_time = datetime.utcnow().isoformat()
        
        # Update incident to solved status
        table.update_item(
            Key={'id': incident_id},
            UpdateExpression='''SET 
                #status = :status, 
                actionStatus = :action_status,
                report = :report,
                actionTaken = :action_taken,
                emailSent = :email_sent,
                emailSentAt = :email_sent_at,
                resolutionTime = :resolution_time
            ''',
            ExpressionAttributeNames={
                '#status': 'status'
            },
            ExpressionAttributeValues={
                ':status': 'solved',
                ':action_status': 'auto',
                ':report': report,
                ':action_taken': f'Auto resolution completed: {report}',
                ':email_sent': True,
                ':email_sent_at': current_time,
                ':resolution_time': current_time
            }
        )
        
        print(f"Updated incident {incident_id} to solved status")
        
    except ClientError as e:
        print(f"DynamoDB error: {str(e)}")
        raise e


def send_success_notification(incident_id, instance_id, insident_type, report, severity):
    """
    Send SNS notification and email about successful resolution
    """
    try:
        sns = boto3.client('sns')
        topic_arn = os.environ.get('SNS_TOPIC_ARN')
        
        if not topic_arn:
            print("SNS_TOPIC_ARN not configured")
            return False
        
        # Create success message
        subject = f"✅ Incident Resolved - {incident_id}"
        
        message = f"""
INCIDENT RESOLVED SUCCESSFULLY

Incident ID: {incident_id}
Instance ID: {instance_id or 'N/A'}
Type: {insident_type}
Severity: {severity}
Status: SOLVED

Resolution Details:
{report}

Resolved at: {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')}

This incident has been automatically resolved by the system.
        """.strip()
        
        # Send to SNS topic (includes email subscribers)
        response = sns.publish(
            TopicArn=topic_arn,
            Subject=subject,
            Message=message,
            MessageAttributes={
                'incident_id': {
                    'DataType': 'String',
                    'StringValue': incident_id
                },
                'alert_type': {
                    'DataType': 'String',
                    'StringValue': 'incident_resolved'
                }
            }
        )
        
        print(f"Success notification sent. MessageId: {response['MessageId']}")
        return True
        
    except ClientError as e:
        print(f"SNS error: {str(e)}")
        raise e