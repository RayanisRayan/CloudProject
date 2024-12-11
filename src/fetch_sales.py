import boto3
import json
from datetime import datetime, timedelta
import time
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('SalesTable')

def lambda_handler(event, context):
    
    business_key = event.get('queryStringParameters', {}).get('key')
    print(business_key)
    if not business_key:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Business key is required'})
        }

    # Query DynamoDB for sales in the last month
    now = time.time()
    last_month = now - 3600*24*30

    response = table.scan(
        FilterExpression="businessKey :key AND TimeOfSale >= :last_month",
        ExpressionAttributeValues={
            ':key': business_key,
            ':last_month': int(last_month.timestamp())
        }
    )

    sales_data = response.get('Items', [])
    return {
        'statusCode': 200,
        'body': json.dumps({
            'labels': ['Last Month'],
            'values': [revenue]
        })
    }
