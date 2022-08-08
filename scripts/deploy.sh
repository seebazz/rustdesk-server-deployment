#!/usr/bin/env bash

source scripts/.env

# loging to ecr
scripts/login_ecr.sh

# setup ecr and upload to ecr
python3 scripts/config_ecr.py

# setup ecs and deploy to ecs fargate
scripts/setup_ecs.sh
