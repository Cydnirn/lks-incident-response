import json
import boto3
import os
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
sns = boto3.client('sns')

incidents_table = dynamodb.Table(os.environ.get('INCIDENTS_TABLE', 'incidents'))
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')
API_GATEWAY_URL = os.environ.get('API_GATEWAY_URL', 'https://your-api.com')

def lambda_handler(event, context):
    """
    Send incident notification email and return status
    """
    try:
        # Get incident_id from event (from Step Function or direct call)
        incident_id = event.get('incident_id') or event.get('incidentId')
        
        if not incident_id:
            raise ValueError("incident_id is required")
        
        print(f"Sending notification for incident: {incident_id}")
        
        # Get incident from DynamoDB
        response = incidents_table.get_item(Key={'id': incident_id})
        if 'Item' not in response:
            raise Exception(f"Incident {incident_id} not found")
        
        incident = response['Item']
        
        # Generate email content
        email_content = generate_email_content(incident)
        
        # Send email notification
        notification_result = send_email_notification(incident, email_content)
        
        # Update incident with email status
        incidents_table.update_item(
            Key={'id': incident_id},
            UpdateExpression='SET emailSent = :sent, emailSentAt = :sentAt',
            ExpressionAttributeValues={
                ':sent': True,
                ':sentAt': datetime.utcnow().isoformat()
            }
        )
        
        print(f"Successfully sent notification for incident: {incident_id}")
        
        # Return status for Step Function
        return {
            'statusCode': 200,
            'incident_id': incident_id,
            'emailSent': True,
            'emailSentAt': datetime.utcnow().isoformat(),
            'messageId': notification_result.get('messageId'),
            'subject': email_content['subject'],
            'notificationStatus': 'success',
            'timestamp': datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        print(f"Error sending notification: {str(e)}")
        
        # Try to update incident with failure status
        try:
            if 'incident_id' in locals():
                incidents_table.update_item(
                    Key={'id': incident_id},
                    UpdateExpression='SET emailSent = :sent, actionTaken = :action',
                    ExpressionAttributeValues={
                        ':sent': False,
                        ':action': f'Failed to send notification: {str(e)}'
                    }
                )
        except:
            pass
        
        # Return error status for Step Function
        return {
            'statusCode': 500,
            'incident_id': event.get('incident_id') or event.get('incidentId', 'unknown'),
            'emailSent': False,
            'notificationStatus': 'failed',
            'error': str(e),
            'timestamp': datetime.utcnow().isoformat()
        }


def generate_email_content(incident):
    """Generate email content with simplified format"""
    
    # Generate action URLs
    auto_url = f"{API_GATEWAY_URL}/action?id={incident['id']}&action=auto"
    manual_url = f"{API_GATEWAY_URL}/action?id={incident['id']}&action=manual"
    
    # Severity emoji mapping
    severity_emojis = {
        'critical': '🔥',
        'high': '🚨',
        'medium': '⚠️',
        'low': '💡'
    }
    
    severity_emoji = severity_emojis.get(incident['severity'], '⚠️')
    
    # Format affected services
    affected_services = incident.get('affectedServices', [])
    services_text = ', '.join(affected_services) if affected_services else 'Unknown'
    
    # Format suggestions
    suggestions = incident.get('suggestions', [])
    suggestions_text = ''
    if suggestions:
        suggestions_text = '\n'.join([f"• {suggestion}" for suggestion in suggestions[:5]])
    else:
        suggestions_text = 'No automated suggestions available'
    
    # Create email subject
    subject = f"{severity_emoji} [{incident['severity'].upper()}] {incident['title']} - {incident['environment'].upper()}"
    
    # Create email body
    email_body = f"""
{severity_emoji} INCIDENT ALERT: {incident['title']}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 INCIDENT DETAILS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

• Incident ID: {incident['id']}
• Type: {incident['insident_type']}
• Severity: {incident['severity'].upper()}
• Environment: {incident['environment'].upper()}
• Instance: {incident.get('instance_id', 'N/A')}
• Created: {incident.get('createdAt', 'Unknown')}
• Affected Services: {services_text}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 DESCRIPTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{incident.get('description', 'No description available')}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 ANALYSIS REPORT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{incident.get('report', 'Report generation in progress...')}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 SUGGESTED ACTIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{suggestions_text}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚡ ACTION REQUIRED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Choose how to handle this incident:

🤖 AUTO HEAL (Automated Resolution):
{auto_url}

👤 MANUAL HANDLING (DevOps Intervention):
{manual_url}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This is an automated notification from the Incident Response System.
Incident ID: {incident['id']}
Generated at: {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')}
    """.strip()
    
    return {
        'subject': subject,
        'body': email_body
    }


def send_email_notification(incident, email_content):
    """Send email notification via SNS"""
    
    try:
        if not SNS_TOPIC_ARN:
            print("SNS_TOPIC_ARN not configured, skipping notification")
            return {'messageId': 'not-configured', 'status': 'skipped'}
        
        # Send to SNS topic
        response = sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Message=email_content['body'],
            Subject=email_content['subject'],
            MessageAttributes={
                'incident_id': {
                    'DataType': 'String',
                    'StringValue': incident['id']
                },
                'severity': {
                    'DataType': 'String',
                    'StringValue': incident['severity']
                },
                'incident_type': {
                    'DataType': 'String',
                    'StringValue': incident['insident_type']
                },
                'environment': {
                    'DataType': 'String',
                    'StringValue': incident['environment']
                },
                'notification_type': {
                    'DataType': 'String',
                    'StringValue': 'incident_alert'
                }
            }
        )
        
        message_id = response['MessageId']
        print(f"SNS notification sent successfully. MessageId: {message_id}")
        
        # Optionally store email content for audit trail
        store_email_audit(incident['id'], email_content)
        
        return {
            'messageId': message_id,
            'status': 'sent',
            'topicArn': SNS_TOPIC_ARN
        }
        
    except Exception as e:
        print(f"Error sending SNS notification: {str(e)}")
        raise e


def store_email_audit(incident_id, email_content):
    """Store email content for audit trail (optional)"""
    try:
        # Only store if S3 bucket is configured
        bucket_name = os.environ.get('EMAIL_ARCHIVE_BUCKET')
        if not bucket_name:
            return
        
        s3 = boto3.client('s3')
        timestamp = datetime.utcnow().isoformat()
        
        # Store email audit
        audit_data = {
            'incident_id': incident_id,
            'subject': email_content['subject'],
            'body': email_content['body'],
            'sent_at': timestamp
        }
        
        s3.put_object(
            Bucket=bucket_name,
            Key=f"notifications/{incident_id}/{timestamp}.json",
            Body=json.dumps(audit_data, indent=2),
            ContentType='application/json'
        )
        
        print(f"Email audit stored for incident: {incident_id}")
        
    except Exception as e:
        print(f"Failed to store email audit: {str(e)}")
        # Don't fail the notification if audit storage fails