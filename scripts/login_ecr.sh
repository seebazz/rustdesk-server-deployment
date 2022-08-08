#!/usr/bin/env bash

# reference: https://docs.aws.amazon.com/AmazonECR/latest/userguide/ECR_GetStarted.html
# video: https://aws.amazon.com/ecr/getting-started/

# load env variables (.env is in the same level as shell script.)
source scripts/.env

# setup AWS profile on your shell
echo 'logging into ECR'
aws configure set default.region ${AWS_REGION}
aws configure set default.output json

# get ecr logging details.
token=$(aws ecr get-authorization-token)
registry=$(echo "$token" | jq -r .authorizationData[].proxyEndpoint | sed -e 's|https://||g')
pass=$(echo "$token" | jq -r .authorizationData[].authorizationToken | base64 -d | cut -d: -f2)

# login via docker
echo "$pass" | docker login -u AWS --password-stdin "$registry"
echo 'aws auth successful'
