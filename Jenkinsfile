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
        script {
          env.IMAGE_TAG = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
        }
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

    stage('Build') {
      steps {
        sh 'docker build -t $IMAGE_NAME:$IMAGE_TAG .'
      }
    }

    stage('Test') {
      steps {
        sh '''
          docker run --rm \
            $IMAGE_NAME:$IMAGE_TAG \
            pytest tests/ -v
        '''
      }
    }

  }

  post {
    success {
      echo "Pipeline OK: ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
    }
    failure {
      echo "Pipeline FAILED"
    }
  }
}
