import boto3
import random
import csv
import json

RANGE_BEGIN = 0
RANGE_END = 100
NUM_EXAMPLES = 5000

def f(x, y):
    return int(y >= (30 * x + 50))

def lambda_handler(event, context):
    s3 = boto3.resource('s3')

    train_points = [(random.randint(RANGE_BEGIN, RANGE_END), random.randint(RANGE_BEGIN, RANGE_END)) for i in range(NUM_EXAMPLES)]
    train = [[f(x, y), x, y] for x, y in train_points]

    bucket_name = 'terraform-bucket-luther-wisa'
    bucket = s3.Bucket(bucket_name)
    
    with open('/tmp/raw.csv', 'w') as writeFile:
        writer = csv.writer(writeFile)
        writer.writerows(train)
    
    with open('/tmp/transform.py', 'w') as writeFile:
        writeFile.write("import os\nimport pandas as pd\nimport numpy as np\n\nif __name__=='__main__':\n    columns = ['label', 'x', 'y']\n\n    input_data_path = os.path.join('/opt/ml/processing/input', 'raw.csv')\n    \n    df = pd.read_csv(input_data_path, names=columns, dtype={'label': np.int, 'x': np.float, 'y': np.float})\n\n    # Standard Scalar\n    df['x'] = (df['x'] - df['x'].mean()) / df['x'].std()\n    df['y'] = (df['y'] - df['y'].mean()) / df['y'].std()\n\n    # Save\n    df.to_csv('/opt/ml/processing/output/train/transformed.csv', header=False, index=False)\n")
    
    bucket.upload_file('/tmp/raw.csv', 'input/raw.csv')
    bucket.upload_file('/tmp/transform.py', 'code/transform.py')

    return {
        'statusCode': 200,
        'body': json.dumps({
            'raw': 'input/raw.csv',
            'code': 'code/transform.py'
        })
    }