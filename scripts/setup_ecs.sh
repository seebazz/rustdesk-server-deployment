#!/usr/bin/env bash
set -e

source scripts/.env
# Task Execution IAM Role
# - create the task execution role
project_name=$AWS_PROJECT
role_name=$AWS_ROLE

echo "creating role"
aws iam create-role --role-name ${role_name} --assume-role-policy-document file://scripts/task-execution-assume-role.json

# attach the task execution role policy
echo "attach the task execution role policy"
aws iam attach-role-policy --role-name ${role_name} --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

# ECS CLI configuration
# create ecs cluster config
echo "create ecs cluster config"
ecs-cli configure --cluster ${project_name} --region ${AWS_REGION} --default-launch-type EC2 --config-name ${project_name}

# create ecs profile
echo "create ecs profile"
ecs-cli configure profile --access-key "$AWS_ACCESS_KEY_ID" --secret-key "$AWS_SECRET_ACCESS_KEY" --profile-name ${project_name}


# use an array
array=(${PublicSubnets//,/ })
subnet_a=${array[0]}
subnet_b=${array[1]}

# call the python script with the arguments passed
python3 scripts/set_ecs_params.py "${VPC}" "${ECSHostSecurityGroup}" "${subnet_a}" "${subnet_b}"

# deploy to the ecs cluster
ecs-cli compose --file ${DOCKER_COMPOSE_YML_OUTPUT} --ecs-params ${ECS_PARAMS_OUTPUT} --project-name ${project_name} service up --create-log-groups --cluster-config ${project_name}