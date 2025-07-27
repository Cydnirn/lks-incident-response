import json
import boto3
import os
from datetime import datetime
from botocore.exceptions import ClientError

def api_gateway_handler(event, context):
    """
    API Gateway with Lambda Proxy integration for incident handling
    
    Query Parameters:
    - id: incident ID
    - action: 'manual' or 'auto'
    
    Manual: Update DynamoDB status to resolved
    Auto: Trigger Step Function with instance_id from DynamoDB
    """
    
    # CORS headers for Lambda Proxy
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
        'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
        'Content-Type': 'application/json'
    }
    
    try:
        # Print event for debugging
        print(f"Received event: {json.dumps(event)}")
        
        # Handle OPTIONS request for CORS preflight
        if event.get('httpMethod') == 'OPTIONS':
            return {
                'statusCode': 200,
                'headers': headers,
                'body': ''
            }
        
        # Lambda Proxy - get query parameters from API Gateway
        query_params = event.get('queryStringParameters')
        if not query_params:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({
                    'error': 'Missing query parameters'
                })
            }
        
        incident_id = query_params.get('id')
        action = query_params.get('action')
        
        # Validation
        if not incident_id:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({
                    'error': 'Missing required parameter: id'
                })
            }
        
        if action not in ['manual', 'auto']:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({
                    'error': 'Invalid action. Must be "manual" or "auto"'
                })
            }
        
        # Initialize AWS clients
        dynamodb = boto3.resource('dynamodb')
        table_name = os.environ.get('INCIDENT_TABLE', 'incidents')
        table = dynamodb.Table(table_name)
        
        # Get incident from DynamoDB
        try:
            response = table.get_item(Key={'id': incident_id})
            
            if 'Item' not in response:
                return {
                    'statusCode': 404,
                    'headers': headers,
                    'body': json.dumps({
                        'error': f'Incident with id {incident_id} not found'
                    })
                }
            
            incident = response['Item']
            
        except ClientError as e:
            return {
                'statusCode': 500,
                'headers': headers,
                'body': json.dumps({
                    'error': f'DynamoDB error: {str(e)}'
                })
            }
        
        # Handle action
        if action == 'manual':
            return handle_manual_action(table, incident_id, incident, headers)
        else:  # action == 'auto'
            return handle_auto_action(incident_id, incident, headers)
            
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({
                'error': f'Internal server error: {str(e)}'
            })
        }


def handle_manual_action(table, incident_id, incident, headers):
    """
    Handle manual action - update DynamoDB status to resolved
    """
    try:
        current_time = datetime.utcnow().isoformat()
        
        # Update incident status
        table.update_item(
            Key={'id': incident_id},
            UpdateExpression='SET #status = :status, resolved_at = :resolved_at, resolution_type = :resolution_type',
            ExpressionAttributeNames={
                '#status': 'status'
            },
            ExpressionAttributeValues={
                ':status': 'resolved',
                ':resolved_at': current_time,
                ':resolution_type': 'manual'
            }
        )
        
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps('Manual intervention!')
        }
        
    except ClientError as e:
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({
                'error': f'Failed to update incident: {str(e)}'
            })
        }


def handle_auto_action(incident_id, incident, headers):
    """
    Handle auto action - trigger Step Function with instance_id
    """
    try:
        instance_id = incident.get('instance_id')
        
        if not instance_id:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({
                    'error': f'No instance_id found for incident {incident_id}'
                })
            }
        
        # Get Step Function ARN from environment
        step_function_arn = os.environ.get('STEP_FUNCTION_ARN')
        
        if not step_function_arn:
            return {
                'statusCode': 500,
                'headers': headers,
                'body': json.dumps({
                    'error': 'STEP_FUNCTION_ARN environment variable not set'
                })
            }
        
        # Initialize Step Functions client
        stepfunctions = boto3.client('stepfunctions')
        
        # Prepare input for Step Function
        step_function_input = {
            'incident_id': incident_id,
            'instance_id': instance_id,
            'incident_type': incident.get('incident_type', 'unknown'),
            'triggered_by': 'api_gateway',
            'timestamp': datetime.utcnow().isoformat()
        }
        
        # Start Step Function execution
        execution_response = stepfunctions.start_execution(
            stateMachineArn=step_function_arn,
            name=f'incident-{incident_id}-{int(datetime.utcnow().timestamp())}',
            input=json.dumps(step_function_input)
        )
        
        execution_arn = execution_response['executionArn']
        
        # Update incident status to processing
        dynamodb = boto3.resource('dynamodb')
        table_name = os.environ.get('INCIDENT_TABLE', 'incident')
        table = dynamodb.Table(table_name)
        
        current_time = datetime.utcnow().isoformat()
        
        table.update_item(
            Key={'id': incident_id},
            UpdateExpression='SET #status = :status, processing_started_at = :started_at, execution_arn = :execution_arn, resolution_type = :resolution_type',
            ExpressionAttributeNames={
                '#status': 'status'
            },
            ExpressionAttributeValues={
                ':status': 'processing',
                ':started_at': current_time,
                ':execution_arn': execution_arn,
                ':resolution_type': 'auto'
            }
        )
        
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps('Step Function triggered')
        }
        
    except ClientError as e:
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({
                'error': f'Failed to trigger Step Function: {str(e)}'
            })
        }


# Lambda untuk callback dari Step Function (optional)
def step_function_callback_handler(event, context):
    """
    Callback handler dari Step Function untuk update final status
    Input dari Step Function completion
    """
    try:
        incident_id = event.get('incident_id')
        execution_status = event.get('status', 'unknown')
        
        if not incident_id:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Missing incident_id'})
            }
        
        # Update DynamoDB
        dynamodb = boto3.resource('dynamodb')
        table_name = os.environ.get('INCIDENT_TABLE', 'incident')
        table = dynamodb.Table(table_name)
        
        current_time = datetime.utcnow().isoformat()
        
        if execution_status == 'success':
            final_status = 'resolved'
        elif execution_status == 'manual_intervention_required':
            final_status = 'manual_intervention_required'
        else:
            final_status = 'failed'
        
        table.update_item(
            Key={'id': incident_id},
            UpdateExpression='SET #status = :status, completed_at = :completed_at, execution_result = :result',
            ExpressionAttributeNames={
                '#status': 'status'
            },
            ExpressionAttributeValues={
                ':status': final_status,
                ':completed_at': current_time,
                ':result': event
            }
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Incident {incident_id} updated with final status: {final_status}',
                'incident_id': incident_id,
                'final_status': final_status,
                'completed_at': current_time
            })
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }