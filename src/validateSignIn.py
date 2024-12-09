import json
import uuid
import boto3
import time
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('SessionTable')  


def lambda_handler(event, context):
    try:
        event2 = json.loads(event['body'])
    except:
        return {
            'statusCode': 422,
            'body': json.dumps({'message': 'Bad Request', 'error': "no body"})
        }
    resource = table.get_item(Key= {
        "SessionID":event2['SessionID']
    })
    if 'Item' in resource:
        if resource['Item']['KEY'] == event2['KEY']:
            current = time.time()
            expiry = resource['Item']['Expiry']
            if current<expiry:
                return{
                'statusCode': 200,
                'body': json.dumps({'message': 'VALID'})
                }
            else:
                return{
                'statusCode': 200,
                'body': json.dumps({'message': 'EXPIRED'})
                }
        else:
            return{
            'statusCode': 422,
            'body': json.dumps({'message': 'Bad Request', 'error': "KEY missmatch"})
        } 
    else:
        return {
            'statusCode': 422,
            'body': json.dumps({'message': 'Bad Request', 'error': "No such session"})
        } 