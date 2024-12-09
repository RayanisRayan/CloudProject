import boto3
from decimal import Decimal
import json

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('FeedbackTable')

def lambda_handler(event, context):
    try:
        sale_id = event["SaleID"]
        Shopping_Experience = event["ShoppingExperience"]
        Quality_Of_Products = event["QualityOfProducts"]
        Would_Purchase_Again = event["WouldPurchaseAgain"]
        Comments = event["Comments"]
    except Exception as e:
        return {
            'statusCode': 422,
            'body': json.dumps({'message': 'Bad Request', 'error': str(e)})
        }
    try:
        table.put_item(
            Item={
                'SaleID': sale_id,
                'ShoppingExperience': Shopping_Experience,
                'QualityOfProducts': Quality_Of_Products,
                'WouldPurchaseAgain': str(Would_Purchase_Again),
                'Comments': Comments
            }
        )
        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Feedback inserted successfully', 'Sale ID': sale_id})
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Error inserting Feedback', 'error': str(e)})
        }
   
