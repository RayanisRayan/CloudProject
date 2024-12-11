import boto3
import json
import time
from decimal import Decimal
from boto3.dynamodb.conditions import Attr

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
    last_month = Decimal(now - 3600*24*30)

    response = table.scan(
    FilterExpression=Attr('businessKey').eq(business_key) & Attr('TimeOfSale').gte(last_month))
    print(response)
    sales_data = response.get('Items', [])
    return {
        'statusCode': 200,
        "headers": {
        "Access-Control-Allow-Origin": "*",  # Allow all origins or specify the allowed origin
        "Access-Control-Allow-Methods": "GET, POST, OPTIONS",  # Allowed HTTP methods
        "Access-Control-Allow-Headers": "Content-Type"  # Allowed headers
        },
        'body': json.dumps(sales_data, cls=DecimalEncoder)
    }

class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)  # Or use int(obj) if you prefer
        return super(DecimalEncoder, self).default(obj)