import json

def manual_intervention_handler(event, context):
    """
    Return error indicating manual intervention is required
    Input: {"instance_id": "i-xxx"}
    """
    
    instance_id = event.get('instance_id', 'unknown')
    incident_id = event.get('incident_id', 'unknown')
    incident_type = event.get('incident_type', 'unknown')
    
    return {
        'instance_id': instance_id,
        'incident_id': incident_id,
        'incident_type': incident_type,
        'status': 'error',
        'report': 'Manual intervention required',
        'severity': 'high'
    }