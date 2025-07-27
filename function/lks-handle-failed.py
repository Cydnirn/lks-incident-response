import json
import boto3
import os
from datetime import datetime
from botocore.exceptions import ClientError

def notif_error_handler(event, context):
    """
    Handle notification error - update incident status and send SNS notification
    
    Input event structure:
    {
        "incident_id": "INC-2025-001",
        "instance_id": "i-1234567890abcdef0", 
        "insident_type": "CPU_HIGH",
        "status": "error",
        "report": "Service restart failed after instance resize",
        "severity": "high"
    }
    """
    
    try:
        # Extract data from event
        incident_id = event.get('incident_id')
        instance_id = event.get('instance_id')
        insident_type = event.get('insident_type', 'OTHER')  # Changed to match schema
        status = event.get('status', 'unknown')
        report = event.get('report', 'An error occurred during auto resolution')
        severity = event.get('severity', 'medium')  # Default to valid severity
        
        if not incident_id:
            raise ValueError("incident_id is required")
        
        print(f"Processing notification error for incident: {incident_id}")
        
        # Update DynamoDB incident status
        update_result = update_incident_status(
            incident_id, 
            instance_id, 
            insident_type, 
            report, 
            severity
        )
        
        # Send SNS notification
        sns_result = send_sns_notification(
            incident_id, 
            instance_id, 
            insident_type, 
            report,
            severity
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Notification error processed successfully',
                'incident_id': incident_id,
                'instance_id': instance_id,
                'status_updated': update_result,
                'notification_sent': sns_result,
                'timestamp': datetime.utcnow().isoformat()
            })
        }
        
    except Exception as e:
        print(f"Error processing notification: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': f'Failed to process notification error: {str(e)}',
                'incident_id': event.get('incident_id', 'unknown')
            })
        }


def update_incident_status(incident_id, instance_id, insident_type, error_message, severity):
    """
    Update incident status to pending with manual action required
    """
    try:
        dynamodb = boto3.resource('dynamodb')
        table_name = os.environ.get('INCIDENT_TABLE', 'incident')
        table = dynamodb.Table(table_name)
        
        current_time = datetime.utcnow().isoformat()
        
        # Update incident with error details - matching the schema
        response = table.update_item(
            Key={'id': incident_id},
            UpdateExpression='''SET 
                #status = :status, 
                actionStatus = :action_status,
                report = :report,
                severity = :severity,
                insident_type = :insident_type,
                actionTaken = :action_taken,
                emailSent = :email_sent,
                emailSentAt = :email_sent_at,
                resolutionTime = :resolution_time
            ''',
            ExpressionAttributeNames={
                '#status': 'status'
            },
            ExpressionAttributeValues={
                ':status': 'pending',
                ':action_status': 'manual',
                ':report': error_message,
                ':severity': severity,
                ':insident_type': insident_type,
                ':action_taken': f'Auto resolution failed: {error_message}',
                ':email_sent': True,
                ':email_sent_at': current_time,
                ':resolution_time': current_time
            },
            ReturnValues='UPDATED_NEW'
        )
        
        print(f"Successfully updated incident {incident_id} status to pending/manual")
        return True
        
    except ClientError as e:
        print(f"DynamoDB error updating incident {incident_id}: {str(e)}")
        raise e


def send_sns_notification(incident_id, instance_id, insident_type, report, severity):
    """
    Send SNS notification about manual intervention requirement
    """
    try:
        sns = boto3.client('sns')
        topic_arn = os.environ.get('SNS_TOPIC_ARN')
        
        if not topic_arn:
            print("SNS_TOPIC_ARN not configured, skipping notification")
            return False
        
        # Map severity for display
        severity_emoji = {
            'critical': '🔥',
            'high': '🚨',
            'medium': '⚠️',
            'low': '💡'
        }
        
        # Map incident type for display
        incident_type_display = {
            'CPU_HIGH': 'High CPU Usage',
            'MEM_HIGH': 'High Memory Usage',
            'POD_CRASH': 'Pod Crash',
            'IMAGE_PULL': 'Image Pull Error',
            'UNHEALTHY_POD': 'Unhealthy Pod',
            'APP_ERROR': 'Application Error',
            'OTHER': 'Other Issue'
        }
        
        # Create notification message
        notification_subject = f"{severity_emoji.get(severity, '⚠️')} Manual Intervention Required - Incident {incident_id}"
        
        # Build detailed message
        message_parts = [
            f"INCIDENT ALERT: Auto-resolution failed for incident {incident_id}",
            "",
            "📋 INCIDENT DETAILS:",
            f"• Incident ID: {incident_id}",
            f"• Instance ID: {instance_id or 'N/A'}",
            f"• Incident Type: {incident_type_display.get(insident_type, insident_type)}",
            f"• Severity: {severity.upper()}",
            f"• Report: {report}",
            f"• Timestamp: {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')}",
            "",
            "⚠️ ACTION REQUIRED:",
            "The automated incident resolution process has failed and requires manual intervention.",
            "",
            "🔧 NEXT STEPS:",
            "1. Review the incident details above",
            "2. Investigate the root cause of the failure", 
            "3. Take appropriate manual remediation actions",
            "4. Update incident status when resolved",
            "",
            "📊 CURRENT STATUS:",
            f"• Status: PENDING",
            f"• Action Status: MANUAL",
            f"• Email Notification: SENT",
            "",
            "⏰ This incident requires immediate attention to ensure system stability."
        ]
        
        notification_message = "\n".join(message_parts)
        
        # Send SNS notification
        response = sns.publish(
            TopicArn=topic_arn,
            Subject=notification_subject,
            Message=notification_message,
            MessageAttributes={
                'incident_id': {
                    'DataType': 'String',
                    'StringValue': incident_id
                },
                'severity': {
                    'DataType': 'String', 
                    'StringValue': severity
                },
                'insident_type': {
                    'DataType': 'String',
                    'StringValue': insident_type
                },
                'alert_type': {
                    'DataType': 'String',
                    'StringValue': 'manual_intervention_required'
                }
            }
        )
        
        message_id = response['MessageId']
        print(f"SNS notification sent successfully. MessageId: {message_id}")
        
        return True
        
    except ClientError as e:
        print(f"SNS error: {str(e)}")
        raise e


def step_function_error_callback(event, context):
    """
    Callback dari Step Function ketika execution gagal
    Input dari Step Function error state
    """
    try:
        print(f"Step Function error callback received: {json.dumps(event)}")
        
        # Extract information from Step Function error
        incident_id = event.get('incident_id')
        instance_id = event.get('instance_id')
        
        # Get error details from Step Function
        error_info = event.get('Error', {})
        error_cause = event.get('Cause', {})
        
        # Parse cause if it's a JSON string
        if isinstance(error_cause, str):
            try:
                error_cause = json.loads(error_cause)
            except:
                pass
        
        # Determine error type and message
        insident_type = event.get('insident_type', 'OTHER')  # Use from event or default
        report = error_cause.get('errorMessage', 'Step Function execution failed')
        severity = event.get('severity', 'high')  # Default to high for step function errors
        
        # Validate severity value
        valid_severities = ['critical', 'high', 'medium', 'low']
        if severity not in valid_severities:
            severity = 'high'
            
        # Validate incident type
        valid_incident_types = ['CPU_HIGH', 'MEM_HIGH', 'POD_CRASH', 'IMAGE_PULL', 'UNHEALTHY_POD', 'APP_ERROR', 'OTHER']
        if insident_type not in valid_incident_types:
            insident_type = 'OTHER'
        
        # Prepare notification event
        notification_event = {
            'incident_id': incident_id,
            'instance_id': instance_id,
            'insident_type': insident_type,
            'status': 'error',
            'report': report,
            'severity': severity
        }
        
        # Call the main notification error handler
        return notif_error_handler(notification_event, context)
        
    except Exception as e:
        print(f"Error in Step Function error callback: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': f'Failed to process Step Function error: {str(e)}'
            })
        }