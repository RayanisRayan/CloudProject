import boto3
import json
from decimal import Decimal

# Initialize DynamoDB resource and table
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('FeedbackTable')

def lambda_handler(event, context):
    # Define CORS headers
    headers = {
        "Access-Control-Allow-Origin": "*",  # Allow all origins or specify the allowed origin
        "Access-Control-Allow-Methods": "GET,OPTIONS,POST",  # Allowed HTTP methods
        "Access-Control-Allow-Headers": "Content-Type, X-Amz-Date, Authorization, X-Api-Key, X-Amz-Security-Token"  # Allowed headers
    }
    
    # Handle preflight (OPTIONS) requests for CORS
    if event['httpMethod'] == 'OPTIONS':
        return {
            "statusCode": 200,
            "headers": headers,
            "body": json.dumps({"message": "CORS preflight request"})
        }
    
    try:
        # Parse the request body
        body = json.loads(event['body'])
        sale_id = body.get("SaleID")
        shopping_experience = body.get("ShoppingExperience")
        quality_of_products = body.get("QualityOfProducts")
        would_purchase_again = body.get("WouldPurchaseAgain")
        comments = body.get("Comments")
        
        # Validate required fields
        if not all([sale_id, shopping_experience, quality_of_products, would_purchase_again, comments]):
            return {
                "statusCode": 400,
                "headers": headers,
                "body": json.dumps({"error": "All fields are required"})
            }
        
        # Insert feedback into DynamoDB
        table.put_item(
            Item={
                'SaleID': sale_id,
                'ShoppingExperience': shopping_experience,
                'QualityOfProducts': quality_of_products,
                'WouldPurchaseAgain': str(would_purchase_again),  # Convert boolean to string
                'Comments': comments
            }
        )
        
        # Return success response
        return {
            "statusCode": 200,
            "headers": headers,
            "body": json.dumps({"message": "Feedback inserted successfully", "SaleID": sale_id})
        }
    
    except Exception as e:
        # Return error response
        return {
            "statusCode": 500,
            "headers": headers,
            "body": json.dumps({"error": str(e)})
        }

# Utility class for JSON serialization of Decimal types (if needed in the future)
class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)
