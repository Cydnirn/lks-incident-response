# Lambda Functions - LKS 2025 Incident Response System

This directory contains AWS Lambda functions that form the core of the Incident Response System (IRS) for the LKS 2025 competition. These functions handle automated incident detection, response, and resolution in a cloud infrastructure environment.

## Overview

The Lambda functions are designed to work together in a serverless architecture to:
- Detect infrastructure incidents through CloudWatch alarms
- Automatically respond to different types of incidents
- Generate incident reports using AI/LLM
- Create vector embeddings for incident analysis and similarity search
- Send notifications and handle manual interventions
- Track incident lifecycle and resolution

## Function Categories

### 1. Incident Detection & Creation
- **lks-cloudwatch-alarm.py** - Processes CloudWatch alarms and identifies incident types
- **lks-incident-creation.py** - Creates incidents from CloudWatch alarm events
- **lks-incident-report.py** - Generates AI-powered incident reports
- **lks-incident-notification-button.py** - Sends email notifications with action buttons

### 2. AI/ML & Analytics
- **lks-vector-embeding.py** - Creates vector embeddings for solved incidents for similarity search and analysis

### 3. Incident Response Handlers
- **lks-handle-cpu.py** - Handles high CPU incidents by resizing instances
- **lks-handle-mem.py** - Handles high memory incidents by resizing instances
- **lks-handle-crash.py** - Handles service crashes by restarting services
- **lks-handle-shutdown.py** - Handles shutdown incidents by restarting services
- **lks-handle-error.py** - Handles unknown incidents requiring manual intervention

### 4. API Gateway & Actions
- **lks-apigw-mail-action.py** - API Gateway handler for manual/auto incident actions

### 5. Success & Failure Handlers
- **lks-handle-success.py** - Handles successful incident resolutions
- **lks-handle-failed.py** - Handles failed incident resolutions

## Function Details

| Function Name | Input | Output | Environment Variables | Description |
|---------------|-------|--------|----------------------|-------------|
| **lks-cloudwatch-alarm.py** | SNS event with CloudWatch alarm data | `{statusCode: 200/500, body: string}` | `STEP_FUNCTION_ARN` | Processes CloudWatch alarms via SNS, identifies incident types, extracts instance and metrics data, and triggers Step Function for incident creation. |
| **lks-incident-creation.py** | CloudWatch alarm event or test event with `alarm_name`, `reason`, `metric_name`, `threshold`, `instance_id` | `{statusCode: 200, incidentId: string, incident: object}` | `INCIDENTS_TABLE` | Creates incident records in DynamoDB from CloudWatch alarm events. Determines incident type, severity, and affected services automatically. |
| **lks-incident-report.py** | `{incidentId: string}` | `{statusCode: 200, incidentId: string, reportGenerated: boolean}` | `INCIDENTS_TABLE`, `OLLAMA_ENDPOINT`, `OLLAMA_MODEL` | Generates comprehensive incident reports using Ollama LLM. Analyzes incident details and provides technical analysis, root cause analysis, and actionable suggestions. |
| **lks-incident-notification-button.py** | `{incidentId: string}` | `{statusCode: 200, incidentId: string, emailSent: boolean}` | `INCIDENTS_TABLE`, `SNS_TOPIC_ARN`, `API_GATEWAY_URL` | Sends HTML email notifications with action buttons for manual or automatic incident resolution. Includes incident details, severity indicators, and direct action links. |
| **lks-vector-embeding.py** | Kinesis event with incident data or direct incident object | `{statusCode: 200/500, body: string}` | `OLLAMA_ENDPOINT`, `OLLAMA_MODEL`, `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` | Creates vector embeddings for solved/closed incidents using Ollama LLM. Stores embeddings in PostgreSQL with pgvector extension for similarity search and incident analysis. |
| **lks-apigw-mail-action.py** | API Gateway event with query params `id` and `action` | `{statusCode: 200/400/404/500, headers: object, body: string}` | `INCIDENT_TABLE`, `STEP_FUNCTION_ARN` | API Gateway handler that processes manual/auto action requests. For manual actions, updates incident status to resolved. For auto actions, triggers Step Function with instance details. |
| **lks-handle-cpu.py** | `{instance_id: string, incident_id: string, incident_type?: string}` | `{instance_id: string, incident_id: string, status: string, old_instance_type?: string, new_instance_type?: string, was_running?: boolean, error?: string}` | None | Resizes EC2 instances to handle high CPU utilization. Stops instance, modifies instance type to m5.large, and restarts if it was running. |
| **lks-handle-mem.py** | `{instance_id: string, incident_id: string, incident_type?: string}` | `{instance_id: string, incident_id: string, status: string, old_instance_type?: string, new_instance_type?: string, was_running?: boolean, error?: string}` | `PRIVATE_KEY`, `SSH_USER`, `SERVICE_NAME` | Resizes EC2 instances to handle high memory utilization. Stops instance, modifies instance type to m5.large, and restarts if it was running. |
| **lks-handle-crash.py** | `{instance_id: string, incident_id: string}` | `{instance_id: string, incident_id: string, status: string, service_status?: string, error?: string}` | `PRIVATE_KEY`, `SSH_USER`, `SERVICE_NAME` | Restarts crashed services via SSH connection. Connects to EC2 instance using private key, checks service status, and restarts the specified service (default: loadsim). |
| **lks-handle-shutdown.py** | `{instance_id: string, incident_id: string, incident_type?: string}` | `{instance_id: string, incident_id: string, status: string, service_status?: string, error?: string}` | `PRIVATE_KEY`, `SSH_USER`, `SERVICE_NAME` | Restarts services after shutdown incidents via SSH connection. Similar to crash handler but specifically for shutdown-related incidents. |
| **lks-handle-error.py** | `{instance_id: string, incident_id?: string, incident_type?: string}` | `{instance_id: string, incident_id: string, incident_type: string, status: string, report: string, severity: string}` | None | Handles unknown or unclassified incidents by returning an error status indicating manual intervention is required. Used as a fallback for incident types that cannot be automatically resolved. |
| **lks-handle-success.py** | `{incident_id: string, instance_id?: string, insident_type?: string, status?: string, report?: string, severity?: string}` | `{statusCode: 200/500, body: string}` | `INCIDENT_TABLE`, `SNS_TOPIC_ARN` | Processes successful incident resolutions. Updates incident status to 'solved' in DynamoDB and sends SNS notification about successful resolution. |
| **lks-handle-failed.py** | `{incident_id: string, instance_id?: string, insident_type?: string, status?: string, report?: string, severity?: string}` | `{statusCode: 200/500, body: string}` | `INCIDENT_TABLE`, `SNS_TOPIC_ARN` | Processes failed incident resolutions. Updates incident status to 'pending' with manual action required and sends SNS notification about the failure. |

## Environment Variables

### Common Variables
- `INCIDENTS_TABLE` / `INCIDENT_TABLE` - DynamoDB table name for storing incidents
- `SNS_TOPIC_ARN` - SNS topic ARN for sending notifications

### LLM Integration
- `OLLAMA_ENDPOINT` - Endpoint URL for Ollama LLM service
- `OLLAMA_MODEL` - Model name to use for report generation (default: phi4-mini)

### Database Access
- `DB_HOST` - PostgreSQL database host
- `DB_PORT` - PostgreSQL database port (default: 5432)
- `DB_NAME` - PostgreSQL database name (default: incidents)
- `DB_USER` - PostgreSQL database username
- `DB_PASSWORD` - PostgreSQL database password

### SSH Access
- `PRIVATE_KEY` - Base64 encoded private key for SSH access to EC2 instances
- `SSH_USER` - SSH username (default: ubuntu)
- `SERVICE_NAME` - Service name to restart (default: loadsim)

### API Gateway & Step Functions
- `API_GATEWAY_URL` - Base URL for API Gateway endpoints
- `STEP_FUNCTION_ARN` - ARN of Step Function for automated incident resolution

## Incident Types Supported

The system supports the following incident types:

### Infrastructure Incidents
- **CPU_HIGH** - High CPU utilization (handled by instance resize)
- **MEM_HIGH** - High memory utilization (handled by instance resize)

### Application Incidents
- **APP_CRASH** - Application crashes (handled by service restart)
- **APP_SHUTDOWN** - Application shutdowns (handled by service restart)
- **APP_ERROR** - Application errors (requires manual intervention)

### System Incidents
- **SYSTEM_CRASH** - System crashes (handled by service restart)
- **SYSTEM_SHUTDOWN** - System shutdowns (handled by service restart)

## Deployment

These functions are designed to be deployed as part of the LKS 2025 infrastructure. Each function should be deployed with the appropriate IAM roles and permissions for:

- DynamoDB access (read/write)
- SNS publish permissions
- EC2 instance management
- Step Function execution
- CloudWatch Logs
- CloudWatch alarms (read access)
- PostgreSQL database access (for vector embeddings)
- Kinesis stream access (for vector processing)

## Testing

Each function can be tested individually using the AWS Lambda console or AWS CLI. Test events are provided in the function comments and should match the expected input format.

### Test Event Examples

**CloudWatch Alarm Test:**
```json
{
  "Records": [
    {
      "Sns": {
        "Subject": "ALARM: CPU High",
        "Message": "{\"AlarmName\":\"CPU-High-Alarm\",\"NewStateValue\":\"ALARM\",\"NewStateReason\":\"Threshold Crossed\"}"
      }
    }
  ]
}
```

**Incident Creation Test:**
```json
{
  "alarm_name": "test-cpu-alarm",
  "reason": "CPU utilization exceeded threshold",
  "metric_name": "CPUUtilization",
  "threshold": 80,
  "instance_id": "i-1234567890abcdef0"
}
```

**Vector Embedding Test:**
```json
{
  "incident_id": "INC-2025-001",
  "title": "High CPU Utilization",
  "description": "CPU usage exceeded 80% threshold",
  "status": "solved",
  "report": "Instance was resized from t3.micro to m5.large",
  "severity": "high"
}
```

## Dependencies

- **boto3** - AWS SDK for Python
- **paramiko** - SSH library (for crash/shutdown handlers)
- **requests** - HTTP library (for LLM integration)
- **psycopg2** - PostgreSQL adapter for Python (for vector embeddings)

## Architecture Flow

1. **Detection**: CloudWatch alarms trigger `lks-cloudwatch-alarm.py` via SNS
2. **Processing**: `lks-cloudwatch-alarm.py` identifies incident type and triggers Step Function
3. **Creation**: Step Function calls `lks-incident-creation.py` to create incident record
4. **Notification**: `lks-incident-notification-button.py` sends email with action buttons
5. **Response**: Based on incident type, appropriate handler is triggered:
   - CPU/Memory: Instance resize via `lks-handle-cpu.py` or `lks-handle-mem.py`
   - Crash/Shutdown: Service restart via `lks-handle-crash.py` or `lks-handle-shutdown.py`
   - Unknown: Manual intervention via `lks-handle-error.py`
6. **Reporting**: `lks-incident-report.py` generates AI-powered reports
7. **Resolution**: Success/failure handlers update status and send final notifications
8. **Analytics**: `lks-vector-embeding.py` creates vector embeddings for solved incidents

## Competition Notes

For LKS 2025 participants:
- All functions are pre-configured and ready for deployment
- Environment variables need to be set during infrastructure deployment
- Functions work together to provide automated incident response
- Manual intervention is available through API Gateway endpoints
- AI-powered reporting provides detailed incident analysis
- CloudWatch alarms must be configured to send SNS notifications
- Step Functions orchestrate the incident response workflow
- Vector embeddings enable similarity search for incident analysis
- PostgreSQL with pgvector extension is required for vector storage

## Troubleshooting

### Common Issues
1. **SSH Connection Failures**: Ensure `PRIVATE_KEY` is properly base64 encoded
2. **DynamoDB Access**: Verify IAM permissions for DynamoDB table access
3. **SNS Notifications**: Check SNS topic ARN and permissions
4. **Step Function Triggers**: Verify Step Function ARN and execution permissions
5. **PostgreSQL Connection**: Ensure database credentials and network access are correct
6. **Vector Embedding Failures**: Check Ollama endpoint availability and model access

### Logs
All functions log to CloudWatch Logs. Check the following log groups:
- `/aws/lambda/lks-cloudwatch-alarm`
- `/aws/lambda/lks-incident-creation`
- `/aws/lambda/lks-incident-report`
- `/aws/lambda/lks-incident-notification-button`
- `/aws/lambda/lks-vector-embeding`
- `/aws/lambda/lks-handle-*` (for all incident handlers)

## Vector Embedding Features

The `lks-vector-embeding.py` function provides advanced analytics capabilities:

### Features
- **Automatic Processing**: Only processes incidents with status 'solved' or 'closed'
- **Text Content Creation**: Combines title, description, report, and suggestions
- **Vector Generation**: Uses Ollama LLM to create 768-dimensional embeddings
- **PostgreSQL Storage**: Stores embeddings with pgvector extension for similarity search
- **Kinesis Integration**: Processes incidents from Kinesis streams or direct events

### Use Cases
- **Similar Incident Search**: Find similar past incidents for faster resolution
- **Pattern Analysis**: Identify recurring incident patterns
- **Knowledge Base**: Build a searchable incident knowledge base
- **AI Recommendations**: Provide context-aware incident resolution suggestions 