from decimal import Decimal
import json
import boto3
import uuid
"""
For now this is a sale dynamo db
Sale ID - number
time of sale - number? 
sale ammount - float
item names - json
user id - number

"""
#TODO provision it
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('SalesTable')
#TODO: Validate User Exists

def lambda_handler(event, context):
    # Extract input values
    
    try:
        sale_id = str(uuid.uuid4())
        user_id = int(event['UserID'])
        items = event['ItemNames']
        sale_amount = Decimal(str(event['SaleAmount']))
        time_of_sale = int(event['TimeOfSale'])
    except Exception as e:
        return {
            'statusCode': 422,
            'body': json.dumps({'message': 'Bad Request', 'error': str(e)})
        }
    # Perform the operation based on the function
    # TO DO
    try:
        response = table.put_item(
            Item={
                'SaleID': sale_id,  # Partition key
                'TimeOfSale': Decimal(time_of_sale),  # Ensure number format
                'SaleAmount': Decimal(sale_amount),
                'ItemNames': items,  # List of items
                'UserID': user_id
            }
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Sale inserted successfully', 'Sale ID': sale_id})
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Error inserting sale', 'error': str(e)})
        }
