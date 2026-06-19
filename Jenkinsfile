pipeline {
  agent any

  environment {
    IMAGE_NAME = 'sentiment-ai'
    REGISTRY   = 'ghcr.io/dspitech'
    REGISTRY_IMAGE = "${REGISTRY}/${IMAGE_NAME}"
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
        script {
          env.IMAGE_TAG = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
        }
      }
    }

    stage('Info') {
      steps {
        sh 'git log --oneline -3'
        sh 'echo "Workspace OK"'
      }
    }

    stage('Lint') {
      steps {
        sh '''
          docker run --rm \
            -v $WORKSPACE:/app \
            -w /app \
            python:3.12-slim \
            sh -c "pip install flake8 -q && flake8 ."
        '''
      }
    }

    stage('Build & Test') {
      steps {
        sh '''
          IMAGE_NAME=sentiment-ai

          docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

          docker rm -f test-runner 2>/dev/null || true

          set +e

          docker run \
            -e CI=true \
            --name test-runner \
            ${IMAGE_NAME}:${IMAGE_TAG} \
            pytest tests/ -v \
              --cov=src \
              --cov-report=xml:/tmp/coverage.xml \
              --cov-report=term-missing \
              --cov-fail-under=70

          TEST_EXIT_CODE=$?
          set -e

          docker cp test-runner:/tmp/coverage.xml ./coverage.xml 2>/dev/null || true

          docker rm -f test-runner 2>/dev/null || true

          exit $TEST_EXIT_CODE
        '''
      }

      post {
        failure {
          echo 'Tests échoués ou coverage < 70%'
        }
      }
    }

    stage('SonarQube Analysis & Quality Gate') {
      environment {
        SONARQUBE_TOKEN = credentials('sonar-token')
        SONAR_HOST_URL  = 'http://4.223.165.64:9000/'
      }

      steps {
        sh '''
          if [ ! -d "$HOME/.sonar/sonar-scanner-5.0.1.3006-linux" ]; then
            echo "Téléchargement du Sonar Scanner natif..."
            mkdir -p $HOME/.sonar
            curl -sSLo $HOME/.sonar/sonar-scanner.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip
            unzip -q -o $HOME/.sonar/sonar-scanner.zip -d $HOME/.sonar/
          fi

          echo "Exécution du scan natif..."
          $HOME/.sonar/sonar-scanner-5.0.1.3006-linux/bin/sonar-scanner \
            -Dsonar.host.url=$SONAR_HOST_URL \
            -Dsonar.login=$SONARQUBE_TOKEN \
            -Dsonar.projectKey=sentiment-ai \
            -Dsonar.projectName=SentimentAI \
            -Dsonar.sources=src \
            -Dsonar.python.version=3.11 \
            -Dsonar.python.coverage.reportPaths=coverage.xml \
            -Dsonar.sourceEncoding=UTF-8

          echo "Vérification du Quality Gate..."
          sleep 5
          STATUS=$(curl -s -u "${SONARQUBE_TOKEN}:" "${SONAR_HOST_URL}api/qualitygates/project_status?projectKey=sentiment-ai" | grep -o '"status":"[^"]*"' | head -1 | cut -d'"' -f4)
          echo "Le statut du Quality Gate SonarQube est : $STATUS"
          
          if [ "$STATUS" = "ERROR" ]; then
            echo "Le Quality Gate a échoué !"
            exit 1
          fi
        '''
      }
    }

    stage('Push to GHCR') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'github-token',
          usernameVariable: 'GITHUB_USER',
          passwordVariable: 'GITHUB_TOKEN'
        )]) {
          sh '''
            echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USER --password-stdin

            docker tag sentiment-ai:${IMAGE_TAG} ${REGISTRY_IMAGE}:${IMAGE_TAG}
            docker tag sentiment-ai:${IMAGE_TAG} ${REGISTRY_IMAGE}:latest

            docker push ${REGISTRY_IMAGE}:${IMAGE_TAG}
            docker push ${REGISTRY_IMAGE}:latest
          '''
        }
      }
    }

  }

  post {
    success {
      echo "Pipeline OK - Image pushed: ${REGISTRY_IMAGE}:${IMAGE_TAG}"
    }
    failure {
      echo "Pipeline FAILED"
    }
  }
}
