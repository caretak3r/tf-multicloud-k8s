#!/usr/bin/env python3
import json
import os
import logging
from flask import Flask, jsonify, request
import boto3
from botocore.exceptions import ClientError

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize AWS Secrets Manager client
secrets_client = boto3.client('secretsmanager', region_name=os.environ.get('AWS_REGION', 'us-east-1'))
secrets_prefix = os.environ.get('SECRETS_PREFIX', '')

@app.route('/health')
def health_check():
    return jsonify({"status": "healthy"}), 200

@app.route('/secret/<secret_name>')
def get_secret(secret_name):
    try:
        full_secret_name = f"{secrets_prefix}{secret_name}"
        
        response = secrets_client.get_secret_value(SecretId=full_secret_name)
        secret_value = response['SecretString']
        
        # Try to parse as JSON, fall back to string
        try:
            parsed_secret = json.loads(secret_value)
            return jsonify({"value": parsed_secret})
        except json.JSONDecodeError:
            return jsonify({"value": secret_value})
            
    except ClientError as e:
        error_code = e.response['Error']['Code']
        logger.error(f"Error retrieving secret {secret_name}: {error_code}")
        
        if error_code == 'DecryptionFailureException':
            return jsonify({"error": "Secret decryption failed"}), 500
        elif error_code == 'InternalServiceErrorException':
            return jsonify({"error": "Internal service error"}), 500
        elif error_code == 'InvalidParameterException':
            return jsonify({"error": "Invalid parameter"}), 400
        elif error_code == 'InvalidRequestException':
            return jsonify({"error": "Invalid request"}), 400
        elif error_code == 'ResourceNotFoundException':
            return jsonify({"error": "Secret not found"}), 404
        else:
            return jsonify({"error": "Unknown error"}), 500
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500

@app.route('/secrets')
def list_secrets():
    try:
        response = secrets_client.list_secrets(
            Filters=[
                {
                    'Key': 'name',
                    'Values': [f'{secrets_prefix}*']
                }
            ]
        )
        
        secret_names = [secret['Name'].replace(secrets_prefix, '') for secret in response['SecretList']]
        return jsonify({"secrets": secret_names})
        
    except Exception as e:
        logger.error(f"Error listing secrets: {str(e)}")
        return jsonify({"error": "Failed to list secrets"}), 500

@app.route('/secret/<secret_name>/<key>')
def get_secret_key(secret_name, key):
    try:
        full_secret_name = f"{secrets_prefix}{secret_name}"
        
        response = secrets_client.get_secret_value(SecretId=full_secret_name)
        secret_value = response['SecretString']
        
        try:
            parsed_secret = json.loads(secret_value)
            if key in parsed_secret:
                return jsonify({"value": parsed_secret[key]})
            else:
                return jsonify({"error": f"Key '{key}' not found in secret"}), 404
        except json.JSONDecodeError:
            return jsonify({"error": "Secret is not JSON format"}), 400
            
    except ClientError as e:
        error_code = e.response['Error']['Code']
        logger.error(f"Error retrieving secret {secret_name}: {error_code}")
        
        if error_code == 'ResourceNotFoundException':
            return jsonify({"error": "Secret not found"}), 404
        else:
            return jsonify({"error": "Failed to retrieve secret"}), 500
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)