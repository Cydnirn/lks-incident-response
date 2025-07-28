import json
import boto3
import base64
import os
import psycopg2
import requests
from datetime import datetime

# Environment variables
OLLAMA_ENDPOINT = os.environ.get('OLLAMA_ENDPOINT')
OLLAMA_MODEL = os.environ.get('OLLAMA_MODEL', 'phi4-mini')

# PostgreSQL connection parameters
DB_HOST = os.environ.get('DB_HOST')
DB_PORT = os.environ.get('DB_PORT', '5432')
DB_NAME = os.environ.get('DB_NAME', 'incidents')
DB_USER = os.environ.get('DB_USER')
DB_PASSWORD = os.environ.get('DB_PASSWORD')

def lambda_handler(event, context):
    """
    Simple vectorizer - only process incidents with status 'solved' or 'closed'
    """
    try:
        print(f"Received event: {json.dumps(event)}")
        
        # Initialize PostgreSQL table
        init_postgres_table()
        
        processed_count = 0
        
        # Process different event sources
        if event.get('source') == 'aws.kinesis' and 'detail' in event:
            # EventBridge from Kinesis
            incident_data = decode_kinesis_data(event['detail'])
            if incident_data and should_process_incident(incident_data):
                success = process_incident(incident_data)
                processed_count = 1 if success else 0
                
        elif 'Records' in event:
            # Direct Kinesis records
            for record in event['Records']:
                incident_data = decode_kinesis_data(record['kinesis'])
                if incident_data and should_process_incident(incident_data):
                    success = process_incident(incident_data)
                    if success:
                        processed_count += 1
        else:
            # Direct incident data (testing)
            if should_process_incident(event):
                success = process_incident(event)
                processed_count = 1 if success else 0
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Vectorization completed',
                'processed_incidents': processed_count,
                'timestamp': datetime.utcnow().isoformat()
            })
        }
        
    except Exception as e:
        print(f"Error in vectorization: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }


def init_postgres_table():
    """
    Create incident-vector table if not exists
    """
    try:
        conn = get_postgres_connection()
        cursor = conn.cursor()
        
        # Enable pgvector extension
        cursor.execute("CREATE EXTENSION IF NOT EXISTS vector;")
        
        # Create simple table for solved/closed incidents
        create_table_sql = """
        CREATE TABLE IF NOT EXISTS "incident-vector" (
            id SERIAL PRIMARY KEY,
            incident_id VARCHAR(255) UNIQUE NOT NULL,
            title TEXT,
            description TEXT,
            report TEXT,
            suggestions TEXT[],
            severity VARCHAR(20),
            category VARCHAR(50),
            incident_type VARCHAR(50),
            environment VARCHAR(20),
            status VARCHAR(20),
            action_taken TEXT,
            affected_services TEXT[],
            tags TEXT[],
            text_content TEXT,
            embedding VECTOR(768),
            created_at TIMESTAMP,
            resolution_time TIMESTAMP,
            vectorized_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        
        CREATE INDEX IF NOT EXISTS idx_incident_id ON "incident-vector"(incident_id);
        CREATE INDEX IF NOT EXISTS idx_incident_type ON "incident-vector"(incident_type);
        CREATE INDEX IF NOT EXISTS idx_severity ON "incident-vector"(severity);
        CREATE INDEX IF NOT EXISTS idx_embedding ON "incident-vector" USING ivfflat (embedding vector_cosine_ops);
        """
        
        cursor.execute(create_table_sql)
        conn.commit()
        cursor.close()
        conn.close()
        
        print("PostgreSQL table initialized successfully")
        
    except Exception as e:
        print(f"Error initializing PostgreSQL: {str(e)}")
        raise e


def get_postgres_connection():
    """
    Get PostgreSQL connection
    """
    return psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD
    )


def decode_kinesis_data(kinesis_record):
    """
    Decode base64 data from Kinesis
    """
    try:
        if 'data' not in kinesis_record:
            return None
        
        # Decode base64
        decoded_data = base64.b64decode(kinesis_record['data']).decode('utf-8')
        incident_data = json.loads(decoded_data)
        
        return incident_data
        
    except Exception as e:
        print(f"Error decoding Kinesis data: {str(e)}")
        return None


def should_process_incident(incident_data):
    """
    Check if incident should be processed (only solved/closed)
    """
    status = incident_data.get('status', '').lower()
    
    if status in ['solved', 'closed']:
        print(f"Processing incident {incident_data.get('id')} with status: {status}")
        return True
    else:
        print(f"Skipping incident {incident_data.get('id')} with status: {status}")
        return False


def process_incident(incident_data):
    """
    Process single incident and store vector
    """
    try:
        incident_id = incident_data.get('id')
        if not incident_id:
            print("No incident ID found")
            return False
        
        # Create text content for embedding
        text_content = create_text_content(incident_data)
        
        # Generate embedding using Ollama
        embedding = generate_embedding(text_content)
        if not embedding:
            print(f"Failed to generate embedding for {incident_id}")
            return False
        
        # Store in PostgreSQL
        return store_vector(incident_id, incident_data, embedding, text_content)
        
    except Exception as e:
        print(f"Error processing incident: {str(e)}")
        return False


def create_text_content(incident_data):
    """
    Create text content from incident data
    """
    parts = []
    
    # Basic info
    if incident_data.get('title'):
        parts.append(f"Title: {incident_data['title']}")
    
    if incident_data.get('description'):
        parts.append(f"Description: {incident_data['description']}")
    
    if incident_data.get('report'):
        parts.append(f"Report: {incident_data['report']}")
    
    # Technical details
    parts.append(f"Type: {incident_data.get('insident_type', 'unknown')}")
    parts.append(f"Severity: {incident_data.get('severity', 'unknown')}")
    parts.append(f"Category: {incident_data.get('category', 'unknown')}")
    parts.append(f"Environment: {incident_data.get('environment', 'unknown')}")
    
    # Resolution info
    if incident_data.get('actionTaken'):
        parts.append(f"Action Taken: {incident_data['actionTaken']}")
    
    # Suggestions
    if incident_data.get('suggestions'):
        suggestions_text = '. '.join(incident_data['suggestions'])
        parts.append(f"Suggestions: {suggestions_text}")
    
    # Services and tags
    if incident_data.get('affectedServices'):
        services = ', '.join(incident_data['affectedServices'])
        parts.append(f"Affected Services: {services}")
    
    if incident_data.get('tags'):
        tags = ', '.join(incident_data['tags'])
        parts.append(f"Tags: {tags}")
    
    return '. '.join(parts)


def generate_embedding(text):
    """
    Generate embedding using Ollama phi4-mini
    """
    try:
        if not OLLAMA_ENDPOINT:
            print("OLLAMA_ENDPOINT not configured")
            return None
        
        payload = {
            "model": OLLAMA_MODEL,
            "prompt": text
        }
        
        response = requests.post(
            f"{OLLAMA_ENDPOINT}/api/embeddings",
            json=payload,
            timeout=60,
            headers={'Content-Type': 'application/json'}
        )
        
        if response.status_code == 200:
            result = response.json()
            embedding = result.get('embedding')
            
            if embedding:
                print(f"Generated {len(embedding)}-dimensional embedding")
                return embedding
        
        print(f"Ollama error: {response.status_code}")
        return None
        
    except Exception as e:
        print(f"Error calling Ollama: {str(e)}")
        return None


def store_vector(incident_id, incident_data, embedding, text_content):
    """
    Store vector in PostgreSQL
    """
    try:
        conn = get_postgres_connection()
        cursor = conn.cursor()
        
        # Convert embedding to pgvector format
        embedding_str = '[' + ','.join(map(str, embedding)) + ']'
        
        # Parse timestamps
        created_at = None
        resolution_time = None
        
        if incident_data.get('createdAt'):
            try:
                created_at = datetime.fromisoformat(incident_data['createdAt'].replace('Z', '+00:00'))
            except:
                pass
        
        if incident_data.get('resolutionTime'):
            try:
                resolution_time = datetime.fromisoformat(incident_data['resolutionTime'].replace('Z', '+00:00'))
            except:
                pass
        
        # Insert or update
        insert_sql = """
        INSERT INTO "incident-vector" (
            incident_id, title, description, report, suggestions,
            severity, category, incident_type, environment, status,
            action_taken, affected_services, tags, text_content,
            embedding, created_at, resolution_time
        ) VALUES (
            %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
        ) ON CONFLICT (incident_id) DO UPDATE SET
            title = EXCLUDED.title,
            description = EXCLUDED.description,
            report = EXCLUDED.report,
            suggestions = EXCLUDED.suggestions,
            severity = EXCLUDED.severity,
            category = EXCLUDED.category,
            incident_type = EXCLUDED.incident_type,
            environment = EXCLUDED.environment,
            status = EXCLUDED.status,
            action_taken = EXCLUDED.action_taken,
            affected_services = EXCLUDED.affected_services,
            tags = EXCLUDED.tags,
            text_content = EXCLUDED.text_content,
            embedding = EXCLUDED.embedding,
            resolution_time = EXCLUDED.resolution_time,
            vectorized_at = CURRENT_TIMESTAMP;
        """
        
        cursor.execute(insert_sql, (
            incident_id,
            incident_data.get('title', ''),
            incident_data.get('description', ''),
            incident_data.get('report', ''),
            incident_data.get('suggestions', []),
            incident_data.get('severity', 'unknown'),
            incident_data.get('category', 'other'),
            incident_data.get('insident_type', 'OTHER'),
            incident_data.get('environment', 'production'),
            incident_data.get('status', 'unknown'),
            incident_data.get('actionTaken', ''),
            incident_data.get('affectedServices', []),
            incident_data.get('tags', []),
            text_content,
            embedding_str,
            created_at,
            resolution_time
        ))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        print(f"Successfully stored vector for incident: {incident_id}")
        return True
        
    except Exception as e:
        print(f"Error storing vector: {str(e)}")
        return False