import json
import boto3
import requests
import os
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
incidents_table = dynamodb.Table(os.environ.get('INCIDENTS_TABLE', 'incidents'))

OLLAMA_ENDPOINT = os.environ.get('OLLAMA_ENDPOINT')
OLLAMA_MODEL = os.environ.get('OLLAMA_MODEL', 'phi4-mini')

def lambda_handler(event, context):
    """
    Generate incident report using Ollama LLM and return results
    """
    try:
        # Get incident_id from event (from Step Function or direct call)
        incident_id = event.get('incident_id') or event.get('incidentId')
        
        if not incident_id:
            raise ValueError("incident_id is required")
        
        print(f"Generating report for incident: {incident_id}")
        
        # Get incident from DynamoDB
        response = incidents_table.get_item(Key={'id': incident_id})
        if 'Item' not in response:
            raise Exception(f"Incident {incident_id} not found")
        
        incident = response['Item']
        
        # Generate report using Ollama
        report_data = generate_incident_report(incident)
        
        # Update incident with report
        incidents_table.update_item(
            Key={'id': incident_id},
            UpdateExpression='SET report = :report, suggestions = :suggestions',
            ExpressionAttributeValues={
                ':report': report_data['report'],
                ':suggestions': report_data['suggestions']
            }
        )
        
        print(f"Generated report for incident: {incident_id}")
        
        # Return results for Step Function
        return {
            'statusCode': 200,
            'incident_id': incident_id,
            'report': report_data['report'],
            'suggestions': report_data['suggestions'],
            'reportGenerated': True,
            'timestamp': datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        print(f"Error generating report: {str(e)}")
        # Return error but don't fail the Step Function
        return {
            'statusCode': 500,
            'incident_id': event.get('incident_id') or event.get('incidentId', 'unknown'),
            'report': f"Failed to generate report: {str(e)}",
            'suggestions': ["Manual investigation required", "Check system logs", "Contact DevOps team"],
            'reportGenerated': False,
            'error': str(e)
        }


def generate_incident_report(incident):
    """Generate incident report using Ollama"""
    
    # Prepare context for LLM based on available data
    context = prepare_incident_context(incident)
    
    # Generate report
    report_prompt = f"""
    You are an expert DevOps engineer analyzing a system incident. Generate a concise but comprehensive incident report.

    Incident Details:
    - ID: {incident['id']}
    - Title: {incident['title']}
    - Type: {incident['insident_type']}
    - Severity: {incident['severity']}
    - Environment: {incident['environment']}
    - Instance: {incident.get('instance_id', 'N/A')}
    - Description: {incident['description']}
    - Affected Services: {', '.join(incident.get('affectedServices', []))}
    - Created: {incident.get('createdAt', 'Unknown')}

    Additional Context:
    {context}

    Please provide a structured technical report covering:
    1. **Summary**: Brief overview of the incident
    2. **Technical Analysis**: What happened and why
    3. **Impact Assessment**: Services and users affected
    4. **Root Cause**: Likely cause of the issue

    Keep the report concise but informative. Format as markdown.
    """
    
    suggestions_prompt = f"""
    Based on this {incident['insident_type']} incident in {incident['environment']} environment:
    - Severity: {incident['severity']}
    - Instance: {incident.get('instance_id', 'N/A')}
    - Description: {incident['description']}

    Provide 4-5 specific actionable suggestions for immediate resolution:

    Focus on:
    1. Immediate remediation steps
    2. System stabilization actions
    3. Monitoring/verification steps
    4. Prevention measures

    Return ONLY a simple numbered list without explanations.
    """
    
    # Call Ollama for report
    report = call_ollama(report_prompt)
    
    # Call Ollama for suggestions
    suggestions_text = call_ollama(suggestions_prompt)
    suggestions = parse_suggestions(suggestions_text)
    
    return {
        'report': report,
        'suggestions': suggestions
    }


def prepare_incident_context(incident):
    """Prepare additional context based on incident type and available data"""
    context_parts = []
    
    # Add incident type specific context
    incident_type = incident.get('insident_type', '')
    
    if incident_type == 'CPU_HIGH':
        context_parts.append("""
        **CPU High Utilization Context:**
        - Monitor for sustained vs spike patterns
        - Check for runaway processes or inefficient code
        - Consider CPU-intensive operations or increased load
        - Review auto-scaling policies and thresholds
        """)
    
    elif incident_type == 'MEM_HIGH':
        context_parts.append("""
        **Memory High Utilization Context:**
        - Check for memory leaks in applications
        - Monitor garbage collection performance
        - Review memory allocation patterns
        - Consider container memory limits
        """)
    
    elif incident_type == 'APP_CRASH':
        context_parts.append("""
        **Application Crash Context:**
        - Check application logs for crash signals
        - Review recent deployments or changes
        - Look for resource exhaustion (OOM killer)
        - Analyze crash dumps if available
        """)
    
    elif incident_type == 'APP_SHUTDOWN':
        context_parts.append("""
        **Application Shutdown Context:**
        - Determine if shutdown was graceful or forced
        - Check for system-level shutdown signals
        - Review process health checks and dependencies
        - Look for resource constraints causing shutdown
        """)
    
    elif incident_type == 'APP_ERROR':
        context_parts.append("""
        **Application Error Context:**
        - Review error logs and stack traces
        - Check external dependencies (DB, APIs, services)
        - Analyze error patterns and frequency
        - Consider configuration or deployment issues
        """)
    
    # Add environment specific context
    if incident.get('environment') == 'production':
        context_parts.append("**Production Environment**: Prioritize fast resolution to minimize user impact.")
    
    # Add severity specific context
    if incident.get('severity') in ['critical', 'high']:
        context_parts.append("**High Priority**: This incident requires immediate attention and escalation.")
    
    return "\n".join(context_parts)


def call_ollama(prompt):
    """Call Ollama API for text generation"""
    try:
        if not OLLAMA_ENDPOINT:
            print("OLLAMA_ENDPOINT not configured, using fallback")
            return generate_fallback_response(prompt)
        
        payload = {
            "model": OLLAMA_MODEL,
            "prompt": prompt,
            "stream": False,
            "options": {
                "temperature": 0.3,
                "top_p": 0.9,
                "max_tokens": 800
            }
        }
        
        response = requests.post(
            f"{OLLAMA_ENDPOINT}/api/generate",
            json=payload,
            timeout=120,
            headers={'Content-Type': 'application/json'}
        )
        
        if response.status_code == 200:
            result = response.json()
            return result.get('response', '').strip()
        else:
            print(f"Ollama API error: {response.status_code} - {response.text}")
            return generate_fallback_response(prompt)
            
    except requests.exceptions.RequestException as e:
        print(f"Error calling Ollama: {str(e)}")
        return generate_fallback_response(prompt)


def generate_fallback_response(prompt):
    """Generate fallback response if Ollama is unavailable"""
    if "suggestions" in prompt.lower() or "actionable" in prompt.lower():
        return """
        1. Check system logs and metrics immediately
        2. Restart affected services if safe to do so
        3. Scale resources if utilization is high
        4. Verify system health after actions
        5. Document findings for post-incident review
        """
    else:
        return """
        ## Incident Report

        **Summary**: Automated incident detected requiring investigation.

        **Technical Analysis**: System monitoring detected an anomaly that triggered this incident. Manual investigation is required to determine the exact cause and impact.

        **Impact Assessment**: Potentially affecting system performance and user experience. Impact scope needs manual verification.

        **Root Cause**: To be determined through manual investigation of logs, metrics, and system status.

        **Status**: Awaiting manual analysis and resolution.
        """


def parse_suggestions(suggestions_text):
    """Parse suggestions text into list"""
    suggestions = []
    lines = suggestions_text.split('\n')
    
    for line in lines:
        line = line.strip()
        # Match numbered lists, bullet points, or dashes
        if line and (line[0].isdigit() or line.startswith('-') or line.startswith('•') or line.startswith('*')):
            # Remove numbering and bullet points
            suggestion = line.lstrip('0123456789.-•* ').strip()
            if suggestion and len(suggestion) > 10:  # Avoid very short suggestions
                suggestions.append(suggestion)
    
    # Fallback if parsing fails
    if not suggestions and suggestions_text.strip():
        # Try to split by sentences or periods
        sentences = [s.strip() for s in suggestions_text.split('.') if s.strip()]
        if sentences:
            suggestions = sentences[:5]
        else:
            suggestions = [suggestions_text.strip()]
    
    # Ensure we have at least some suggestions
    if not suggestions:
        suggestions = [
            "Investigate system logs for error patterns",
            "Check resource utilization and system health",
            "Verify service dependencies and connectivity",
            "Consider restarting affected services",
            "Monitor system after resolution attempts"
        ]
    
    return suggestions[:5]  # Limit to 5 suggestions