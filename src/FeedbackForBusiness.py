import boto3
import json
from boto3.dynamodb.conditions import Key

# Initialize DynamoDB resource and table
dynamodb = boto3.resource('dynamodb')
businessTable = dynamodb.Table('FeedbackTable')

def lambda_handler(event, context):
    try:
        # Parse the request body
        body = json.loads(event['body'])
        business_key = body.get("businessKey")

        if not business_key:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "Missing businessKey in the request body"})
            }

        # Query DynamoDB using the GSI for businessKey
        response = businessTable.query(
            IndexName='businessKey-index',  # Use the name of the GSI
            KeyConditionExpression=Key('businessKey').eq(business_key)
        )

        # Extract the items
        items = response.get('Items', [])
        
        # Return the items as a JSON response
        return {
            "statusCode": 200,
            "body": json.dumps(items, default=str),
            "headers": {
                "Content-Type": "application/json"
            }
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": "Internal Server Error", "message": str(e)}),
            "headers": {
                "Content-Type": "application/json"
            }
        }
