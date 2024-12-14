from decimal import Decimal
import json
import uuid
import boto3
import time
import base64

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('UsersTable')  # Replace with your DynamoDB table
sessions = dynamodb.Table('SessionTable')
business = dynamodb.Table('BusinessTable')

def lambda_handler(event, context):
    try:
        event2 = json.loads(event['body'])
    except:
        return {
            'statusCode': 422,
            'body': json.dumps({'message': 'Bad Request', 'error': "no body"})
        }
    user_id = event2['userName']
    password = event2['userAttributes']['password']
    userid = {'UserID':user_id}
    response = table.get_item(Key=userid)
    busniessResponse = business.get_item(Key ={'BusinessName':str(event2['BusinessName'])})

    if not ('Item' in busniessResponse): 
        return {
            'statusCode': 422,
            'body': json.dumps({'message': 'Bad Request', 'error': "No Such Business"})
        } 
    if busniessResponse["Item"]['KEY'] != event2['KEY']:
        return {
            'statusCode': 422,
            'body': json.dumps({'message': 'Bad Request', 'error': "Key Missmatch"})
        } 
    print("+++++++++++++++++++\n",response)

    if 'Item' in response:
        index= response['Item']
        hashedPass =index['password']
        if hashedPass == password:
            sessionKey = str(uuid.uuid4())
            expiry = time.time() + 900
            sessions.put_item(
                Item= {
                    'SessionID': sessionKey,
                    'Expiry': Decimal(expiry),
                    'BusinessName':event2['BusinessName'],
                    'KEY': event2['KEY']
                }
            )
            return {
                'statusCode': 200,
                'body': json.dumps({'message': 'User Added','body':json.dumps({
                    'SessionID': sessionKey,
                    'Expiry': expiry,
                    'BusinessName':event2['BusinessName'],
                    'KEY': event2['KEY']
                })})
                }
            
        else:
            return {
            'statusCode': 422,
            'body': json.dumps({'message': 'Bad Request', 'error': "Password Incorrect"})
        } 
    else:
        return {
            'statusCode': 422,
            'body': json.dumps({'message': 'Bad Request', 'error': "User Does not Exists"})
        } 

    
