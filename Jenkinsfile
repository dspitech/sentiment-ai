pipeline {
    agent any
    environment {
        SONAR_SCANNER_HOME = "/opt/sonar-scanner"
    }
    stages {
        stage('Install SonarScanner') {
            steps {
                sh '''
                if [ ! -d "/opt/sonar-scanner" ]; then
                    sudo mkdir -p /opt/sonar-scanner
                    sudo wget -q https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip -O /tmp/sonar.zip
                    sudo unzip -q /tmp/sonar.zip -d /opt/
                    sudo mv /opt/sonar-scanner-5.0.1.3006-linux/* /opt/sonar-scanner/
                fi
                '''
            }
        }
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonarqube') {
                    withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                        // Scan direct (plus de Docker, donc plus de problème de permissions)
                        sh "/opt/sonar-scanner/bin/sonar-scanner -Dsonar.projectKey=sentiment-ai-new -Dsonar.sources=. -Dsonar.host.url=\$SONAR_HOST_URL -Dsonar.login=${SONAR_TOKEN}"
                    }
                }
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
    }
}
