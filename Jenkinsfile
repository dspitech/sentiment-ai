pipeline {
    agent any
    environment {
        IMAGE_NAME = "sentiment-ai"
        REGISTRY   = "ghcr.io/dspitech"
        IMAGE_TAG  = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
        SONAR_URL  = "http://4.223.165.64:9000"
    }
    stages {
        stage('1. Checkout') {
            steps { checkout scm }
        }

        stage('2. Lint') {
            steps {
                sh 'docker run --rm -v ${WORKSPACE}:/app -w /app python:3.12-slim sh -c "pip install flake8 -q && flake8 ."'
            }
        }

        stage('3. IaC Validate') {
            steps {
                dir('infra') {
                    sh '''
                        docker run --rm -v $(pwd):/terraform -w /terraform hashicorp/terraform:latest init -backend=false
                        docker run --rm -v $(pwd):/terraform -w /terraform hashicorp/terraform:latest validate
                    '''
                }
            }
        }

        stage('4. Build') {
            steps {
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('5. Test') {
            steps {
                sh """
                    docker rm -f test-runner 2>/dev/null || true
                    docker run --name test-runner ${IMAGE_NAME}:${IMAGE_TAG} \
                        pytest tests/ -v --cov=. --cov-report=xml:/tmp/coverage.xml --cov-fail-under=70
                    docker cp test-runner:/tmp/coverage.xml ./coverage.xml
                    docker rm -f test-runner
                """
            }
        }

        stage('6. SonarQube Analysis') {
            steps {
                sh 'rm -rf ${WORKSPACE}/.scannerwork'
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                    sh """
                        docker run --rm \
                            -v ${WORKSPACE}:/usr/src \
                            -w /usr/src \
                            sonarsource/sonar-scanner-cli:latest sonar-scanner \
                            -Dsonar.projectKey=sentiment-ai-new \
                            -Dsonar.sources=. \
                            -Dsonar.python.coverage.reportPaths=coverage.xml \
                            -Dsonar.host.url=${SONAR_URL} \
                            -Dsonar.login=\$SONAR_TOKEN \
                            -Dsonar.working.directory=/tmp/.scannerwork
                    """

                    // Récupérer le task ID depuis le rapport généré dans le workspace
                    script {
                        def taskId = sh(
                            script: "grep ceTaskId ${WORKSPACE}/.sonar/report-task.txt | cut -d= -f2",
                            returnStdout: true
                        ).trim()

                        echo "SonarQube task ID: ${taskId}"

                        // Poller jusqu'à ce que le task soit terminé
                        timeout(time: 10, unit: 'MINUTES') {
                            waitUntil(initialRecurrencePeriod: 5000) {
                                def status = sh(
                                    script: """
                                        curl -s -u \$SONAR_TOKEN: \
                                            "${SONAR_URL}/api/ce/task?id=${taskId}" \
                                            | grep -o '"status":"[^"]*"' \
                                            | cut -d'"' -f4
                                    """,
                                    returnStdout: true
                                ).trim()
                                echo "Task status: ${status}"
                                if (status == 'FAILED' || status == 'CANCELLED') {
                                    error("SonarQube task ${taskId} ended with status: ${status}")
                                }
                                return status == 'SUCCESS'
                            }
                        }

                        // Vérifier le Quality Gate
                        def qgStatus = sh(
                            script: """
                                curl -s -u \$SONAR_TOKEN: \
                                    "${SONAR_URL}/api/qualitygates/project_status?projectKey=sentiment-ai-new" \
                                    | grep -o '"status":"[^"]*"' \
                                    | head -1 \
                                    | cut -d'"' -f4
                            """,
                            returnStdout: true
                        ).trim()

                        echo "Quality Gate status: ${qgStatus}"
                        if (qgStatus != 'OK') {
                            error("Quality Gate FAILED: ${qgStatus}. See ${SONAR_URL}/dashboard?id=sentiment-ai-new")
                        }
                    }
                }
            }
        }

        stage('7. Security Scan') {
            steps {
                sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v trivy-cache:/root/.cache/trivy aquasec/trivy:latest image --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 ${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        stage('8. Push') {
            when { branch 'main' }
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'github-token',
                    usernameVariable: 'REG_USER',
                    passwordVariable: 'REG_PASS'
                )]) {
                    sh """
                        echo \$REG_PASS | docker login ghcr.io -u \$REG_USER --password-stdin
                        docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                    """
                }
            }
        }

        stage('9. IaC Apply') {
            when { branch 'main' }
            steps {
                dir('infra') {
                    sh """
                        docker run --rm \
                            -v \$(pwd):/terraform \
                            -w /terraform \
                            -v /var/run/docker.sock:/var/run/docker.sock \
                            -e TF_VAR_image_tag=${IMAGE_TAG} \
                            hashicorp/terraform:latest init
                        docker run --rm \
                            -v \$(pwd):/terraform \
                            -w /terraform \
                            -v /var/run/docker.sock:/var/run/docker.sock \
                            -e TF_VAR_image_tag=${IMAGE_TAG} \
                            hashicorp/terraform:latest apply -auto-approve
                    """
                }
            }
        }
    }
    post { always { cleanWs() } }
}
