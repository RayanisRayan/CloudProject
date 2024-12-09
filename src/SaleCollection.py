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
sns = boto3.client('sns')

dynamodb = boto3.resource('dynamodb')
lambda_client = boto3.client('lambda')
table = dynamodb.Table('SalesTable')

def lambda_handler(event, context):
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
    try:
        table.put_item(
            Item={
                'SaleID': sale_id,
                'TimeOfSale': Decimal(time_of_sale),
                'SaleAmount': Decimal(sale_amount),
                'ItemNames': items,
                'UserID': str(user_id)
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
            sale_id = event['SaleID']
            user_id = event['UserID']
            sale_amount = event['SaleAmount']
            item_names = event['ItemNames']
            time_of_sale = event['TimeOfSale']
            number = event["PhoneNumber"]
            # Publish to SNS
            message = f"New sale recorded:\nSaleID: {sale_id}\nUserID: {user_id}\nAmount: {sale_amount}\nItems: {item_names}\nTime: {time_of_sale}"
            print("hello")
            sns.publish(
                PhoneNumber="+966580952824",
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
   
