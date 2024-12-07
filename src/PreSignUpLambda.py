import json
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('UsersTable')  


def lambda_handler(event, context):
    # check if user already exists
    userid = event['userName']
    userid = {'UserID':userid}
    response = table.get_item(key =userid)
    print(response)
    if response:
        raise Exception("User Already Exists")
    return event
