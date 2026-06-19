pipeline {
    agent any
    stages {
        // ... étapes 1 à 5 inchangées
        
        stage('6. SonarQube Analysis') { 
            steps { 
                script {
                    // Utilise la configuration de serveur "sonarqube" définie dans Jenkins
                    withSonarQubeEnv('sonarqube') {
                        // Utilise l'outil "sonar-scanner" configuré dans Tools
                        // S'il n'est pas configuré, le plugin peut utiliser un scanner automatique
                        sh """sonar-scanner \
                            -Dsonar.projectKey=sentiment-ai-new \
                            -Dsonar.sources=. \
                            -Dsonar.python.coverage.reportPaths=coverage.xml \
                            -Dsonar.host.url=$SONAR_HOST_URL \
                            -Dsonar.login=$SONAR_AUTH_TOKEN"""
                    }
                    // Maintenant, Jenkins "voit" le rapport car il a été généré localement
                    timeout(time: 10, unit: 'MINUTES') {
                        waitForQualityGate abortPipeline: true
                    }
                }
            } 
        }
        // ... étapes 8 et 9
    }
}
