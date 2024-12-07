import json
import uuid
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('BusinessTable')  


def lambda_handler(event, context):
    # check if user already exists
    businessID = event['BusinessName']
    businessID = {'BusinessName':businessID}
    response = table.get_item(Key = businessID)
    if 'Item' in response:
        return {
            'statusCode': 422,
            'body': json.dumps({'message': 'Bad Request', 'error': "Business Already Exists"})
        }

    businessID = event['BusinessName']
    url = event['businessAttributes']['URL'] 
    unique_key = str(uuid.uuid4())

# Save user information in DynamoDB
# Unique Key to make changes
    table.put_item(
        Item= {
            'BusinessName': businessID,
            'URL': url,
            'KEY': unique_key 
        }
    )
    return {
            'BusinessName': businessID,
            'URL': url,
            'KEY': unique_key 
        }