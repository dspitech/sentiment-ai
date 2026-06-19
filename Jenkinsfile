pipeline {
  agent any

  environment {
    IMAGE_NAME = 'sentiment-ai'
    REGISTRY   = 'ghcr.io/dspitech'
    REGISTRY_IMAGE = "${REGISTRY}/${IMAGE_NAME}"
    SONAR_HOST_URL = 'http://4.223.165.64:9000/'
    SONAR_USER_TOKEN = 'sqa_5e07e6f28100271b73d2b76bcbc49d72e2bc70ee'
  }

  stages {
    stage('1. Checkout') { steps { checkout scm; script { env.IMAGE_TAG = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim() } } }
    stage('2. Lint') { steps { sh 'docker run --rm -v $WORKSPACE:/app -w /app python:3.12-slim sh -c "pip install flake8 -q && flake8 ."' } }
    stage('3. Build') { steps { sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ." } }
    stage('4. Test') { steps { sh "docker run --name test-runner ${IMAGE_NAME}:${IMAGE_TAG} pytest tests/ -v --cov=src --cov-report=xml:/tmp/coverage.xml --cov-fail-under=70" } }
    stage('5. Extract Coverage') { steps { sh "docker cp test-runner:/tmp/coverage.xml ./coverage.xml && docker rm -f test-runner" } }
    
    stage('6. Install Scanner') { 
      steps { 
        sh '''
          if [ ! -d "$HOME/.sonar/bin" ]; then
            mkdir -p $HOME/.sonar
            curl -sSL https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip -o $HOME/.sonar/scanner.zip
            unzip -q -o $HOME/.sonar/scanner.zip -d $HOME/.sonar/
            mv $HOME/.sonar/sonar-scanner-5.0.1.3006-linux/* $HOME/.sonar/
            rm $HOME/.sonar/scanner.zip
          fi
        ''' 
      } 
    }
    
    stage('7. Sonar Analysis') { steps { sh '$HOME/.sonar/bin/sonar-scanner -Dsonar.host.url=$SONAR_HOST_URL -Dsonar.login=$SONAR_USER_TOKEN -Dsonar.projectKey=sentiment-ai -Dsonar.sources=src -Dsonar.python.coverage.reportPaths=coverage.xml' } }
    
    stage('8. Quality Gate') { 
      steps { 
        sh '''
          STATUS=$(curl -s -u "$SONAR_USER_TOKEN:" "${SONAR_HOST_URL}api/qualitygates/project_status?projectKey=sentiment-ai" | grep -o '"status":"[^"]*"' | head -1 | cut -d'"' -f4)
          echo "Status actuel: $STATUS"
          if [ "$STATUS" = "ERROR" ]; then
            echo "Quality Gate en échec !"
            exit 1
          fi
        ''' 
      } 
    }
    
    stage('9. Push Image') { steps { sh 'docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${REGISTRY_IMAGE}:${IMAGE_TAG} && docker push ${REGISTRY_IMAGE}:${IMAGE_TAG}' } }
    
    stage('10. Deploy Terraform') {
      steps {
        dir('infra') {
          sh '''
            docker run --rm -v $(pwd):/terraform -v $HOME/.aws:/root/.aws -w /terraform -e TF_VAR_image_tag=${IMAGE_TAG} hashicorp/terraform:latest init
            docker run --rm -v $(pwd):/terraform -v $HOME/.aws:/root/.aws -w /terraform -e TF_VAR_image_tag=${IMAGE_TAG} hashicorp/terraform:latest apply -auto-approve
          '''
        }
      }
    }
  }
}
