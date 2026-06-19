#!/bin/sh
terraform init -upgrade
terraform import docker_network.cicd $(docker network inspect cicd-network --format='{{.Id}}') 2>/dev/null || true
terraform apply -auto-approve
