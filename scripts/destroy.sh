#!/usr/bin/env bash

source scripts/.env

# cleanup aws log group
aws logs delete-log-group --log-group-name ${AWS_PROJECT}

# clean up ecr
python3 scripts/del_ecr.py

ecsInstance=$(aws ecs list-container-instances --cluster ${AWS_PROJECT} |  jq -r '.containerInstanceArns[0]')

aws ecs update-container-instances-state \
    --container-instances $ecsInstance \
    --status DRAINING

# clean up ecs cluster
ecs-cli compose --file docker-compose.ecs.yml --ecs-params ecs-params.ecs.yml --project-name ${AWS_PROJECT} service down --cluster-config ${AWS_PROJECT}
ecs-cli down --force --cluster-config rustdesk

# clean up role
aws iam detach-role-policy --role-name ${AWS_ROLE} --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
aws iam delete-role --role-name ${AWS_ROLE}
