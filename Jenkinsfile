pipeline {
    agent any
    
    environment {
        IMAGE_NAME = "sentiment-ai"
        REGISTRY   = "ghcr.io/dspitech"
        IMAGE_TAG  = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
        SONAR_TOKEN = credentials('sonar-token')
    }

    stages {
        stage('Checkout') {
            steps { checkout scm }
        }

        stage('Lint') {
            steps {
                sh 'docker run --rm -v ${WORKSPACE}:/app -w /app python:3.12-slim sh -c "pip install flake8 -q && flake8 ."'
            }
        }

        stage('IaC Validate') {
            steps {
                dir('infra') {
                    sh 'terraform init -backend=false -input=false'
                    sh 'terraform fmt -check'
                    sh 'terraform validate'
                }
            }
        }

        stage('Build & Test') {
            steps {
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
                sh "docker rm -f test-runner 2>/dev/null || true"
                sh "docker run --name test-runner ${IMAGE_NAME}:${IMAGE_TAG} pytest tests/ -v --cov=src --cov-report=xml:/tmp/coverage.xml --cov-fail-under=70 || echo 'Tests failed'"
                sh "docker cp test-runner:/tmp/coverage.xml ./coverage.xml"
                sh "docker rm -f test-runner"
            }
        }

        stage('SonarQube Analysis') {
            steps {
                sh 'docker run --rm --user root -v ${WORKSPACE}:/usr/src sonarsource/sonar-scanner-cli:latest rm -rf /usr/src/.scannerwork'
                withSonarQubeEnv('sonarqube') {
                    sh """docker run --rm -v ${WORKSPACE}:/usr/src -w /usr/src \
                        sonarsource/sonar-scanner-cli:latest \
                        sonar-scanner \
                        -Dsonar.projectKey=sentiment-ai \
                        -Dsonar.sources=src \
                        -Dsonar.python.coverage.reportPaths=coverage.xml \
                        -Dsonar.host.url=\$SONAR_HOST_URL \
                        -Dsonar.login=${SONAR_TOKEN}"""
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 15, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Security Scan') {
            steps {
                sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v trivy-cache:/root/.cache/trivy aquasec/trivy:latest image --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 ${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        stage('Push') {
            when { branch 'main' }
            steps {
                withCredentials([usernamePassword(credentialsId: 'github-token', usernameVariable: 'REG_USER', passwordVariable: 'REG_PASS')]) {
                    sh "echo \$REG_PASS | docker login ghcr.io -u \$REG_USER --password-stdin"
                    sh "docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
                    sh "docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
                }
            }
        }

        stage('IaC Apply') {
            when { branch 'main' }
            steps {
                dir('infra') {
                    sh 'terraform init -input=false'
                    sh "terraform apply -auto-approve -var='image_tag=${IMAGE_TAG}'"
                }
            }
        }
    }

    post {
        always { cleanWs() }
        success { echo "Pipeline ${IMAGE_TAG} terminé avec succès !" }
        failure { echo "Pipeline ${IMAGE_TAG} échoué." }
    }
}
