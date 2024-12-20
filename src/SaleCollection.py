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

# def lambda_handler(event, context):
#     # Extract input values
    
#     try:
#         sale_id = str(uuid.uuid4())
#         user_id = int(event['UserID'])
#         items = event['ItemNames']
#         sale_amount = Decimal(str(event['SaleAmount']))
#         time_of_sale = int(event['TimeOfSale'])
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
import time
sns = boto3.client('sns')

dynamodb = boto3.resource('dynamodb')
lambda_client = boto3.client('lambda')
table = dynamodb.Table('SalesTable')

def lambda_handler(event, context):
    event2 = json.loads(event['body'])
    try:
        sale_id = str(uuid.uuid4())
        user_id = str(event2['UserID'])
        items = event2['ItemNames']
        sale_amount = Decimal(str(event2['SaleAmount']))
        time_of_sale = time.time()
        businessKey = str(event2['businessKey'])
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
                'UserID': str(user_id),
                'businessKey': businessKey
            }
        )

        # Notify the Notification Lambda
        notification_event = {
            'SaleID': sale_id,
            'TimeOfSale': time_of_sale,
            'SaleAmount': float(sale_amount),
            'ItemNames': items,
            'UserID': user_id
        }
        try:
        # Extract sale details
            print(event2)
            sale_id = sale_id
            user_id = event2['UserID']
            sale_amount = event2['SaleAmount']
            item_names = event2['ItemNames']
            number = str(event2["PhoneNumber"])
            # Publish to SNS
            message = f"Thank you for purchasing from us. Please take the sale id and rate us through the link provided.\nSale ID: {sale_id}\nLink: http://13.60.218.222"
            print("hello")
            sns.publish(
                PhoneNumber=number,
                Message=message,
                Subject="New Sale Notification"
            )

            
        except Exception as e:
            return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Error sending notification', 'error': str(e)})
            }
        # lambda_client.invoke(
        #     FunctionName="arn:aws:lambda:eu-north-1:971422701265:function:NotificationLambda",
        #     InvocationType="Event",  # Async invocation
        #     Payload=json.dumps(notification_event)
        # )
        
        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Sale inserted successfully', 'Sale ID': sale_id})
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Error inserting sale', 'error': str(e)})
        }
   
