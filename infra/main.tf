# infra/main.tf

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

# Configuration du provider Docker utilisant le socket local
provider "docker" {
  # L'emplacement /var/run/docker.sock est le standard pour les systèmes Linux
  host = "unix:///var/run/docker.sock"
}

# Suite de infra/main.tf

# Réseau Docker partagé Jenkins / SonarQube / SentimentAI
resource "docker_network" "cicd" {
  name = "cicd-network"
}

# Image Docker SentimentAI -- image locale buildée par Jenkins
resource "docker_image" "sentiment" {
  name         = "sentiment-ai:${var.image_tag}"
  keep_locally = true
}

# Conteneur staging
resource "docker_container" "sentiment_staging" {
  name    = var.container_name
  image   = docker_image.sentiment.image_id
  restart = "unless-stopped"

  networks_advanced {
    name = docker_network.cicd.name
  }

  ports {
    internal = 8000
    external = var.app_port
  }

  env = [
    "ENV=staging",
    "LOG_LEVEL=INFO",
  ]

  # Attention : vérifie que 'curl' est installé dans ton image Docker
  healthcheck {
    test     = ["CMD", "curl", "-f", "http://localhost:8000/health"]
    interval = "30s"
    timeout  = "10s"
    retries  = 3
  }
}
