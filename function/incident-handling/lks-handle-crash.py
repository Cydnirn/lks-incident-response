import json
import boto3
import paramiko
import os
import base64
from io import StringIO

def restart_service_handler(event, context):
    """
    Restart service loadsim via SSH
    Input: {"instance_id": "i-xxx", "incident_id": "INC-2025-001"}
    Environment Variables:
    - PRIVATE_KEY: Base64 encoded private key
    - SSH_USER: SSH username (default: ubuntu)
    - SERVICE_NAME: Service name (default: loadsim)
    """
    
    instance_id = event['instance_id']
    incident_id = event['incident_id']
    # Get environment variables
    private_key_b64 = os.environ.get('PRIVATE_KEY')
    ssh_user = os.environ.get('SSH_USER', 'ubuntu')
    service_name = os.environ.get('SERVICE_NAME', 'loadsim')
    
    if not private_key_b64:
        return {
            'instance_id': instance_id,
            'incident_id': incident_id,
            'status': 'error',
            'error': 'PRIVATE_KEY environment variable not set'
        }
    
    ec2 = boto3.client('ec2')
    ssh_client = None
    
    try:
        # Get instance IP address
        response = ec2.describe_instances(InstanceIds=[instance_id])
        instance = response['Reservations'][0]['Instances'][0]
        
        # Try private IP first, then public IP
        instance_ip = instance.get('PrivateIpAddress')
        if not instance_ip:
            instance_ip = instance.get('PublicIpAddress')
        
        if not instance_ip:
            return {
                'instance_id': instance_id,
                'incident_id': incident_id,
                'status': 'error',
                'error': 'No IP address found for instance'
            }
        
        # Decode private key
        private_key_str = base64.b64decode(private_key_b64).decode('utf-8')
        private_key = paramiko.RSAKey.from_private_key(StringIO(private_key_str))
        
        # Create SSH connection
        ssh_client = paramiko.SSHClient()
        ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        
        # Connect with timeout
        ssh_client.connect(
            hostname=instance_ip,
            username=ssh_user,
            pkey=private_key,
            timeout=30,
            banner_timeout=30
        )
        
        # Check if service exists
        stdin, stdout, stderr = ssh_client.exec_command(f'systemctl list-units --type=service | grep {service_name}')
        service_exists = stdout.read().decode().strip()
        
        if not service_exists:
            return {
                'instance_id': instance_id,
                'incident_id': incident_id,
                'status': 'error',
                'error': f'Service {service_name} not found'
            }
        
        # Get service status before restart
        stdin, stdout, stderr = ssh_client.exec_command(f'systemctl is-active {service_name}')
        status_before = stdout.read().decode().strip()
        
        # Restart the service
        stdin, stdout, stderr = ssh_client.exec_command(f'sudo systemctl restart {service_name}')
        restart_error = stderr.read().decode().strip()
        
        if restart_error and 'Warning' not in restart_error:
            return {
                'instance_id': instance_id,
                'incident_id': incident_id,
                'status': 'error',
                'error': f'Failed to restart service: {restart_error}'
            }
        
        # Wait a moment for service to start
        import time
        time.sleep(3)
        
        # Check service status after restart
        stdin, stdout, stderr = ssh_client.exec_command(f'systemctl is-active {service_name}')
        status_after = stdout.read().decode().strip()
        
        # Get service logs (last 5 lines)
        stdin, stdout, stderr = ssh_client.exec_command(f'sudo journalctl -u {service_name} -n 5 --no-pager')
        recent_logs = stdout.read().decode().strip()
        
        return {
            'instance_id': instance_id,
            'instance_ip': instance_ip,
            'service_name': service_name,
            'incident_id': incident_id,
            'status': 'success',
            'status_before': status_before,
            'status_after': status_after,
            'is_active': status_after == 'active',
            'recent_logs': recent_logs[-500:] if recent_logs else ''  # Last 500 chars
        }
        
    except paramiko.AuthenticationException:
        return {
            'instance_id': instance_id,
            'incident_id': incident_id,
            'status': 'error',
            'error': 'SSH authentication failed'
        }
    except paramiko.SSHException as e:
        return {
            'instance_id': instance_id,
            'incident_id': incident_id,
            'status': 'error',
            'error': f'SSH connection error: {str(e)}'
        }
    except Exception as e:
        return {
            'instance_id': instance_id,
            'incident_id': incident_id,
            'status': 'error',
            'error': str(e)
        }
    finally:
        if ssh_client:
            ssh_client.close()