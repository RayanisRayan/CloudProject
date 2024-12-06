import json
import boto3

# Initialize SNS client
sns = boto3.client('sns')

# Replace with 971422701265 with the user id 
SNS_TOPIC_ARN = "arn:aws:sns:eu-north-1:971422701265:SalesNotificationTopic"

def lambda_handler(event, context):
    try:
        # Extract sale details from the event
        sale_id = event['SaleID']
        user_id = event['UserID']
        sale_amount = event['SaleAmount']
        time_of_sale = event['TimeOfSale']
        items = event['ItemNames']
        
        # Prepare the message to send
        message = {
            'SaleID': sale_id,
            'UserID': user_id,
            'SaleAmount': str(sale_amount),
            'TimeOfSale': time_of_sale,
            'ItemNames': items
        }
        
        # Send the notification (e.g., email or SMS)
        response = sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Message=json.dumps(message),  # Send message as JSON
            Subject="New Sale Notification"  # Subject for email/SMS
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Notification sent successfully', 'response': response})
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Error sending notification', 'error': str(e)})
        }
