import json
import boto3


dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('UsersTable')  


def lambda_handler(event, context):
    try:
        event2 = json.loads(event['body'])
    except:
        return {
            'statusCode': 422,
            'body': json.dumps({'message': 'Bad Request', 'error': "no body"})
        }
    # check if user already exists
    userid = event2['userName']
    userid = {'UserID':userid}
    response = table.get_item(Key=userid)
    print("+++++++++++++++++++\n",response)

    if 'Item' in response:
        return {
            'statusCode': 422,
            'body': json.dumps({'message': 'Bad Request', 'error': "User Already Exists"})
        }
    

    user_id = event2['userName']
    email = event2['userAttributes']['email'] 
    password = event2['userAttributes']['password']   
    hashed_password = password

# Save user information in DynamoDB
    table.put_item(
        Item= {
            'UserID': user_id,
            'email': email,
            'password': hashed_password,
        }
    )
    return {
            'statusCode': 200,
            'body': json.dumps({'message': 'User Added'})
        }
