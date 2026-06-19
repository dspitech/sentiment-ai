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
      }

      steps {
        withSonarQubeEnv(installationName: 'sonarqube') {
          sh '''
            # Exécution avec les IDs (UID:GID) exacts de l'utilisateur Jenkins hôte
            docker run --rm \
              --user $(id -u):$(id -g) \
              -v $WORKSPACE:/usr/src \
              -w /usr/src \
              -e SONAR_HOST_URL=$SONAR_HOST_URL \
              -e SONAR_TOKEN=$SONARQUBE_TOKEN \
              sonarsource/sonar-scanner-cli:latest \
              sonar-scanner \
                -Dsonar.projectKey=sentiment-ai \
                -Dsonar.projectName=SentimentAI \
                -Dsonar.projectBaseDir=/usr/src \
                -Dsonar.working.directory=/usr/src/.scannerwork \
                -Dsonar.sources=. \
                -Dsonar.python.version=3.11 \
                -Dsonar.python.coverage.reportPaths=coverage.xml \
                -Dsonar.sourceEncoding=UTF-8
          '''
          
          timeout(time: 15, unit: 'MINUTES') {
            waitForQualityGate abortPipeline: true
          }
        }
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
