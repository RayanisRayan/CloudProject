import json
import boto3


dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('UsersTable')  


def lambda_handler(event, context):
    # check if user already exists
    userid = event['userName']
    userid = {'UserID':userid}
    response = table.get_item(Key=userid)
    print("+++++++++++++++++++\n",response)

    if 'Item' in response:
        return {
            'statusCode': 422,
            'body': json.dumps({'message': 'Bad Request', 'error': "User Already Exists"})
        }
    

    user_id = event['userName']
    email = event['userAttributes']['email'] 
    password = event['userAttributes']['password']   
    hashed_password = password

# Save user information in DynamoDB
    table.put_item(
        Item= {
            'UserID': user_id,
            'email': email,
            'password': hashed_password,
        }
    )
    return event
