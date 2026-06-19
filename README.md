# test webhook jenkins
# Test déclenchement pipeline Jenkins
# Test Vendredi : déclenchement pipeline Jenkins

## Pipeline CI/CD - SentimentAI
Ce projet utilise un pipeline Jenkins complet automatisé en 8 étapes :
1. Checkout SCM
2. Info
3. Lint (flake8)
4. Build & Test (pytest + coverage)
5. SonarQube Analysis & Quality Gate
6. Security Scan (Trivy avec blocage sur CRITICAL/HIGH)
7. Push to GHCR
8. Post Actions
