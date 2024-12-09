# from decimal import Decimal
# import json
# import boto3
# import uuid
# """
# For now this is a sale dynamo db
# Sale ID - number
# time of sale - number? 
# sale ammount - float
# item names - json
# user id - number

# """
# #TODO provision it
# dynamodb = boto3.resource('dynamodb')
# table = dynamodb.Table('SalesTable')
# #TODO: Validate User Exists

# def lambda_handler(event2, context):
#     # Extract input values
    
#     try:
#         sale_id = str(uuid.uuid4())
#         user_id = int(event2['UserID'])
#         items = event2['ItemNames']
#         sale_amount = Decimal(str(event2['SaleAmount']))
#         time_of_sale = int(event2['TimeOfSale'])
#     except Exception as e:
#         return {
#             'statusCode': 422,
#             'body': json.dumps({'message': 'Bad Request', 'error': str(e)})
#         }
#     # Perform the operation based on the function
#     # TO DO
#     try:
#         response = table.put_item(
#             Item={
#                 'SaleID': sale_id,  # Partition key
#                 'TimeOfSale': Decimal(time_of_sale),  # Ensure number format
#                 'SaleAmount': Decimal(sale_amount),
#                 'ItemNames': items,  # List of items
#                 'UserID': user_id
#             }
#         )
        
#         return {
#             'statusCode': 200,
#             'body': json.dumps({'message': 'Sale inserted successfully', 'Sale ID': sale_id})
#         }
#     except Exception as e:
#         return {
#             'statusCode': 500,
#             'body': json.dumps({'message': 'Error inserting sale', 'error': str(e)})
#         }
import boto3
import uuid
from decimal import Decimal
import json

dynamodb = boto3.resource('dynamodb')
lambda_client = boto3.client('lambda')
table = dynamodb.Table('SalesTable')

def lambda_handler(event, context):
    try:
        event2 = json.loads(event['body'])
    except:
        return {
            'statusCode': 422,
            'body': json.dumps({'message': 'Bad Request', 'error': "no body"})
        }
    try:
        sale_id = str(uuid.uuid4())
        user_id = int(event2['UserID'])
        items = event2['ItemNames']
        sale_amount = Decimal(str(event2['SaleAmount']))
        time_of_sale = int(event2['TimeOfSale'])
    except Exception as e:
        return {
            'statusCode': 422,
            'body': json.dumps({'message': 'Bad Request', 'error': str(e)})
        }
    try:
        table.put_item(
            Item={
                'SaleID': sale_id,
                'TimeOfSale': Decimal(time_of_sale),
                'SaleAmount': Decimal(sale_amount),
                'ItemNames': items,
                'UserID': user_id
            }
        )

        # Notify the Notification Lambda
        notification_event2 = {
            'SaleID': sale_id,
            'TimeOfSale': time_of_sale,
            'SaleAmount': float(sale_amount),
            'ItemNames': items,
            'UserID': user_id
        }
        lambda_client.invoke(
            FunctionName="NotificationLambda",
            InvocationType="Event",  # Async invocation
            Payload=json.dumps(notification_event2)
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
