pipeline {
  agent any

  environment {
    IMAGE_NAME = 'sentiment-ai'
    REGISTRY   = 'ghcr.io/dspitech'
    REGISTRY_IMAGE = "${REGISTRY}/${IMAGE_NAME}"
    SONAR_HOST_URL = 'http://4.223.165.64:9000/'
    SONAR_USER_TOKEN = 'sqa_5e07e6f28100271b73d2b76bcbc49d72e2bc70ee'
    DOCKER_HOST_IP  = '172.17.0.1'
  }

  stages {
    stage('1. Checkout') { steps { checkout scm; script { env.IMAGE_TAG = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim() } } }
    stage('2. Lint') { steps { sh 'docker run --rm -v $WORKSPACE:/app -w /app python:3.12-slim sh -c "pip install flake8 -q && flake8 ."' } }
    stage('3. Build') { steps { sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ." } }
    stage('4. Test') { steps { sh "docker run --name test-runner ${IMAGE_NAME}:${IMAGE_TAG} pytest tests/ -v --cov=src --cov-report=xml:/tmp/coverage.xml --cov-fail-under=70" } }
    stage('5. Extract Coverage') { steps { sh "docker cp test-runner:/tmp/coverage.xml ./coverage.xml && docker rm -f test-runner" } }
    stage('6. Install Scanner') { steps { sh 'if [ ! -d "$HOME/.sonar/bin" ]; then mkdir -p $HOME/.sonar; curl -sSL https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip -o $HOME/.sonar/scanner.zip; unzip -q -o $HOME/.sonar/scanner.zip -d $HOME/.sonar/; mv $HOME/.sonar/sonar-scanner-5.0.1.3006-linux/* $HOME/.sonar/; rm $HOME/.sonar/scanner.zip; fi' } }
    stage('7. Sonar Analysis') { steps { sh '$HOME/.sonar/bin/sonar-scanner -Dsonar.host.url=$SONAR_HOST_URL -Dsonar.login=$SONAR_USER_TOKEN -Dsonar.projectKey=sentiment-ai -Dsonar.sources=src -Dsonar.python.coverage.reportPaths=coverage.xml' } }
    stage('8. Quality Gate') { steps { sh 'STATUS=$(curl -s -u "$SONAR_USER_TOKEN:" "${SONAR_HOST_URL}api/qualitygates/project_status?projectKey=sentiment-ai" | grep -o \'"status":"[^"]*"\'); if [ "$STATUS" = \'"status":"ERROR"\' ]; then exit 1; fi' } }
    stage('9. Push Image') { steps { sh 'docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${REGISTRY_IMAGE}:${IMAGE_TAG} && docker push ${REGISTRY_IMAGE}:${IMAGE_TAG}' } }

    stage('10. Deploy Terraform') {
      steps {
        script {
          sh """
            docker build -t terraform-deploy -f- . <<DOCKERFILE
FROM hashicorp/terraform:latest
RUN apk add --no-cache docker-cli
COPY infra/      /terraform/
COPY monitoring/ /monitoring/
COPY deploy.sh   /terraform/
RUN rm -f /terraform/terraform.tfstate /terraform/terraform.tfstate.backup /terraform/.terraform.lock.hcl
WORKDIR /terraform
DOCKERFILE
            docker run --rm \\
              --entrypoint /bin/sh \\
              -v /var/run/docker.sock:/var/run/docker.sock \\
              -v \${HOME}/.aws:/root/.aws \\
              -e TF_VAR_image_tag=${IMAGE_TAG} \\
              terraform-deploy /terraform/deploy.sh
          """
        }
      }
    }

    stage('11. Smoke Test') {
      when { expression { env.GIT_BRANCH ==~ /.*main/ } }
      steps {
        sh '''
          echo "Attente démarrage (10s)..."
          sleep 10
          curl -f http://${DOCKER_HOST_IP}:8001/health || exit 1
          echo "/health OK"
          curl -s http://${DOCKER_HOST_IP}:8001/metrics | grep -q sentiment_predictions_total || exit 1
          echo "/metrics OK"
          sleep 20
          PROM_RESULT=$(curl -s "http://${DOCKER_HOST_IP}:9090/api/v1/query?query=up%7Bjob%3D%27sentiment-ai%27%7D")
          echo "Prometheus response: $PROM_RESULT"
          echo "$PROM_RESULT" | grep -q '"value"' || exit 1
          echo "Prometheus scrape OK"
          curl -f http://${DOCKER_HOST_IP}:3000/api/health || exit 1
          echo "Smoke Test OK : Tous les services sont opérationnels."
        '''
      }
      post {
        failure {
          sh 'docker logs prometheus || true'
          sh 'docker logs sentiment-staging || true'
        }
      }
    }
  }
}
