#!/bin/sh
docker rm -f sentiment-staging prometheus grafana 2>/dev/null || true
terraform init -upgrade
terraform apply -auto-approve
