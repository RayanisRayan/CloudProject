import boto3
import json

sns = boto3.client('sns')
import os
SNS_TOPIC_ARN = os.getenv("SNS_TOPIC_ARN")

def lambda_handler(event, context):
    try:
        # Extract sale details
        sale_id = event['SaleID']
        user_id = event['UserID']
        sale_amount = event['SaleAmount']
        item_names = event['ItemNames']
        time_of_sale = event['TimeOfSale']

        # Publish to SNS
        message = f"New sale recorded:\nSaleID: {sale_id}\nUserID: {user_id}\nAmount: {sale_amount}\nItems: {item_names}\nTime: {time_of_sale}"
        print("hello")
        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Message=message,
            Subject="New Sale Notification"
        )

        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Notification sent successfully'})
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Error sending notification', 'error': str(e)})
        }
