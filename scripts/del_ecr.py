import os
import boto3

client = boto3.client('ecr')

ID = os.getenv('AWS_ACCOUNT_ID', 'your_AWS_id')
REGION = os.getenv('AWS_REGION', 'your_aws_region')
PROJECT = os.getenv('AWS_PROJECT', 'your_aws_region')

# use if repository exist
HBBS_REPOSITORY_URI = f'{ID}.dkr.ecr.{REGION}.amazonaws.com/{PROJECT}_hbbs'
HBBR_REPOSITORY_URI = f'{ID}.dkr.ecr.{REGION}.amazonaws.com/{PROJECT}_hbbr'

ECR_REPO_OBJ = {
    f"{PROJECT}_hbbs": HBBS_REPOSITORY_URI,
    f"{PROJECT}_hbbr": HBBR_REPOSITORY_URI
}

for key, value in ECR_REPO_OBJ.items():
    response = client.delete_repository(
        registryId=ID,
        repositoryName=key,
        force=True
    )

    print(response)
