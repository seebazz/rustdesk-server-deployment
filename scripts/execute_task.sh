#!/usr/bin/env bash
set -e


# Task Execution IAM Role
# - create the task execution role

rainbowtext="$1" 

aws iam --region us-east-1 create-role --role-name ecsRainbowtextTaskExecutionRole --assume-role-policy-document file://task-execution-assume-role.json --profile ${rainbowtext}

# - attach the task execution role policy
aws iam --region us-east-1 attach-role-policy --role-name ecsRainbowtextTaskExecutionRole --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy --profile ${rainbowtext}

# ECS CLI configuration
# create ecs cluster
ecs-cli configure --cluster ${rainbowtext} --region us-east-1 --default-launch-type FARGATE --config-name ${rainbowtext}

# create ecs profile
ecs-cli configure profile --access-key "$AWS_ACCESS_KEY_ID" --secret-key "$AWS_SECRET_ACCESS_KEY" --profile-name ${rainbowtext}

# ecs-cli up
result=$(ecs-cli up --instance-role ecsRainbowtextTaskExecutionRole --cluster ${rainbowtext})

echo $result


vpc_id=$(echo "$result" | grep -o "VPC created: .*" | cut -f2 -d:)
security_grp=$(echo "$result" | grep -o "Security Group created: .*" | cut -f2 -d:)
subnet_ids=$(echo "$result" | grep -o "Subnet created: .*" | cut -f2 -d:)

# use an array
array=(${subnet_ids//,/ })
subnet_a=${array[0]}
subnet_b=${array[1]}

echo $vpc_id
echo $security_grp_id
echo $subnet_a
echo $subnet_b

# add a security group rule to allow inbound access on port 80
aws ec2 authorize-security-group-ingress --group-id "${security_grp_id}" --protocol tcp --port 80 --cidr 0.0.0.0/0

# delete cluster
# aws ecs delete-cluster --cluster ${rainbowtext}

# call the python script with the arguments passed
python scripts/ecs_params.py "${vpc_id}" "${security_grp_id}" "${subnet_a}" "$subnet_b}"
