pipeline {
    agent any
    environment {
        IMAGE_NAME = "sentiment-ai"
        REGISTRY   = "ghcr.io/dspitech"
        IMAGE_TAG  = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
    }
    stages {
        stage('1. Checkout') { steps { checkout scm } }
        stage('2. Lint') { steps { sh 'docker run --rm -v ${WORKSPACE}:/app -w /app python:3.12-slim sh -c "pip install flake8 -q && flake8 ."' } }
        stage('3. IaC Validate') { steps { dir('infra') { sh 'docker run --rm -v $(pwd):/terraform -w /terraform hashicorp/terraform:latest init -backend=false && docker run --rm -v $(pwd):/terraform -w /terraform hashicorp/terraform:latest validate' } } }
        stage('4. Build') { steps { sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ." } }
        stage('5. Test') { steps { sh "docker rm -f test-runner 2>/dev/null || true && docker run --name test-runner ${IMAGE_NAME}:${IMAGE_TAG} pytest tests/ -v --cov=. --cov-report=xml:/tmp/coverage.xml --cov-fail-under=70 && docker cp test-runner:/tmp/coverage.xml ./coverage.xml && docker rm -f test-runner" } }
        stage('6. SonarQube') { 
            steps { 
                sh 'rm -rf ${WORKSPACE}/.scannerwork'
                withSonarQubeEnv('sonarqube') {
                    withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                        // Changement de projectKey pour 'sentiment-ai-new' afin de contourner le cache SonarQube
                        sh """docker run --rm -v ${WORKSPACE}:/usr/src -w /usr/src sonarsource/sonar-scanner-cli:latest sonar-scanner -Dsonar.projectKey=sentiment-ai-new -Dsonar.sources=. -Dsonar.python.coverage.reportPaths=coverage.xml -Dsonar.host.url=\$SONAR_HOST_URL -Dsonar.login=${SONAR_TOKEN}"""
                    }
                }
            } 
        }
        stage('7. Quality Gate') { steps { timeout(time: 15, unit: 'MINUTES') { waitForQualityGate abortPipeline: true } } }
        stage('8. Security Scan') { steps { sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v trivy-cache:/root/.cache/trivy aquasec/trivy:latest image --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 ${IMAGE_NAME}:${IMAGE_TAG}" } }
        stage('9. Push') { when { branch 'main' } steps { withCredentials([usernamePassword(credentialsId: 'github-token', usernameVariable: 'REG_USER', passwordVariable: 'REG_PASS')]) { sh "echo \$REG_PASS | docker login ghcr.io -u \$REG_USER --password-stdin && docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} && docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}" } } }
        stage('10. IaC Apply') { when { branch 'main' } steps { dir('infra') { sh "docker run --rm -v \$(pwd):/terraform -w /terraform -v /var/run/docker.sock:/var/run/docker.sock -e TF_VAR_image_tag=${IMAGE_TAG} hashicorp/terraform:latest init && docker run --rm -v \$(pwd):/terraform -w /terraform -v /var/run/docker.sock:/var/run/docker.sock -e TF_VAR_image_tag=${IMAGE_TAG} hashicorp/terraform:latest apply -auto-approve" } } }
    }
    post { always { cleanWs() } }
}
