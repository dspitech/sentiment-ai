pipeline {
  agent any

  environment {
    IMAGE_NAME = 'sentiment-ai'
    REGISTRY   = 'ghcr.io/dspitech'
    REGISTRY_IMAGE = "${REGISTRY}/${IMAGE_NAME}"
    SONAR_HOST_URL = 'http://4.223.165.64:9000/'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
        script { env.IMAGE_TAG = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim() }
      }
    }

    stage('Lint') {
      steps {
        sh 'docker run --rm -v $WORKSPACE:/app -w /app python:3.12-slim sh -c "pip install flake8 -q && flake8 ."'
      }
    }

    stage('Build & Test') {
      steps {
        sh '''
          docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
          docker rm -f test-runner 2>/dev/null || true
          docker run --name test-runner ${IMAGE_NAME}:${IMAGE_TAG} pytest tests/ -v --cov=src --cov-report=xml:/tmp/coverage.xml --cov-fail-under=70
          docker cp test-runner:/tmp/coverage.xml ./coverage.xml 2>/dev/null || true
          docker rm -f test-runner 2>/dev/null || true
        '''
      }
    }

    stage('SonarQube Analysis') {
      environment { SONARQUBE_TOKEN = credentials('sonar-token') }
      steps {
        sh '''
          if [ ! -d "$HOME/.sonar/sonar-scanner-5.0.1.3006-linux" ]; then
            mkdir -p $HOME/.sonar
            curl -sSLo $HOME/.sonar/sonar-scanner.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip
            unzip -q -o $HOME/.sonar/sonar-scanner.zip -d $HOME/.sonar/
          fi
          $HOME/.sonar/sonar-scanner-5.0.1.3006-linux/bin/sonar-scanner -Dsonar.host.url=$SONAR_HOST_URL -Dsonar.login=$SONARQUBE_TOKEN -Dsonar.projectKey=sentiment-ai -Dsonar.sources=src -Dsonar.python.coverage.reportPaths=coverage.xml
          sleep 5
          STATUS=$(curl -s -u "${SONARQUBE_TOKEN}:" "${SONAR_HOST_URL}api/qualitygates/project_status?projectKey=sentiment-ai" | grep -o '"status":"[^"]*"' | head -1 | cut -d'"' -f4)
          if [ "$STATUS" = "ERROR" ]; then echo "Quality Gate échoué !"; exit 1; fi
        '''
      }
    }

    stage('Push to GHCR') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'github-token', usernameVariable: 'G_USER', passwordVariable: 'G_TOKEN')]) {
          sh '''
            echo $G_TOKEN | docker login ghcr.io -u $G_USER --password-stdin
            docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${REGISTRY_IMAGE}:${IMAGE_TAG}
            docker push ${REGISTRY_IMAGE}:${IMAGE_TAG}
          '''
        }
      }
    }

    stage('Terraform Apply') {
      when { branch 'main' }
      steps {
        dir('infra') {
          sh '''
            docker run --rm -v $(pwd):/terraform -v $HOME/.aws:/root/.aws -w /terraform \
              -e TF_VAR_image_tag=${IMAGE_TAG} \
              hashicorp/terraform:latest init
              
            docker run --rm -v $(pwd):/terraform -v $HOME/.aws:/root/.aws -w /terraform \
              -e TF_VAR_image_tag=${IMAGE_TAG} \
              hashicorp/terraform:latest apply -auto-approve
          '''
        }
      }
    }
  }
}
