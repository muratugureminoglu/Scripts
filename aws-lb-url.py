import json

def lambda_handler(event, context):

    headers = event.get('headers', {})
    host = headers.get('host', '')
    
    path = event.get('path', '')
    
    full_url = f"https://{host}{path}"
    
    if host:
        return {
            'statusCode': 200,
            'body': f'URL: {full_url}',
            'headers': {
                'Content-Type': 'text/plain'
            }
        }

