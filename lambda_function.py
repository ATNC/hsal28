import json
import boto3
from PIL import Image
import io

s3 = boto3.client('s3')


def lambda_handler(event, context):
    try:
        # Extract bucket name and object key from the event
        bucket_name = event['Records'][0]['s3']['bucket']['name']
        object_key = event['Records'][0]['s3']['object']['key']

        # Get the image from S3
        response = s3.get_object(Bucket=bucket_name, Key=object_key)
        image_content = response['Body'].read()

        # Open the image using Pillow
        image = Image.open(io.BytesIO(image_content))

        # Convert and save the image in different formats
        formats = ['BMP', 'GIF', 'PNG']
        for fmt in formats:
            buffer = io.BytesIO()
            image.save(buffer, format=fmt)
            buffer.seek(0)

            # Save the converted image back to S3
            new_key = object_key.rsplit('.', 1)[0] + '.' + fmt.lower()
            s3.put_object(Bucket=bucket_name, Key=new_key, Body=buffer, ContentType=f'image/{fmt.lower()}')

        return {
            'statusCode': 200,
            'body': json.dumps('Image converted successfully')
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error converting image: {str(e)}')
        }
