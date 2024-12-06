import json
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('UsersTable')  # Replace with your DynamoDB table

def lambda_handler(event, context):
    user_id = event['userName']
    email = event['request']['userAttributes']['email']    
    # Save user information in DynamoDB
    table.put_item(
        Item={
            'UserID': user_id,
            'email': email,
        }
    )
    
    return event
