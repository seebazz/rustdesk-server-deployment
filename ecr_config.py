import os
import subprocess
import time
import yaml
import re

import boto3

client = boto3.client('ecr')

AWS_ACCOUNT_ID = os.getenv('AWS_ACCOUNT_ID', 'your_AWS_id')
AWS_REGION = os.getenv('AWS_REGION', 'your_aws_region')

# Get the name of the current directory
project_name = os.path.basename(os.path.realpath("."))

# use if repository exist
SERVER_REPOSITORY_URI = f'{AWS_ACCOUNT_ID}.dkr.ecr.{AWS_REGION}.amazonaws.com/temboplatform_server'
NGINX_REPOSITORY_URI = f'{AWS_ACCOUNT_ID}.dkr.ecr.{AWS_REGION}.amazonaws.com/temboplatform_nginx'

ECR_REPO_OBJ = {
    'temboplatform_server': SERVER_REPOSITORY_URI,
    'temboplatform_nginx': NGINX_REPOSITORY_URI
}

push_operations = dict()


# Generate version number for built
version = str(int(time.time()))

input_file = os.environ.get("DOCKER_COMPOSE_YML", "docker-compose.yml")
output_file = os.environ.get("DOCKER_COMPOSE_YML", "docker-compose.yml-{}".format(version))

if input_file == output_file == "docker-compose.yml":
    print("I will not clobber your docker-compose.yml file.")
    print("Please unset DOCKER_COMPOSE_YML or set it to something else.")
    exit(1)

print(project_name, output_file, "The project name")

stack = yaml.load(open(input_file))
services = stack["services"]

# retrieve the login command to use to authenticate your Docker client to your registry.
# subprocess.Popen(["aws", "ecr", "get-login", "--no-include-email", "--region", "us-east-1"])

# response = client.describe_repositories()
# print(response, "describe")

# create repository
def create_ecr_repo(services):
    obj = {}

    for service_name, service in services.items():
        if "build" in service:
            # create repository
            ecr_repository_name = f'{project_name.lower()}_{service_name}'
            try:
                response = client.create_repository(
                    repositoryName=ecr_repository_name,
                    tags=[
                        {
                            'Key': 'platform',
                            'Value': service_name
                        },
                    ]
                )

                ecr_uri = response['repository']['repositoryUri']
                obj[ecr_repository_name] = ecr_uri
            except Exception as e:
                return None
    return obj

def tag(ecr_repo_obj):
    for key, value in ecr_repo_obj.items():
        original_tag = f'{key}:latest'
        new_tag = f'{value}:latest'
        subprocess.check_call(["docker", "tag", original_tag, new_tag])

def push(ecr_repo_obj):
    for key, value in ecr_repo_obj.items():
        new_tag = f'{value}:latest'
        # push_operations[key] = subprocess.Popen(["docker", "push", new_tag])
        push = subprocess.Popen(["docker", "push", new_tag])
        status = f"Waiting for {key} push to complete..."
        print(status)
        push.wait()
        print("Done.")

    # for service_name, popen_object in push_operations.items():
    #     status = f"Waiting for {service_name} push to complete..."
    #     print(status)
    #     popen_object.wait()
    #     print("Done.")

def update(service_name, service, ecr_repo_obj):
    for key, value in ecr_repo_obj.items():
        if service_name in key:
            del service["build"]
            service["image"] = value

def re_tag_images(ecr_repo_obj=None):
    if ecr_repo_obj is None:
        ecr_repo_obj = ECR_REPO_OBJ
    tag(ecr_repo_obj)
    
def push_to_ecr(ecr_repo_obj=None):
    if ecr_repo_obj is None:
        ecr_repo_obj = ECR_REPO_OBJ
    push(ECR_REPO_OBJ)

def update_services(ecr_repo_obj=None):
    # Replace the "build" definition by an "image" definition,
    # using the name of the image on ECR.
    global services
    if ecr_repo_obj is None:
        ecr_repo_obj = ECR_REPO_OBJ

    for service_name, service in services.items():
        if "build" in service:
            update(service_name, service, ecr_repo_obj)

    print(services, "the service")


res = create_ecr_repo(services)
re_tag_images(res)
push_to_ecr(res)
update_services(res)