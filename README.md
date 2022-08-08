# rustdesk-server-deployment

A rustdesk server deployment to demonstrate auto deploy to AWS-ECS with Docker-Compose

Project Folder Structure.

```text
- cloudformation
    | - create-vpc.yml
    | - ecs-cluster.yml
    | - lifecyclehook.yml
    | - load-balancer.yml
    | - security-group.yml
- scripts
    | - .env (ignored)
    | - config_ecr.py
    | - del_ecr.py
    | - deploy.sh
    | - destroy.sh
    | - login_ecr.sh
    | - set_ecs_params.py
    | - setup_ecs.sh
    | - task-execution-assume-role.json
- .env (ignored)
- .gitignore
- docker-compose.ecs.yml(generated and ignored)
- docker-compose.yml
- ecs-params.yml
- ecs-params.ecs.yml (generated and ignored)
- instructions.txt
- LICENSE
- README.md
- requirements.txt
```

`.env` file should be placed in your `scripts` folder.
*run `source scripts/.env` to load your environment variables*

```shell
export AWS_PROJECT=rustdesk-server
export AWS_ROLE=<YOUR_AWS_ROLE_NAME>

export AWS_ACCOUNT_ID=<YOUR_AWS_IAM_ACCOUNT_ID>
export AWS_REGION=<YOUR_AWS_REGION>

export AWS_ACCESS_KEY_ID=<YOUR_AWS_IAM_ACCESS_KEY_ID>
export AWS_SECRET_ACCESS_KEY=<YOUR_AWS_IAM_SECRET_ACCESS_KEY>

export DOCKER_COMPOSE_YML_INPUT=docker-compose.yml
export DOCKER_COMPOSE_YML_OUTPUT=docker-compose.ecs.yml

export ECS_PARAMS_INPUT=ecs-params.yml
export ECS_PARAMS_OUTPUT=ecs-params.ecs.yml

export VPC=<YOUR_EXISTING_OR_CREATED_VPC>
export ECSHostSecurityGroup=<YOUR_SG_FROM_RUNNING_CF_FILES>
export PublicSubnets=<EXISTING_OR_CREATED_WITH_VPC>

```

This project makes use of Docker to automate deployment to AWS ECS.
## Build and run locally

```shell
docker-compose build && docker-compose up
```

Navigate to `localhost` to see the running application.

## Build for production

```shell
docker-compose build --build-arg build_env="production"
```

## Build for production and deploy

```text
NB: Activate python virtual environment and pip install
the requirements before running the deploy script.
The deploy script needs to run with python3
```

```shell
docker-compose build --build-arg build_env="production"
./scripts/deploy.sh > deploy.log 2>&1 &
```
## Access the web service
The deployment scripts create a cluster with an auto-generated default security group. The default rules doesn't allow inbound traffic from the Internet and we need to change that after services are up. Run `grep security_grp deploy.log` to extract the auto-generated security group ID. Go to AWS console `AWS -> VPC -> Security Groups` and search for that ID. Add an HTTP inbound rule.

## Destroy after testing app

```shell
scripts/destroy.sh
```

### Other instructions

`instructions.txt`

### Some context here if you don't mind

The Deploy script does three basic things using three files

- `scripts/login_ecr.sh`: It configures aws on your machine with a custom profile and logs into ECR.
- `scripts/config_ecr.py`: It creates a repo on ecr and uploads created and tagged images to ECR.
- `scripts/setup_ecs.sh rustdesk-server`: Setup ECS and deploy to ECS.
