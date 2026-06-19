#!/bin/sh
for container in sentiment-staging prometheus grafana; do
    if docker ps -aq -f name="^${container}$" | grep -q .; then
        docker rm -f "${container}"
    fi
done
terraform init -upgrade
terraform apply -auto-approve
