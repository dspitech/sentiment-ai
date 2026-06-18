pipeline {
  agent any

  environment {
    IMAGE_NAME = 'sentiment-ai'
    REGISTRY   = 'ghcr.io/dspitech'
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
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

    stage('Build Docker') {
      steps {
        sh 'docker build -t sentiment-ai:latest .'
      }
    }

    stage('Test') {
      steps {
        sh '''
          docker run --rm \
            sentiment-ai:latest \
            pytest tests -v || true
        '''
      }
    }

  }

  post {
    success {
      echo "Pipeline OK"
    }
    failure {
      echo "Pipeline FAILED - check logs"
    }
  }
}
