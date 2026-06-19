pipeline {
  agent any
  environment {
    IMAGE_NAME = 'sentiment-ai'
    REGISTRY   = 'ghcr.io/dspitech'
    REGISTRY_IMAGE = "${REGISTRY}/${IMAGE_NAME}"
  }
  stages {
    stage('10. Deploy Terraform') {
      steps {
        script {
          sh """
            cat > deploy.sh << 'SCRIPT_EOF'
#!/bin/sh
if [ \$(docker ps -aq -f name=sentiment-staging) ]; then docker rm -f sentiment-staging; fi
terraform init -upgrade
terraform apply -auto-approve
SCRIPT_EOF
            chmod +x deploy.sh
            docker build -t terraform-deploy -f- . <<DOCKERFILE
FROM hashicorp/terraform:latest
RUN apk add --no-cache docker-cli
COPY infra/ /terraform/
COPY deploy.sh /terraform/
WORKDIR /terraform
DOCKERFILE
            docker run --rm \
              --entrypoint /bin/sh \
              -v /var/run/docker.sock:/var/run/docker.sock \
              terraform-deploy /terraform/deploy.sh
          """
        }
      }
    }
  }
}
