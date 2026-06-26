# Lab DevOps - Project management & agility - Scrum

### Nom : Lo | Prénom : Pape | Email : pape.lo@estiam.com

<div align="center">

![Jenkins](https://img.shields.io/badge/Jenkins-D24939?style=for-the-badge&logo=jenkins&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![GitHub](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white)
![Python](https://img.shields.io/badge/Python_3.12-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Groovy](https://img.shields.io/badge/Groovy-4298B8?style=for-the-badge&logo=apachegroovy&logoColor=white)
![ngrok](https://img.shields.io/badge/ngrok-1F1E37?style=for-the-badge&logo=ngrok&logoColor=white)

**Pipeline CI/CD Jenkins automatisé pour SentimentAI · Docker-out-of-Docker**
*TP2 · Formation DevOps · Pipeline as Code · Build · Test · Push*

[Objectif](#contexte-et-objectifs) • [Glossaire](#glossaire--définitions-clés) • [Architecture](#architecture-du-pipeline) • [Jenkins](#partie-1--installer-jenkins-via-docker) • [Jenkinsfile](#partie-2--écrire-le-jenkinsfile) • [Job](#partie-3--créer-et-exécuter-le-job-jenkins) • [Webhook](#partie-4--webhook--déclenchement-automatique) • [Synthèse](#partie-5--questions-de-synthèse)

</div>

# TP 1 - Git & Docker

> **Objectif :** Repository Git public + image Docker fonctionnelle  
> **Outils :** Git, Docker, Docker Compose, Make  
> **Projet :** SentimentAI - API REST d'analyse de sentiments (FastAPI/Python)

---

## Contexte

Vous intégrez **StartupIA**, une entreprise qui développe une plateforme SaaS d'analyse de sentiments pour les avis clients (e-commerce, réseaux sociaux, CRM). Votre mission est de mettre en place l'infrastructure DevOps de l'API **SentimentAI** depuis le dépôt Git jusqu'à l'image Docker, en préparation du pipeline CI/CD automatisé construit dans les TPs suivants.

SentimentAI est une API REST développée en FastAPI/Python. Elle reçoit un texte en entrée, l'analyse et retourne un label (`POSITIF`, `NÉGATIF` ou `NEUTRE`) accompagné d'un score de confiance entre 0 et 1.

### Roadmap de la formation

| TP | Contenu |
|----|---------|
| **TP 1** ← vous êtes ici | Git, Docker Compose, SentimentAI v0.1 |
| TP 2 | Jenkins pipeline - build, test, push |
| TP 3 | SonarQube, Trivy - Qualité & Sécurité |
| TP 4 | Terraform IaC, Docker provider |
| TP 5 | Monitoring, Prometheus, Grafana |

---

## 0. Notions fondamentales

> Cette section présente les concepts clés mobilisés dans ce TP. Elle est à lire avant de commencer les manipulations.

### 0.1 DevOps - Définition

**DevOps** (contraction de *Development* et *Operations*) est une culture et un ensemble de pratiques visant à unifier le développement logiciel et l'exploitation des systèmes. L'objectif est de raccourcir le cycle de livraison tout en améliorant la fiabilité des déploiements.

Les quatre piliers du DevOps sont :

| Pilier | Description |
|--------|-------------|
| **CI** - Intégration Continue | Fusionner fréquemment le code et le tester automatiquement |
| **CD** - Déploiement Continu | Livrer automatiquement chaque version validée en production |
| **Infrastructure as Code** | Gérer les serveurs et réseaux via du code versionné (Terraform) |
| **Monitoring** | Observer le comportement du système en production (Prometheus, Grafana) |

---

### 0.2 Git - Concepts clés

**Git** est un système de contrôle de version distribué créé par Linus Torvalds en 2005. Il permet de suivre l'évolution d'un projet dans le temps, de collaborer à plusieurs sans écraser le travail des autres, et de revenir à n'importe quel état passé du code.

#### Vocabulaire essentiel

| Terme | Définition |
|-------|------------|
| **Repository (repo)** | Dossier versionné contenant tout l'historique du projet sous forme de snapshots |
| **Commit** | Instantané (snapshot) de l'état du projet à un instant T, identifié par un hash SHA-1 unique |
| **Staging area** | Zone intermédiaire où l'on prépare les fichiers avant de les inclure dans un commit (`git add`) |
| **Branch** | Ligne de développement parallèle permettant de travailler en isolation sans toucher `main` |
| **Remote** | Copie distante du repository hébergée sur un serveur (GitHub, GitLab, Bitbucket…) |
| **Clone** | Copie complète d'un repository distant sur la machine locale, historique inclus |
| **Push** | Envoi des commits locaux vers le repository distant |
| **Pull** | Récupération et intégration des commits distants dans la branche locale |

#### Le cycle de vie d'un fichier Git

```
Untracked  ──git add──►  Staged  ──git commit──►  Committed
                                                       │
                                               git push │
                                                       ▼
                                                   Remote (GitHub)
```

>  **Explication du schéma :** Un fichier passe par trois états avant d'être partagé. `git add` le place dans la *staging area* (zone de préparation). `git commit` crée un instantané permanent dans l'historique local. `git push` envoie cet instantané vers le serveur distant (GitHub).

#### Conventional Commits

La convention **Conventional Commits** normalise les messages de commit pour les rendre lisibles par des humains et des outils (génération automatique de changelogs, déclenchement de pipelines).

Format : `<type>(<scope optionnel>): <description>`

| Type | Usage |
|------|-------|
| `feat` | Nouvelle fonctionnalité |
| `fix` | Correction de bug |
| `docs` | Modification de documentation |
| `chore` | Tâche de maintenance (CI, deps…) |
| `test` | Ajout ou modification de tests |
| `refactor` | Réécriture de code sans changement de comportement |

Exemple : `feat: initialiser la structure SentimentAI`

#### Tags Git

Un **tag** est un pointeur nommé et permanent vers un commit précis. Il sert à marquer des versions livrables du logiciel (ex. `v0.1.0`, `v1.2.3`).

- **Tag léger** (`git tag v0.1.0`) : simple alias vers un commit, sans métadonnées.
- **Tag annoté** (`git tag -a v0.1.0 -m "message"`) : objet Git complet contenant auteur, date, message et signature GPG optionnelle. **Toujours préférer les tags annotés en production.**

---

### 0.3 Docker - Concepts clés

**Docker** est une plateforme de conteneurisation qui permet d'empaqueter une application avec toutes ses dépendances dans une unité isolée et portable appelée **conteneur**.

#### Différence entre une VM et un conteneur

| | Machine Virtuelle (VM) | Conteneur Docker |
|---|---|---|
| **Isolation** | Système d'exploitation complet | Processus isolé partageant le noyau hôte |
| **Taille** | Plusieurs Go | Quelques dizaines à centaines de Mo |
| **Démarrage** | Minutes | Secondes |
| **Portabilité** | Limitée | Totale : "works everywhere" |
| **Performance** | Overhead hyperviseur | Proche du natif |

#### Vocabulaire essentiel

| Terme | Définition |
|-------|------------|
| **Image** | Modèle immuable et versionné d'un conteneur, construit à partir d'un `Dockerfile`. Analogue à une classe en POO. |
| **Conteneur** | Instance en cours d'exécution d'une image. Analogue à un objet instancié depuis une classe. |
| **Dockerfile** | Fichier texte décrivant les étapes de construction d'une image, du plus stable au plus volatile. |
| **Layer (couche)** | Chaque instruction `RUN`, `COPY`, `ADD` dans un Dockerfile crée une couche immuable mise en cache. |
| **Registry** | Dépôt distant d'images Docker (Docker Hub, GitHub Container Registry, AWS ECR…). |
| **Tag** | Étiquette identifiant une version d'une image (ex. `sentiment-ai:latest`, `sentiment-ai:v0.1.0`). |
| **Volume** | Mécanisme de persistance des données au-delà du cycle de vie d'un conteneur. |
| **Port mapping** | Redirection d'un port hôte vers un port conteneur (`-p 8080:8000` : hôte→conteneur). |

#### Le système de cache par layers

Docker met en cache chaque couche du `Dockerfile`. Si une couche change, **toutes les couches suivantes sont invalidées et recalculées**. C'est pourquoi il faut placer les instructions qui changent rarement en tête du Dockerfile :

```
FROM python:3.11-slim          ← Layer 1 : change jamais (image de base)
COPY requirements.txt .        ← Layer 2 : change rarement
RUN pip install -r req.txt     ← Layer 3 : change rarement → mis en cache !
COPY src/ ./src/               ← Layer 4 : change souvent → invalidation ici
```

>  **Explication du schéma :** Les layers sont empilés du plus stable (en haut) au plus volatile (en bas). Docker réutilise le cache de chaque layer tant que son contenu n'a pas changé. Ici, si seul un fichier `.py` dans `src/` est modifié, Docker réutilise les layers 1 à 3 depuis le cache et ne recalcule que le layer 4. Sans cette organisation, `pip install` serait relancé à chaque modification du code- ce qui peut prendre plusieurs minutes inutilement.

Si seul un fichier dans `src/` change, Docker réutilise les layers 1, 2 et 3 depuis le cache et ne recalcule que la layer 4. Sans cette organisation, `pip install` serait relancé à chaque modification de code - ce qui prendrait plusieurs minutes.

---

### 0.4 Docker Compose - Concepts clés

**Docker Compose** est un outil permettant de définir et d'orchestrer des applications multi-conteneurs via un fichier YAML unique (`docker-compose.yml`). Il remplace les longues commandes `docker run` par une configuration déclarative.

#### Concepts clés

| Concept | Définition |
|---------|------------|
| **Service** | Un conteneur défini dans `docker-compose.yml`, avec ses ports, volumes, variables d'environnement et dépendances. |
| **Réseau** | Canal de communication isolé entre services. Les conteneurs d'un même réseau se découvrent par leur nom de service (DNS interne Docker). |
| **Volume** | Stockage persistant partagé entre services ou entre le conteneur et l'hôte. |
| **Healthcheck** | Sonde périodique qui vérifie si un service fonctionne correctement. Docker marque le conteneur `healthy` ou `unhealthy`. |
| **`restart: unless-stopped`** | Politique de redémarrage automatique du conteneur si il plante, sauf si arrêté manuellement. |

---

### 0.5 FastAPI et Pydantic - Concepts clés

**FastAPI** est un framework web Python moderne conçu pour créer des API REST performantes. Il repose sur les *type hints* Python et génère automatiquement la documentation interactive (Swagger UI, accessible sur `/docs`).

**Pydantic** est une bibliothèque de validation de données basée sur les types Python. Elle garantit que les données entrantes respectent un schéma précis : types, longueurs, contraintes. En cas de violation, elle retourne automatiquement une erreur HTTP `422 Unprocessable Entity`.

**Uvicorn** est un serveur ASGI (Asynchronous Server Gateway Interface) léger et performant, utilisé pour servir les applications FastAPI en production.

---

### 0.6 Makefile - Concepts clés

Un **Makefile** est un fichier de recettes qui automatise des tâches répétitives via la commande `make`. Il sert à la fois d'outil d'automatisation et de documentation des commandes du projet.

- **Cible** (`target`) : nom de la tâche à exécuter (ex. `build`, `test`).
- **Recette** : commandes shell exécutées quand la cible est appelée (indentées avec une **tabulation**, jamais des espaces).
- **`.PHONY`** : déclaration indiquant que les cibles ne correspondent pas à des fichiers réels - évite des conflits si un fichier du même nom existe.

---

## Déploiement

### Déployer la VM Linux Ubuntu sur Azure

- Se connecter à Azure 
![image](https://hackmd.io/_uploads/BykOE7bfGl.png)
- Lancer le Cloud Shell et choisir PowerShell
![image](https://hackmd.io/_uploads/B18cNQ-ffe.png)
![image](https://hackmd.io/_uploads/H1eTVQ-GMg.png)
- Déployer la VM
```powershell
# Cloner La configuration de la VM
git clone https://github.com/dspitech/DevOps-VM-Ubuntu-Terraform-Azure.git
```

>  **Explication :** Cette commande télécharge en local l'intégralité du dépôt Git contenant les fichiers Terraform préconfigurés pour créer une VM Ubuntu sur Azure. `git clone` copie tout l'historique et les fichiers dans un nouveau dossier portant le nom du dépôt.

![image](https://hackmd.io/_uploads/rk4_HQ-Gfx.png)

```powershell
# Se placer dans le répertoire du projet
cd DevOps-VM-Ubuntu-Terraform-Azure
```

>  **Explication :** `cd` (change directory) déplace le terminal dans le dossier fraîchement cloné. Toutes les commandes suivantes s'exécuteront dans ce contexte.

![image](https://hackmd.io/_uploads/ryNqBXWzzg.png)
![image](https://hackmd.io/_uploads/Bym3HX-GMg.png)
![image](https://hackmd.io/_uploads/r1rCSX-fze.png)

```powershell
chmod +x ./setup-backend.sh
./setup-backend.sh
```

>  **Explication :** `chmod +x` rend le script `setup-backend.sh` exécutable (lui accorde la permission d'exécution). `./setup-backend.sh` lance ensuite ce script qui crée le backend Terraform distant sur Azure (un Storage Account) pour stocker le fichier d'état Terraform (`terraform.tfstate`) de manière sécurisée et partageable.

![image](https://hackmd.io/_uploads/SkTHL7WGze.png)
![image](https://hackmd.io/_uploads/HkFP87bGfe.png)

```powershell
# vérifier le nom du Storage Account créé
az storage account list --resource-group OpenLab-TFState-RG --query "[].name" -o tsv
# Puis mettez-le dans backend.tf : storage_account_name = "openlabtfstate14523"   # ← le nom réel
```

>  **Explication :** La commande `az storage account list` interroge Azure pour lister les comptes de stockage dans le groupe de ressources `OpenLab-TFState-RG`. L'option `--query "[].name"` filtre pour n'afficher que les noms, et `-o tsv` formate la sortie en texte brut sans guillemets. Le nom retourné doit ensuite être renseigné dans `backend.tf` pour que Terraform sache où stocker son état.

![image](https://hackmd.io/_uploads/By_FIQZzzx.png)
![image](https://hackmd.io/_uploads/BkoTLXWfMe.png)

```powershell
# Initialiser Terraform (téléchargement des providers)
# Formater les fichiers Terraform selon les conventions
# Vérifier la syntaxe et la cohérence de la configuration
# Afficher les ressources qui vont être créées/modifiées
# Déployer l'infrastructure sans confirmation interactive

terraform init && terraform fmt && terraform validate && terraform plan && terraform apply -auto-approve
```

>  **Explication de la chaîne de commandes :**
> - `terraform init` : télécharge les plugins (providers Azure) et initialise le backend distant configuré dans `backend.tf`.
> - `terraform fmt` : reformate automatiquement les fichiers `.tf` selon les conventions Terraform (indentation, alignement).
> - `terraform validate` : vérifie la syntaxe et la cohérence logique de la configuration sans contacter Azure.
> - `terraform plan` : affiche un aperçu des ressources qui seront créées, modifiées ou détruites- aucune action réelle.
> - `terraform apply -auto-approve` : déploie effectivement l'infrastructure sur Azure sans demander de confirmation interactive.
>
> L'opérateur `&&` enchaîne les commandes : si l'une échoue, les suivantes ne s'exécutent pas.

![image](https://hackmd.io/_uploads/rkmWvmZffe.png)
![image](https://hackmd.io/_uploads/S1CXv7-zGe.png)
![image](https://hackmd.io/_uploads/ByDiP7ZGMl.png)
![image](https://hackmd.io/_uploads/rJFfu7WGGg.png)

```powershell
# Télécharger la clé privée SSH générée par Terraform
download ./openlab_rsa
```

>  **Explication :** Terraform a généré une paire de clés SSH (publique/privée) lors du déploiement. `download` est une commande propre au Cloud Shell Azure qui transfère le fichier `openlab_rsa` (clé privée) vers l'ordinateur local. Cette clé est indispensable pour se connecter à la VM sans mot de passe.

![image](https://hackmd.io/_uploads/ByH6PmbGMx.png)

```powershell
# Se connecter à la machine distante via SSH
# Sous Windows PowerShell :
ssh -i "C:\Users\dev\Downloads\openlab_rsa" labadmin@4.225.216.24
```

>  **Explication :** `ssh -i` spécifie la clé privée à utiliser pour l'authentification. `labadmin` est le nom d'utilisateur configuré dans Terraform. `4.225.216.24` est l'adresse IP publique de la VM créée sur Azure. Cette commande ouvre un terminal distant sécurisé sur la VM Ubuntu.

![image](https://hackmd.io/_uploads/S1sLuQ-GMx.png)

## 1. Git - Initialiser le projet

### Prérequis

- Docker (avec Docker Compose)
- Make
- Git

```bash
docker --version && docker compose version && make --version | head -n 1 && git --version
```

>  **Explication :** Cette commande vérifie que tous les outils requis sont installés et fonctionnels. Chaque `--version` affiche la version installée de l'outil. L'opérateur `&&` garantit que toutes les commandes s'exécutent en séquence et qu'une éventuelle erreur interrompt la chaîne. `| head -n 1` limite l'affichage de `make` à la première ligne pour éviter un affichage trop verbeux.

![image](https://hackmd.io/_uploads/rJDJYmbffx.png)

Git est le système de contrôle de version utilisé tout au long de la formation. Chaque modification du code est tracée sous forme de commit. GitHub sera l'hébergeur distant : c'est là que Jenkins ira chercher le code à chaque déclenchement du pipeline.

### 1.1 Créer le repository distant

Connectez-vous à GitHub et créez un nouveau repository **public** avec les paramètres suivants :

| Champ | Valeur attendue |
|-------|-----------------|
| Nom | `sentiment-ai` (exactement, sans majuscule) |
| Visibilité | Public |
| Initialisation | Cocher : README + `.gitignore` Python + Licence MIT |

```bash
# Se connecter à Github
gh auth login
```

>  **Explication :** `gh` est le CLI officiel de GitHub. `gh auth login` lance un processus d'authentification interactif : il demande le type d'hébergeur (github.com), le protocole (HTTPS ou SSH), puis ouvre un navigateur ou propose un code à saisir sur github.com pour associer le terminal à votre compte GitHub. Une fois authentifié, toutes les commandes `gh` s'exécuteront en votre nom.

![image](https://hackmd.io/_uploads/rkZMYQWfGx.png)
![image](https://hackmd.io/_uploads/Bk_mK7-Mfe.png)
![image](https://hackmd.io/_uploads/HkX4t7Zffx.png)
![image](https://hackmd.io/_uploads/HkMrYmZfMg.png)
![image](https://hackmd.io/_uploads/rycIt7Zzfx.png)
![image](https://hackmd.io/_uploads/r1tdt7WGzl.png)
![image](https://hackmd.io/_uploads/H1uFYmbMzg.png)
![image](https://hackmd.io/_uploads/ByV2FQbfze.png)

```bash
# Créer le repo
gh repo create sentiment-ai \
  --public \
  --license MIT \
  --gitignore Python
```

>  **Explication :** `gh repo create` crée un nouveau dépôt directement sur GitHub sans passer par l'interface web.
> - `sentiment-ai` : nom du dépôt.
> - `--public` : rend le dépôt accessible à tous (nécessaire pour Jenkins et les webhooks).
> - `--license MIT` : ajoute automatiquement un fichier `LICENSE` avec la licence MIT.
> - `--gitignore Python` : génère un `.gitignore` préconfiguré pour les projets Python (exclut `__pycache__/`, `.venv/`, `*.pyc`, etc.).
>
> Le backslash `\` en fin de ligne permet de continuer la commande sur la ligne suivante pour améliorer la lisibilité.

> **Pourquoi cocher le `.gitignore` Python dès la création ?**  
> GitHub génère un fichier préconfiguré qui exclut déjà `__pycache__/`, `.venv/`, `*.pyc` et autres artefacts Python indésirables, évitant toute configuration manuelle.
![image](https://hackmd.io/_uploads/rk9CY7bfMe.png)
![image](https://hackmd.io/_uploads/S1Lx9XbfGl.png)
![image](https://hackmd.io/_uploads/HyPbqQZGze.png)

### 1.2 Cloner et configurer

Une fois le repository créé, clonez-le localement. Remplacez `VOTRE_PSEUDO` par votre identifiant GitHub.

```bash
# Cloner le repo localement
git clone https://github.com/dspitech/sentiment-ai.git
```

>  **Explication :** `git clone` télécharge l'intégralité du dépôt distant (code + historique complet) dans un nouveau dossier local nommé `sentiment-ai`. Il configure automatiquement le remote `origin` pointant vers l'URL GitHub, ce qui permettra ensuite de faire `git push origin main` sans configurer manuellement la destination.

![image](https://hackmd.io/_uploads/BkeEcm-zfe.png)

```bash
# Configurer votre identité Git globale (si pas encore fait)
git config --global user.name "Pape Lo"
git config --global user.email "pape.lo@estiam.com"
```

>  **Explication :** Ces deux commandes définissent l'identité qui apparaîtra dans chaque commit. `--global` applique la configuration à tous les dépôts Git de l'utilisateur (stockée dans `~/.gitconfig`). Sans cette configuration, Git refusera de créer des commits. En contexte professionnel, ces informations doivent correspondre à votre identité réelle car elles sont visibles dans l'historique public du dépôt.

```bash
# Vérification
git config --global --list
```

>  **Explication :** Affiche toutes les configurations Git globales définies dans `~/.gitconfig`. Permet de vérifier que `user.name` et `user.email` sont correctement renseignés avant de commencer à travailler.

![image](https://hackmd.io/_uploads/SJ8ucQbzze.png)

```bash
# Vérifier l'état du dépôt : doit afficher "nothing to commit"
git status
```

>  **Explication :** `git status` affiche l'état actuel du dépôt : fichiers modifiés, fichiers en staging, et fichiers non trackés. Un dépôt fraîchement cloné avec le message "nothing to commit, working tree clean" confirme que tout est synchronisé avec le remote.

![image](https://hackmd.io/_uploads/ByxVimZzze.png)

```bash
# Consulter l'historique : un seul commit initial (le README)
git log --oneline
```

>  **Explication :** `git log` affiche l'historique des commits. L'option `--oneline` condense chaque commit sur une ligne (hash court + message). À ce stade, un seul commit créé par GitHub lors de l'initialisation du dépôt (avec README, .gitignore et LICENSE) devrait apparaître.

![image](https://hackmd.io/_uploads/HJdBjmWGMg.png)

> **Identité Git et traçabilité**  
> La configuration `user.name` et `user.email` est essentielle en contexte professionnel. En entreprise, ces informations doivent correspondre à votre identité réelle - elles apparaissent dans chaque commit de l'historique.

### 1.3 Créer la structure du projet

L'arborescence ci-dessous respecte les conventions Python (séparation `src/` et `tests/`) et anticipe les besoins des TPs suivants : `.github/workflows/` accueillera les GitHub Actions, et `Dockerfile` / `docker-compose.yml` seront remplis dans la suite de ce TP.

```bash
# Créer les dossiers nécessaires
mkdir -p src tests .github/workflows

# Créer les fichiers Python (vides pour l'instant)
touch src/__init__.py src/main.py src/model.py src/schemas.py
touch tests/__init__.py tests/test_api.py

# Créer les fichiers de configuration DevOps
touch requirements.txt Dockerfile docker-compose.yml .dockerignore Makefile

# Vérifier la structure complète créée
find . -not -path './.git/*' | sort
```

>  **Explication des commandes :**
> - `mkdir -p` : crée les répertoires et tous les répertoires parents manquants en une seule commande (`-p` = parents). Sans `-p`, si `src` n'existait pas, `mkdir src/tests` échouerait.
> - `touch` : crée des fichiers vides s'ils n'existent pas, ou met à jour leur date de modification s'ils existent déjà. Permet de créer plusieurs fichiers en une seule commande.
> - `find . -not -path './.git/*' | sort` : liste récursivement tous les fichiers et dossiers du projet (`.`) en excluant le dossier `.git` (historique interne de Git), puis trie le résultat alphabétiquement pour une visualisation claire de la structure.

**Structure attendue :**

```
.
├── .dockerignore
├── .github/
│   └── workflows/
├── .gitignore
├── Dockerfile
├── Makefile
├── docker-compose.yml
├── requirements.txt
├── src/
│   ├── __init__.py
│   ├── main.py
│   ├── model.py
│   └── schemas.py
└── tests/
    ├── __init__.py
    └── test_api.py
```
![image](https://hackmd.io/_uploads/BJijs7bzzl.png)

### 1.4 Remplir les fichiers Python

Le modèle utilisé est volontairement simplifié (liste de mots-clés). Cette approche naïve suffit pour valider le pipeline - un vrai modèle ML pourrait le remplacer sans changer l'interface de l'API.

#### 1.4.1 `src/schemas.py` - Modèles de données Pydantic

```bash
cat > src/schemas.py <<'EOF'
from pydantic import BaseModel, Field
from typing import Literal


class PredictionRequest(BaseModel):
    # Le texte à analyser : obligatoire, entre 1 et 5000 caractères
    text: str = Field(..., min_length=1, max_length=5000)


class PredictionResponse(BaseModel):
    # Le label retourné est contraint à 3 valeurs possibles
    label: Literal["POSITIVE", "NEGATIVE", "NEUTRAL"]
    score: float  # Score de confiance entre 0.0 et 1.0
    text: str  # Texte original retourné pour traçabilité
EOF
```

>  **Explication du code `schemas.py` :**
> - `cat > fichier <<'EOF' ... EOF` : redirige le texte entre les deux `EOF` vers le fichier. C'est un *heredoc* shell qui permet d'écrire un fichier multi-lignes en une seule commande.
> - `BaseModel` (Pydantic) : classe parente qui active la validation automatique des données. Toute instance de `PredictionRequest` aura son champ `text` validé dès la création.
> - `Field(..., min_length=1, max_length=5000)` : le `...` signifie que le champ est **obligatoire** (pas de valeur par défaut). `min_length=1` rejette les chaînes vides, `max_length=5000` protège contre les payloads trop lourds.
> - `Literal["POSITIVE", "NEGATIVE", "NEUTRAL"]` : contraint le champ `label` à exactement ces trois valeurs. Pydantic lèvera une erreur de validation si une autre valeur est retournée- garantissant la cohérence du contrat d'API.

![image](https://hackmd.io/_uploads/B1az3Q-MMl.png)


#### 1.4.2 `src/model.py` - Modèle de sentiment simplifié

```bash
cat > src/model.py <<'EOF'
class SentimentModel:
    def __init__(self):
        # Ce message sera visible dans "docker logs sentiment"
        print("[SentimentModel] Modèle chargé")

    def predict(self, text: str) -> dict:
        text_lower = text.lower()

        positive_words = [
            "bien",
            "super",
            "excellent",
            "parfait",
            "bon",
            "aime",
            "adore"
        ]

        negative_words = [
            "mal",
            "nul",
            "horrible",
            "mauvais",
            "déteste",
            "pire"
        ]

        pos = sum(1 for w in positive_words if w in text_lower)
        neg = sum(1 for w in negative_words if w in text_lower)

        if pos > neg:
            return {
                "label": "POSITIVE",
                "score": round(0.6 + 0.1 * pos, 2),
                "text": text
            }

        elif neg > pos:
            return {
                "label": "NEGATIVE",
                "score": round(0.6 + 0.1 * neg, 2),
                "text": text
            }

        return {
            "label": "NEUTRAL",
            "score": 0.5,
            "text": text
        }
EOF
```

>  **Explication du code `model.py` :**
> - `__init__` : méthode constructeur appelée lors de l'instanciation du modèle. Le `print` est volontaire : il apparaîtra dans `docker logs sentiment`, confirmant que le modèle a bien été chargé au démarrage.
> - `text.lower()` : normalise le texte en minuscules pour que la recherche de mots-clés soit insensible à la casse ("BIEN", "Bien" et "bien" donnent le même résultat).
> - `sum(1 for w in positive_words if w in text_lower)` : expression génératrice qui compte combien de mots de la liste apparaissent dans le texte. Plus efficace en mémoire qu'un `len([...])` équivalent.
> - `round(0.6 + 0.1 * pos, 2)` : calcule un score de confiance proportionnel au nombre de mots positifs trouvés. Le score minimal est 0.60 (1 mot), augmente de 0.10 par mot supplémentaire. `round(..., 2)` arrondit à 2 décimales pour éviter les imprécisions flottantes comme `0.7000000001`.
> - Si `pos == neg` (égalité ou aucun mot trouvé), le label `NEUTRAL` est retourné avec un score fixe de `0.5`.

![image](https://hackmd.io/_uploads/BkaL27bfze.png)

#### 1.4.3 `src/main.py` - Application FastAPI

`main.py` est le point d'entrée de l'API. Il expose deux endpoints :
- `/health` pour les healthchecks Docker et Kubernetes
- `/predict` pour les prédictions de sentiment

```bash
cat > src/main.py <<'EOF'
from fastapi import FastAPI
from src.schemas import PredictionRequest, PredictionResponse
from src.model import SentimentModel


app = FastAPI(title="SentimentAI", version="0.1.0")


# Le modèle est chargé une seule fois au démarrage du serveur
model = SentimentModel()


@app.get("/health")
def health():
    """
    Endpoint de healthcheck utilisé par Docker et les load balancers.
    """
    return {"status": "ok"}


@app.post("/predict", response_model=PredictionResponse)
def predict(request: PredictionRequest):
    """
    Analyse le sentiment du texte fourni et retourne un label + score.
    """
    return model.predict(request.text)
EOF
```

>  **Explication du code `main.py` :**
> - `FastAPI(title=..., version=...)` : crée l'application avec des métadonnées visibles dans la documentation automatique Swagger UI à l'adresse `/docs`.
> - `model = SentimentModel()` : instanciation **unique** du modèle au niveau module. FastAPI charge le modèle une seule fois au démarrage du serveur- pas à chaque requête. C'est crucial pour les performances.
> - `@app.get("/health")` : décorateur FastAPI qui enregistre la fonction `health()` comme handler de la route `GET /health`. Retourner un dictionnaire Python est automatiquement converti en JSON.
> - `@app.post("/predict", response_model=PredictionResponse)` : `response_model` indique à FastAPI de valider la réponse avec le schéma Pydantic `PredictionResponse` avant de la renvoyer- protégeant les clients d'une réponse malformée.

![image](https://hackmd.io/_uploads/rkVi27bMzx.png)

#### 1.4.4 `tests/test_api.py` - Tests unitaires et d'intégration

```bash
cat > tests/test_api.py <<'EOF'
from fastapi.testclient import TestClient
from src.main import app


client = TestClient(app)


def test_health():
    """
    Vérifie que l'endpoint /health répond avec status 200.
    """
    r = client.get("/health")
    assert r.status_code == 200


def test_predict_positive():
    """
    Vérifie qu'une prédiction retourne la bonne structure de réponse.
    """
    r = client.post("/predict", json={"text": "Ce produit est excellent !"})

    assert r.status_code == 200

    data = r.json()

    assert data["label"] in ["POSITIVE", "NEGATIVE", "NEUTRAL"]
    assert 0 <= data["score"] <= 1


def test_predict_empty_fails():
    """
    Vérifie que Pydantic rejette un texte vide avec une erreur 422.
    """
    r = client.post("/predict", json={"text": ""})

    assert r.status_code == 422
def test_predict_negative():
    """
    Vérifie qu'un texte négatif retourne le label NEGATIVE.
    """
    r = client.post("/predict", json={"text": "Ce produit est horrible"})

    assert r.status_code == 200

    data = r.json()

    assert data["label"] == "NEGATIVE"
    assert 0 <= data["score"] <= 1


def test_predict_neutral():
    """
    Vérifie qu'un texte sans mot positif ou négatif retourne NEUTRAL.
    """
    r = client.post("/predict", json={"text": "La météo est aujourd'hui"})

    assert r.status_code == 200

    data = r.json()

    assert data["label"] == "NEUTRAL"
    assert data["score"] == 0.5
EOF
```

>  **Explication du code `test_api.py` :**
> - `TestClient(app)` : client HTTP de test fourni par FastAPI (via Starlette). Il simule des requêtes HTTP réelles **sans démarrer de vrai serveur**- les tests sont donc rapides et exécutables sans réseau.
> - `assert r.status_code == 200` : vérifie que le serveur a répondu avec le code HTTP 200 (succès). Si la condition est fausse, pytest lève une `AssertionError` et marque le test en échec.
> - `test_predict_empty_fails` : teste un cas d'erreur volontaire. Envoyer `{"text": ""}` doit déclencher la validation Pydantic (`min_length=1`) et retourner HTTP 422 (Unprocessable Entity). Tester les chemins d'erreur est aussi important que tester les chemins de succès.
> - `test_predict_neutral` : l'assertion `== 0.5` (pas `>= 0.5`) vérifie la valeur exacte, garantissant que la logique du modèle n'a pas changé.

![image](https://hackmd.io/_uploads/B1iA3mbMGg.png)

#### 1.4.5 `requirements.txt` - Dépendances Python

```bash
cat > requirements.txt <<'EOF'
fastapi==0.109.0
uvicorn==0.27.0
pydantic==2.5.3
pytest==7.4.4
pytest-cov==4.1.0
httpx==0.26.0
EOF
```

>  **Explication de `requirements.txt` :**
> - Ce fichier liste toutes les dépendances Python du projet avec leurs versions **exactement épinglées** (opérateur `==`). `pip install -r requirements.txt` installe exactement ces versions, pas de plus récentes.
> - `fastapi` + `uvicorn` : le framework web et son serveur ASGI pour servir l'API.
> - `pydantic` : moteur de validation des données utilisé par FastAPI.
> - `pytest` + `pytest-cov` : framework de tests et plugin de couverture de code (génère `coverage.xml` pour SonarQube au TP3).
> - `httpx` : client HTTP asynchrone requis par `TestClient` de FastAPI pour simuler les requêtes dans les tests.
> - L'épinglage des versions garantit que l'environnement de développement, Docker, Jenkins et la production sont **identiques**. Sans épinglage, `pip install fastapi` installerait la dernière version disponible, qui pourrait introduire des incompatibilités sans prévenir.

![image](https://hackmd.io/_uploads/HkgMamZGMg.png)

> Les versions sont **épinglées** (numéros exacts). C'est une bonne pratique DevOps : elle garantit que le même environnement est recréé identiquement en local, dans Docker, dans Jenkins et en production.
![image](https://hackmd.io/_uploads/HktBpX-zGg.png)

### 1.5 Premier commit et push

```bash
# Ajouter tous les fichiers au staging
git add .

# Vérifier ce qui va être commité avant de valider
git diff --staged --stat

# Créer le commit avec un message conventionnel
git commit -m "feat: initialiser la structure SentimentAI"

# Pousser vers GitHub
git push origin main

# Vérifier que le commit apparaît bien dans l'historique
git log --oneline
```

>  **Explication des commandes Git :**
> - `git add .` : ajoute **tous** les fichiers modifiés et non trackés du répertoire courant à la staging area. Le `.` désigne le répertoire courant et tous ses sous-dossiers.
> - `git diff --staged --stat` : affiche un résumé statistique des changements qui seront inclus dans le prochain commit (nombre de lignes ajoutées/supprimées par fichier). `--staged` cible les fichiers déjà ajoutés avec `git add`. Bonne pratique avant de commiter pour éviter d'inclure des fichiers non voulus.
> - `git commit -m "feat: initialiser la structure SentimentAI"` : crée un commit avec le message spécifié. Le préfixe `feat:` respecte la convention Conventional Commits.
> - `git push origin main` : envoie les commits locaux vers le remote `origin` (GitHub) sur la branche `main`.
> - `git log --oneline` : confirme que le nouveau commit apparaît bien dans l'historique avec son hash et son message.

![image](https://hackmd.io/_uploads/rJYcpQZfGx.png)
![image](https://hackmd.io/_uploads/r1g66m-GMl.png)
![image](https://hackmd.io/_uploads/r1d0pXbGfe.png)
![image](https://hackmd.io/_uploads/r16gCm-Mzx.png)

---

## 2. Docker - Conteneuriser l'API

La conteneurisation permet d'empaqueter l'application avec toutes ses dépendances dans une image Docker reproductible. Une fois conteneurisée, SentimentAI fonctionnera de manière identique en local, dans Jenkins lors des tests, et en production. C'est le principe fondamental du DevOps : *"works on my machine"* devient *"works everywhere"*.

### 2.1 Écrire le Dockerfile

L'ordre des instructions est crucial pour les performances de cache (voir section 0.3). On copie `requirements.txt` **avant** le code source.

```
nano Dockerfile
```

```dockerfile
FROM python:3.11-slim

# Définir le répertoire de travail dans le conteneur
WORKDIR /app

# Étape 1 : copier UNIQUEMENT le fichier de dépendances
# Cette couche sera mise en cache tant que requirements.txt ne change pas
COPY requirements.txt .

# Étape 2 : installer les dépendances (couche mise en cache)
RUN pip install --no-cache-dir -r requirements.txt

# Étape 3 : copier le code source (invalidé à chaque modification du code)
COPY src/ ./src/
COPY tests/ ./tests/

# Documenter le port utilisé par l'application
EXPOSE 8000

# Commande de démarrage du serveur Uvicorn
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

>  **Explication du Dockerfile :**
> - `FROM python:3.11-slim` : image de base officielle Python 3.11 en version allégée (~150 Mo vs ~900 Mo pour la version complète). Contient uniquement le minimum pour exécuter Python.
> - `WORKDIR /app` : définit `/app` comme répertoire de travail dans le conteneur. Toutes les commandes suivantes (`COPY`, `RUN`, `CMD`) s'exécuteront depuis ce répertoire. S'il n'existe pas, Docker le crée automatiquement.
> - `COPY requirements.txt .` : copie **uniquement** le fichier de dépendances en premier. Cette couche est mise en cache et ne sera recalculée que si `requirements.txt` change- pas si le code source change.
> - `RUN pip install --no-cache-dir -r requirements.txt` : installe toutes les dépendances. `--no-cache-dir` évite que pip stocke les archives téléchargées dans l'image, réduisant la taille finale.
> - `EXPOSE 8000` : documentation du port utilisé (n'ouvre pas réellement le port- c'est `-p` lors de `docker run` qui le fait).
> - `CMD [...]` : commande exécutée au démarrage du conteneur. `src.main:app` indique à Uvicorn le module (`src.main`) et l'objet FastAPI (`app`) à servir. `--host 0.0.0.0` écoute sur toutes les interfaces réseau du conteneur.

![image](https://hackmd.io/_uploads/SkVwCQWGGe.png)

> **Pourquoi `python:3.11-slim` et non `python:3.11` ?**  
> L'image `slim` pèse ~150 Mo contre ~900 Mo pour l'image complète. Une image plus petite = moins de surface d'attaque, un transfert plus rapide vers le registry et un démarrage plus rapide.

### 2.2 Écrire le .dockerignore

Le `.dockerignore` exclut les fichiers inutiles ou sensibles du contexte de build, réduisant le temps de transfert et le risque de fuites de secrets.
![image](https://hackmd.io/_uploads/BkWykVZGGg.png)

```bash
cat > .dockerignore <<'EOF'
# Exclure le dépôt Git (inutile dans l'image, très volumineux)
.git/
.github/

# Exclure les fichiers compilés Python (régénérés automatiquement)
__pycache__/
*.pyc
*.pyo

# Exclure les artefacts de tests et de couverture
.pytest_cache/
htmlcov/
coverage.xml

# Exclure les secrets et fichiers d'environnement locaux
.env
.env.*

# Exclure les fichiers Terraform (ajoutés en TP4)
*.tfstate
.terraform/
EOF
```

>  **Explication du `.dockerignore` :**
> - Le `.dockerignore` fonctionne comme le `.gitignore` mais pour le **contexte de build Docker**. Avant d'exécuter le Dockerfile, Docker envoie tous les fichiers du répertoire courant au daemon Docker. Sans `.dockerignore`, le dossier `.git/` (qui peut peser plusieurs centaines de Mo) serait envoyé inutilement à chaque build.
> - `.git/` et `.github/` : l'historique Git et les workflows ne sont jamais nécessaires à l'intérieur du conteneur.
> - `__pycache__/`, `*.pyc`, `*.pyo` : artefacts compilés Python spécifiques à la machine hôte, inutiles voire problématiques dans le conteneur (bytecode incompatible avec la version Python du conteneur).
> - `.env`, `.env.*` : protection critique contre la fuite accidentelle de secrets (tokens, mots de passe, clés API) dans l'image Docker publiée sur un registry public.
> - `*.tfstate`, `.terraform/` : les fichiers d'état Terraform contiennent des informations sensibles sur l'infrastructure.

### 2.3 Builder et tester l'image

```bash
# Construire l'image et la tagger "sentiment-ai:latest"
docker build -t sentiment-ai:latest .
```

>  **Explication :** `docker build` exécute chaque instruction du Dockerfile dans l'ordre pour construire une image.
> - `-t sentiment-ai:latest` : donne un nom (`sentiment-ai`) et un tag (`latest`) à l'image résultante. Sans tag, l'image ne serait accessible que par son hash SHA256.
> - `.` : indique le répertoire courant comme contexte de build (filtré par `.dockerignore`).

![image](https://hackmd.io/_uploads/B13iyNbMMg.png)
![image](https://hackmd.io/_uploads/rkTpy4ZGzl.png)

```bash
# Lancer le conteneur en arrière-plan (-d) avec redirection de port
docker run -d --name sentiment -p 8080:8000 sentiment-ai:latest
```

>  **Explication :** `docker run` crée et démarre un conteneur depuis l'image.
> - `-d` (detached) : démarre le conteneur en arrière-plan, libérant le terminal.
> - `--name sentiment` : donne un nom lisible au conteneur (sinon Docker génère un nom aléatoire comme `funny_einstein`). Ce nom peut être utilisé dans les commandes suivantes (`docker logs sentiment`, `docker stop sentiment`).
> - `-p 8080:8000` : mappe le port `8080` de l'hôte vers le port `8000` du conteneur. Les requêtes arrivant sur `localhost:8080` sont redirigées vers l'application FastAPI écoutant sur le port `8000` à l'intérieur du conteneur.

![image](https://hackmd.io/_uploads/SJWllVbMGx.png)

```bash
# Vérifier que le conteneur est bien démarré
docker ps
```

>  **Explication :** `docker ps` liste tous les conteneurs **en cours d'exécution**. On vérifie que le conteneur `sentiment` apparaît dans la liste avec le statut `Up` et le port mapping `0.0.0.0:8080->8000/tcp`. `docker ps -a` afficherait aussi les conteneurs arrêtés.

![image](https://hackmd.io/_uploads/SJvZeEZGMe.png)

```bash
# Tester l'endpoint de healthcheck
curl http://localhost:8080/health
# Réponse attendue : {"status":"ok"}
```

>  **Explication :** `curl` envoie une requête HTTP GET à l'URL spécifiée et affiche la réponse dans le terminal. La réponse `{"status":"ok"}` confirme que le serveur FastAPI est démarré, le modèle est chargé, et l'endpoint `/health` répond correctement. C'est le test de fumée minimal avant de tester les endpoints fonctionnels.

![image](https://hackmd.io/_uploads/SJqml4ZGfl.png)

```bash
# Tester une prédiction de sentiment
curl -X POST http://localhost:8080/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "Ce produit est excellent !"}'
# Réponse attendue : {"label":"POSITIVE","score":0.7,"text":"..."}
```

>  **Explication :** `curl -X POST` envoie une requête HTTP POST.
> - `-H "Content-Type: application/json"` : en-tête indiquant que le corps de la requête est du JSON. Sans cet en-tête, FastAPI ne saurait pas comment interpréter les données.
> - `-d '{"text": "..."}'` : le corps (body) de la requête au format JSON. FastAPI le désérialise et le valide via Pydantic avant de l'envoyer à `model.predict()`.
> - La réponse attendue `{"label":"POSITIVE","score":0.7,...}` confirme que le mot "excellent" a été détecté dans la liste `positive_words` et que le modèle fonctionne correctement.

![image](https://hackmd.io/_uploads/SkKUlEZGMg.png)

```bash
# Consulter les logs du conteneur pour vérifier le démarrage
docker logs sentiment
```

>  **Explication :** `docker logs` affiche la sortie standard (stdout/stderr) du conteneur. On devrait y voir le message `[SentimentModel] Modèle chargé` (du `print` dans `model.py`) et les logs de démarrage d'Uvicorn confirmant qu'il écoute sur le port 8000.

![image](https://hackmd.io/_uploads/SynPxVWMzl.png)

```bash
# Nettoyer : arrêter et supprimer le conteneur
docker stop sentiment && docker rm sentiment
```

>  **Explication :** Séquence obligatoire de nettoyage en deux étapes.
> - `docker stop sentiment` : envoie SIGTERM au processus principal du conteneur et attend 10 secondes qu'il s'arrête proprement. Si le processus ne répond pas, Docker envoie SIGKILL pour forcer l'arrêt.
> - `docker rm sentiment` : supprime définitivement le conteneur arrêté. Sans cette étape, le nom `sentiment` serait réservé et un prochain `docker run --name sentiment` échouerait avec "name already in use".
> - `&&` : `docker rm` ne s'exécute que si `docker stop` a réussi.

![image](https://hackmd.io/_uploads/ry9cg4WGGl.png)

> **`docker stop` vs `docker rm`**  
> `docker stop` envoie SIGTERM et attend un arrêt propre (timeout 10s, puis SIGKILL). Le conteneur reste dans l'état `stopped`. `docker rm` le supprime définitivement. Toujours `stop` avant `rm`, ou `docker rm -f` pour forcer.

---

## 3. Docker Compose

Docker Compose centralise la configuration de toute la stack dans un fichier YAML unique, remplaçant les longues commandes `docker run`. C'est le standard pour orchestrer les environnements de développement et de staging.

### 3.1 Écrire le docker-compose.yml

```bash
cat > docker-compose.yml <<'EOF'
version: '3.9'

services:
  sentiment-ai:
    build: .
    container_name: sentiment-staging
    ports:
      - "8080:8000"   # hôte:conteneur
    environment:
      - ENV=development
    networks:
      - cicd-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s      # fréquence des vérifications
      timeout: 10s       # délai max avant échec
      retries: 3         # nombre d'échecs avant "unhealthy"
      start_period: 10s  # délai de grâce au démarrage

# Réseau dédié : Jenkins et SonarQube le rejoindront dans les TPs suivants
networks:
  cicd-network:
    driver: bridge
EOF
```

>  **Explication du `docker-compose.yml` :**
> - `version: '3.9'` : version de la syntaxe Compose compatible avec Docker Engine 19.03+ et supportant toutes les fonctionnalités utilisées ici.
> - `build: .` : indique à Compose de builder l'image depuis le `Dockerfile` du répertoire courant (`.`) plutôt que de la télécharger depuis un registry.
> - `container_name: sentiment-staging` : nom fixe du conteneur, permettant de le référencer facilement dans les scripts.
> - `ports: "8080:8000"` : équivalent du `-p 8080:8000` de `docker run`. Format `hôte:conteneur`.
> - `environment: ENV=development` : injecte une variable d'environnement dans le conteneur. L'application peut lire `os.environ["ENV"]` pour adapter son comportement.
> - `restart: unless-stopped` : le conteneur redémarre automatiquement en cas de crash, **sauf** s'il a été arrêté manuellement avec `docker compose stop`.
> - `healthcheck` : sonde périodique pour vérifier la santé du service. `start_period: 10s` donne un délai de grâce au démarrage de l'application avant que les échecs ne comptent.
> - `networks: cicd-network` : réseau Docker personnalisé. Les conteneurs d'un même réseau peuvent se contacter par leur nom de service (ex. `http://sentiment-ai:8000`) sans connaître leurs IPs.

![image](https://hackmd.io/_uploads/H1jAgV-Mze.png)

> **Pourquoi un réseau `cicd-network` dédié ?**  
> Les conteneurs d'un même réseau Docker nommé se découvrent par leur nom de service (DNS interne). Dans les TPs suivants, Jenkins contactera SonarQube via `http://sonarqube:9000` plutôt qu'une IP instable.

### 3.2 Lancer, tester et arrêter la stack

```bash
# Démarrer la stack en arrière-plan (-d = detached)
docker compose up -d
```

>  **Explication :** `docker compose up` lit `docker-compose.yml`, build ou télécharge les images nécessaires, crée les réseaux et volumes déclarés, puis démarre tous les services. `-d` (detached) libère le terminal après le démarrage. Si l'image n'existe pas encore localement, Compose la build automatiquement grâce à `build: .`.

![image](https://hackmd.io/_uploads/HJrmbNWGMg.png)

```bash
# Vérifier l'état des services (attendre ~30s pour le healthcheck)
docker compose ps
```

>  **Explication :** Affiche l'état de chaque service défini dans `docker-compose.yml`. Après le délai `start_period` (10s) et si les premières sondes réussissent, le statut passe de `starting` à `healthy`. Un statut `unhealthy` indique que l'application ne répond pas correctement à `/health`.

![image](https://hackmd.io/_uploads/HyWHW4bMzl.png)

```bash
# Tester que l'API répond correctement
curl http://localhost:8080/health
```

>  **Explication :** Même test que précédemment mais cette fois via Docker Compose. Confirme que le port mapping, le réseau et l'application fonctionnent correctement dans la configuration déclarative.

![image](https://hackmd.io/_uploads/rJsLZNWGzx.png)

```bash
# Suivre les logs en temps réel (Ctrl+C pour quitter)
docker compose logs -f sentiment-ai
```

>  **Explication :** `docker compose logs -f` (follow) affiche les logs de tous les services en temps réel, colorés par service si plusieurs tournent. Permet de déboguer les erreurs de démarrage ou de surveiller l'activité en direct. `Ctrl+C` arrête le suivi sans arrêter le conteneur.

![image](https://hackmd.io/_uploads/ryyKW4WMGe.png)

```bash
# Arrêter et supprimer les conteneurs (réseau et volumes conservés)
docker compose down
```

>  **Explication :** `docker compose down` arrête et supprime proprement tous les conteneurs et le réseau créés par `docker compose up`. Contrairement à `docker compose stop` (qui arrête sans supprimer), `down` nettoie complètement. Les **volumes nommés** sont conservés par défaut- il faut ajouter `-v` pour les supprimer.

```bash
# Pour tout supprimer y compris les volumes :
docker compose down -v
```

>  **Explication :** `-v` supprime également les volumes Docker associés aux services. À utiliser avec précaution : toutes les données persistées (bases de données, fichiers) seront perdues. Dans ce TP, aucun volume de données n'est utilisé (pas de base de données), donc `-v` est sans risque.

![image](https://hackmd.io/_uploads/BkX6b4-GGl.png)

---

## 4. Makefile & Tag Git

Un Makefile automatise les tâches répétitives et sert de **documentation vivante** des commandes du projet. Tout nouveau développeur comprend immédiatement comment builder, tester et déployer en lisant les cibles.

### 4.1 Écrire le Makefile

>  **Attention :** l'indentation des recettes doit utiliser des **tabulations** (`Tab`), pas des espaces.

```bash
cat > Makefile <<'EOF'
IMAGE_NAME = sentiment-ai
PORT       = 8080

.PHONY: build run test stop clean tag

build:
	docker build -t $(IMAGE_NAME):latest .

run:
	docker compose up -d

# Lance les tests DANS le conteneur Docker
test:
	docker run --rm \
		-v $(PWD):/app \
		-w /app \
		$(IMAGE_NAME):latest \
		pytest tests/ -v --cov=src --cov-report=term-missing

stop:
	docker compose down

clean:
	docker compose down
	docker rmi $(IMAGE_NAME):latest || true

tag:
	git tag -a v0.1.0 -m "Initial SentimentAI release"
	git push origin v0.1.0
EOF
```

>  **Explication du Makefile :**
> - `IMAGE_NAME = sentiment-ai` : variable Makefile réutilisable dans toutes les cibles via `$(IMAGE_NAME)`. Modifier cette valeur une seule fois la propage partout.
> - `.PHONY: build run test stop clean tag` : déclare ces cibles comme "phony" (fictives). Sans cela, si un fichier nommé `build` existait dans le projet, `make build` ne ferait rien (considérant que la cible est "à jour"). `.PHONY` force toujours l'exécution.
> - `build:` → `docker build -t $(IMAGE_NAME):latest .` : build l'image Docker avec le tag `latest`.
> - `test:` → lance pytest **à l'intérieur d'un conteneur Docker** (`docker run --rm`). `-v $(PWD):/app` monte le répertoire courant dans le conteneur. `--cov=src --cov-report=term-missing` active la mesure de couverture de code sur le package `src/` et affiche les lignes non couvertes.
> - `clean:` → `docker rmi ... || true` : supprime l'image Docker. `|| true` évite que `make clean` échoue si l'image n'existe pas.
> - `tag:` → crée un tag annoté Git (`-a`) avec un message (`-m`) et le pousse vers GitHub. Les tags annotés sont visibles dans l'onglet "Releases" de GitHub.

> **Pourquoi tester dans le conteneur ?**  
> Cela garantit que les tests s'exécutent dans le même environnement que la production. Un test qui passe localement mais échoue dans Docker révèle une dépendance manquante ou une hypothèse incorrecte sur l'environnement.

### 4.2 Lancer les tests

```bash
make test
```

>  **Explication :** `make test` exécute la recette `test` du Makefile, qui lance pytest dans un conteneur Docker éphémère (`--rm` = supprimé après exécution). La sortie affiche les résultats de chaque test (✓ vert / ✗ rouge) et le rapport de couverture de code indiquant quelles lignes de `src/` ne sont pas couvertes par les tests.

![image](https://hackmd.io/_uploads/SyP8S4-zfx.png)

### 4.3 Créer le tag de version v0.1.0

```bash
# Créer le tag v0.1.0 annoté et le pousser vers GitHub
make tag

# Vérifier que le tag est bien créé localement
git tag -l

# Vérifier que le tag apparaît dans l'historique
git log --oneline --decorate
```

>  **Explication :**
> - `make tag` : exécute les deux commandes de la cible `tag` du Makefile- crée le tag annoté puis le pousse vers GitHub.
> - `git tag -l` : liste tous les tags existants localement. Doit afficher `v0.1.0`.
> - `git log --oneline --decorate` : affiche l'historique des commits avec les tags et branches associés. Le tag `v0.1.0` devrait apparaître à côté du commit courant, ex. : `a3f8c12 (HEAD -> main, tag: v0.1.0, origin/main) feat: ...`.

![image](https://hackmd.io/_uploads/HJH0fEWzMg.png)
![image](https://hackmd.io/_uploads/SynkmEbMGg.png)
![image](https://hackmd.io/_uploads/SkzX7N-MMx.png)
![image](https://hackmd.io/_uploads/Bkm4XNWGMx.png)


---

## 5. Réponses aux questions

### Question 1.1 - Rôle du `.gitignore` et `__pycache__/`

**Rôle du `.gitignore`**

Le fichier `.gitignore` liste les fichiers et dossiers que Git doit ignorer, c'est-à-dire ne jamais tracer ni inclure dans les commits. Il permet de maintenir le repository propre en excluant les fichiers générés automatiquement, les secrets (`.env`), les artefacts de compilation et les fichiers propres à l'environnement local de chaque développeur.

**Pourquoi ne pas commiter `__pycache__/` ?**

Le dossier `__pycache__/` contient les fichiers `.pyc`, qui sont des versions compilées en bytecode des modules Python. Ces fichiers sont générés automatiquement par l'interpréteur à chaque exécution et sont propres à la version locale de Python- ils diffèrent d'une machine à l'autre. Les commiter polluerait l'historique Git avec des fichiers binaires inutiles, provoquerait des conflits de merge constants entre développeurs, et alourdirait le repository sans aucune valeur ajoutée.

---

### Question 1.2 - `git add .` vs `git add -p`

**`git add .`**

Ajoute **tous** les fichiers modifiés et non-trackés du répertoire courant (et de ses sous-dossiers) à la staging area en une seule commande. C'est rapide mais sans discernement : on commit tout ce qui a changé.

**`git add -p` (patch mode)**

Lance un mode interactif qui présente chaque modification (hunk) une par une et demande si on souhaite l'inclure dans le prochain commit (`y` = yes, `n` = no, `s` = split, `e` = edit). Cela permet de créer des commits **atomiques et cohérents**, où chaque commit ne contient qu'un seul changement logique.

**Quand préférer `git add -p` ?**

On préfère `git add -p` lorsqu'on a travaillé sur plusieurs fonctionnalités ou corrections en parallèle et que l'on souhaite les séparer en commits distincts. Par exemple, si un fichier contient à la fois un correctif de bug et le début d'une nouvelle feature, `git add -p` permet de commiter uniquement le correctif dans un premier commit (`fix:`), puis la feature dans un second (`feat:`). C'est une pratique essentielle pour maintenir un historique Git lisible et faciliter les revues de code (`git blame`, `git bisect`).

---

### Question 2.1 - Cache Docker lors du build

**Couches mises en cache (`CACHED`) :**

Lors d'un second `docker build` sans modification, les couches suivantes sont lues depuis le cache :
- `FROM python:3.11-slim` - l'image de base est déjà téléchargée localement.
- `COPY requirements.txt .` - le fichier n'a pas changé, le hash est identique.
- `RUN pip install --no-cache-dir -r requirements.txt` - aucune dépendance n'a changé, Docker réutilise la couche buildée précédemment. C'est la couche la plus longue à recalculer (~30s à plusieurs minutes).

**Couches recalculées :**

- `COPY src/ ./src/` et `COPY tests/ ./tests/` - si un fichier source change, ces layers sont invalidés et tout ce qui suit est recalculé.

**Pourquoi c'est important en pratique ?**

Sans cette organisation, la moindre modification d'un fichier `.py` déclencherait un `pip install` complet à chaque build, rendant le pipeline CI/CD inutilisable en termes de temps.

---

### Question 2.2 - Invalidation du cache après modification d'un fichier Python

**Observation lors d'un second build sans modification :**

Toutes les couches affichent `CACHED` dans la sortie. Le build est quasi-instantané car Docker n'exécute aucune instruction - il reconstruit l'image entièrement depuis le cache.

**Quelle instruction perd le cache si on modifie un fichier dans `src/` ?**

L'instruction `COPY src/ ./src/` est invalidée. Docker calcule un hash de tous les fichiers copiés : si un seul fichier change, le hash diffère et la couche est recalculée. Puisqu'elle est invalidée, **toutes les instructions suivantes** le sont aussi - ici seulement `COPY tests/` et `CMD`, qui sont rapides.

**Explication par le principe des layers :**

Les layers Docker sont immuables et empilés de manière séquentielle. Le cache d'une layer est valide uniquement si :
1. L'instruction Dockerfile est identique à la précédente exécution, **ET**
2. La layer parente est elle-même issue du cache.

Dès qu'une layer est invalidée, toute la chaîne en dessous l'est aussi - c'est le comportement déterministe du cache Docker. C'est la raison fondamentale pour laquelle on structure le Dockerfile du **plus stable au plus volatile** : `FROM` → dépendances → code source.

---

### Question 3.1 - Utilité du healthcheck en déploiement automatisé

**Définition du healthcheck ici :**

Toutes les 30 secondes, Docker exécute `curl -f http://localhost:8000/health` à l'intérieur du conteneur. Si la commande réussit (code HTTP 200), le conteneur est marqué `healthy`. Après 3 échecs consécutifs, il passe à `unhealthy`.

**Pourquoi c'est indispensable en déploiement automatisé ?**

Sans healthcheck, Docker considère qu'un conteneur est opérationnel dès lors que son processus principal a démarré - même si l'application a planté silencieusement, est bloquée dans une boucle infinie, ou si le serveur web n'écoute pas encore. Dans un pipeline CI/CD ou avec un orchestrateur comme Kubernetes, cela signifie que du trafic pourrait être redirigé vers un conteneur non fonctionnel, provoquant des erreurs 502 ou 503 pour les utilisateurs finaux.

Le healthcheck permet à Docker (et aux orchestrateurs) de distinguer « le processus tourne » de « l'application répond correctement ». Un outil comme Kubernetes peut ainsi :
- Retarder l'envoi de trafic jusqu'à ce que le conteneur soit `healthy` (readiness probe).
- Redémarrer automatiquement un conteneur devenu `unhealthy` (liveness probe).
- Éviter de déployer une version défectueuse en production (rolling update avec vérification).

---

### Question 4.1 - Résultats des tests et coverage

**Résultat attendu de `make test` :**

![image](https://hackmd.io/_uploads/HyDBr4bGzl.png)


**Ce que couvre chaque test :**

| Test | Ce qu'il vérifie |
|------|-----------------|
| `test_health` | L'endpoint `/health` répond HTTP 200 - prouve que FastAPI démarre correctement |
| `test_predict_positive` | `/predict` retourne un JSON valide avec `label` et `score` dans les bonnes plages |
| `test_predict_empty_fails` | Pydantic rejette un texte vide avec HTTP 422 - valide la validation des entrées |

**En cas d'échec :** la cause la plus fréquente est un `__init__.py` manquant dans `src/` ou `tests/`, qui empêche Python de les traiter comme des packages importables.

---

### Question 4.2 - Tag annoté vs tag léger

**Tag léger (`git tag v0.1.0`) :**

Un tag léger est un simple alias (pointeur) vers un commit. Il ne stocke que le hash du commit cible - aucune métadonnée supplémentaire. Il ne crée pas d'objet Git dédié et n'apparaît pas dans `git log` avec `--decorate` de la même façon.

**Tag annoté (`git tag -a v0.1.0 -m "message"`) :**

Un tag annoté est un **objet Git à part entière**, stocké dans la base de données Git avec :
- Le nom du créateur et son email
- La date et l'heure de création
- Un message descriptif
- Une signature GPG optionnelle pour authentifier la version

**Pourquoi préférer les tags annotés en production ?**

| Critère | Tag léger | Tag annoté |
|---------|-----------|------------|
| Métadonnées (auteur, date) | ✗ | ✓ |
| Message de release | ✗ | ✓ |
| Signature GPG possible | ✗ | ✓ |
| Visible dans `git describe` | Parfois | ✓ |
| Interprété comme release par GitHub | ✗ | ✓ |

En production, les tags annotés permettent de savoir **qui** a validé la mise en production, **quand** et **pourquoi**. Ils sont reconnus par GitHub comme des releases officielles (affichées dans l'onglet *Releases*) et peuvent être signés cryptographiquement pour garantir leur authenticité. Dans les pipelines CI/CD, Jenkins et GitHub Actions peuvent déclencher des déploiements spécifiques uniquement sur les tags annotés, offrant ainsi un contrôle plus fin sur ce qui part en production.

---

## 6. Récapitulatif - À rendre

| Livrable | Critère de validation |
|----------|-----------------------|
| Repository GitHub `sentiment-ai` public | Structure complète visible sur GitHub |
| Tag `v0.1.0` | Visible dans `git tag -l` et sur GitHub (onglet Releases) |
| `Dockerfile` + `.dockerignore` + `docker-compose.yml` | Commités dans le repo |
| `Makefile` | Cibles `build`, `run`, `test`, `clean`, `tag` fonctionnelles |
| Screenshot `make test` | 3 tests verts avec coverage |
| Screenshot `docker compose ps` | Conteneur en statut `healthy` |
| Réponses aux questions | Sections 5.1 à 5.7 complétées |


---

# TP 2 - Jenkins Pipeline CI/CD

> **Formation DevOps** · Pipeline automatisé build / test / push pour le projet **SentimentAI**

### Roadmap de la formation

| TP | Contenu |
|----|---------|
| TP 1  | Git, Docker Compose, SentimentAI v0.1 |
| **TP 2** ← vous êtes ici | Jenkins pipeline - build, test, push |
| TP 3 | SonarQube, Trivy - Qualité & Sécurité |
| TP 4 | Terraform IaC, Docker provider |
| TP 5 | Monitoring, Prometheus, Grafana |

---

## Contexte et objectifs

**SentimentAI** est désormais versionnée dans Git et conteneurisée avec Docker (TP1). Ce TP automatise le cycle build / test / push :

À chaque `git push`, Jenkins récupère le code, le lint, construit l'image Docker, lance les tests et pousse l'image vers le registry si l'on est sur la branche `main`.

| Objectif | Livrable attendu |
|---|---|
| Installer Jenkins en conteneur (DooD) | Jenkins accessible sur `localhost:8080` |
| Écrire un pipeline as code | `Jenkinsfile` commité à la racine du repo |
| Automatiser le déclenchement | Webhook GitHub ou Poll SCM fonctionnel |
| Pousser l'image vers le registry | Image visible dans GitHub Packages (`ghcr.io`) |


### Prérequis pour le TP2

Le TP2 installera Jenkins via Docker et créera un pipeline Groovy (`Jenkinsfile`) complet avec les stages : **Checkout → Lint → Build → Test → Push**. Avant de passer au TP2, vérifiez que :

- Votre repo `sentiment-ai` est accessible **publiquement** sur GitHub
- La commande `make test` passe avec **3 tests verts**
- L'image Docker se build sans erreur avec `docker build`

>  **Explication du schéma :** Cette roadmap représente la progression logique des TPs. Chaque TP s'appuie sur les acquis du précédent. Le TP2 (Jenkins) consomme les artefacts du TP1 (image Docker + dépôt Git) pour automatiser le pipeline. Cette accumulation progressive est caractéristique d'une vraie mise en place DevOps en entreprise.

---

## Définitions clés

### Jenkins

**Jenkins** est un serveur d'automatisation open-source écrit en Java. Il permet de mettre en place des pipelines CI/CD (Intégration Continue / Déploiement Continu) qui s'exécutent automatiquement à chaque modification du code source.

### CI/CD

| Terme | Définition |
|---|---|
| **CI** - Intégration Continue | Pratique qui consiste à intégrer régulièrement le code dans un dépôt partagé, accompagné de tests automatiques. |
| **CD** - Déploiement Continu | Extension de la CI : chaque build validé est automatiquement déployé en production ou vers un registry. |
| **Pipeline** | Séquence d'étapes automatisées (stages) définissant le cycle de vie d'un build. |
| **Stage** | Étape individuelle d'un pipeline (ex. : Lint, Build, Test, Push). |

### Jenkinsfile

Fichier texte au format **Groovy** versionné dans le dépôt Git qui décrit le pipeline Jenkins. C'est le principe du **Pipeline as Code** : chaque modification du pipeline est traçable, reviewable en Pull Request et rollbackable comme n'importe quel fichier de code.

### Docker-out-of-Docker (DooD)

Technique permettant à un **conteneur Docker** (ici Jenkins) d'exécuter des commandes `docker build` en montant le socket Docker de l'hôte (`/var/run/docker.sock`). Jenkins ne fait pas tourner son propre daemon Docker, il pilote celui de la machine hôte.

```
Machine hôte
├── Docker daemon  ←── socket : /var/run/docker.sock
└── Conteneur Jenkins
    └── monte /var/run/docker.sock  →  peut faire docker build, docker push…
```

>  **Explication du schéma DooD :** Le daemon Docker est le processus central qui gère les conteneurs sur la machine hôte. En montant son socket dans le conteneur Jenkins, on lui permet d'envoyer des commandes au daemon hôte comme s'il était installé directement. Jenkins peut ainsi builder et pousser des images sans avoir son propre daemon Docker- d'où le nom "Docker-out-of-Docker" (par opposition à "Docker-in-Docker" qui ferait tourner un daemon complet à l'intérieur du conteneur).

> **Risque de sécurité** : monter le socket Docker donne au conteneur Jenkins les mêmes droits que `root` sur l'hôte. En production, on préférera [Kaniko](https://github.com/GoogleContainerTools/kaniko) ou [Buildah](https://buildah.io/), qui ne nécessitent pas de daemon Docker.

### Agent Jenkins

> Un **agent** est le nœud sur lequel s'exécute le pipeline.

| Déclaration | Comportement |
|---|---|
| `agent any` | S'exécute sur n'importe quel agent disponible (nœud Jenkins). |
| `agent { docker { image 'python:3.11' } }` | Lance un conteneur Docker éphémère avec l'image spécifiée. Utile pour isoler les dépendances. |

### Fail Fast

Principe CI/CD qui consiste à **détecter les erreurs le plus tôt possible** dans le pipeline pour éviter de gaspiller du temps de build. Le stage Lint s'exécute avant le Build pour échouer immédiatement si le code contient des erreurs de syntaxe.

### Quality Gate

Seuil de qualité minimal qu'un build doit franchir pour passer. Dans ce TP, le seuil est une **couverture de tests ≥ 70 %** (`--cov-fail-under=70`). Ce seuil sera renforcé à 80 % avec SonarQube au TP3.

### Image Tag & Traçabilité

Chaque image Docker est taguée avec le **SHA court du commit Git** (`git rev-parse --short HEAD`), par exemple `sentiment-ai:a3f8c12`. Cela permet de retrouver exactement quel commit correspond à quelle image déployée en production.

### Poll SCM vs Webhook

| Méthode | Principe | Délai | Charge serveur |
|---|---|---|---|
| **Poll SCM** | Jenkins interroge GitHub à intervalle fixe | Jusqu'à 5 min | Requêtes périodiques même sans changement |
| **Webhook** | GitHub notifie Jenkins à chaque `git push` | Quelques secondes | Requête uniquement en cas de push |

### withCredentials

Bloc Groovy qui injecte des secrets (tokens, mots de passe) comme variables d'environnement **au moment de l'exécution**. Les valeurs ne sont jamais visibles dans les logs Jenkins (remplacées par `****`). Le Jenkinsfile peut être commité dans Git sans exposer les secrets.

---

## Architecture du pipeline

```
git push
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│                     Jenkins Pipeline                    │
│                                                         │
│  ┌──────────┐  ┌──────┐  ┌────────────┐  ┌──────────┐  │
│  │ Checkout │→ │ Lint │→ │Build &Test │→ │  Push    │  │
│  │          │  │flake8│  │Docker+pytest│  │(main only)│ │
│  └──────────┘  └──────┘  └────────────┘  └──────────┘  │
│                                                         │
│  post { always { docker compose down -v } }             │
└─────────────────────────────────────────────────────────┘
                                                │
                                                ▼
                                       ghcr.io/PSEUDO/sentiment-ai
                                       :a3f8c12  (SHA tag)
                                       :latest
```

>  **Explication du schéma :** Chaque bloc représente un stage Jenkins. L'ordre est délibéré (principe Fail Fast) : Checkout d'abord (on a besoin du code), puis Lint (vérification syntaxique rapide avant de builder), puis Build & Test (opérations lourdes), puis Push uniquement si tout est vert et sur `main`. Le bloc `post { always }` s'exécute après tous les stages quelle que soit l'issue pour nettoyer les ressources. La flèche finale représente l'image publiée dans le registry GitHub avec deux tags : le SHA pour la traçabilité et `latest` pour la commodité.

---

## Prérequis

- Docker installé et en cours d'exécution sur votre machine
- Un compte GitHub avec un dépôt `sentiment-ai` (TP1 complété)
- Git configuré localement (`git config --global user.name/email`)
- Accès à `localhost:8080` (aucun autre service ne doit utiliser ce port)

---

## Partie 1 - Installer Jenkins via Docker

### Concepts abordés

- **Volume Docker** : espace de stockage persistant indépendant du cycle de vie du conteneur.
- **Docker socket** : interface Unix permettant à un processus de communiquer avec le daemon Docker.

### 1.1 Lancer Jenkins

Jenkins sera installé dans un conteneur Docker qui a accès au daemon Docker de l'hôte via la technique **DooD**.

```bash
# Créer un volume pour persister les données Jenkins entre les redémarrages
docker volume create jenkins-data
```

>  **Explication :** `docker volume create` crée un volume Docker nommé `jenkins-data`. Un volume est un espace de stockage géré par Docker, indépendant du système de fichiers du conteneur. Les données écrites dans ce volume survivent aux arrêts, redémarrages et suppressions du conteneur Jenkins- permettant de conserver jobs, builds, plugins et credentials entre les sessions.

![image](https://hackmd.io/_uploads/ByPBhVbMMl.png)

```bash
# Lancer Jenkins avec accès au Docker de l'hôte
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins-data:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts
```

>  **Explication de chaque option :**
> - `-d` : mode détaché (arrière-plan).
> - `--name jenkins` : nom lisible pour référencer le conteneur.
> - `-p 8080:8080` : accès à l'interface web Jenkins (hôte:conteneur).
> - `-p 50000:50000` : port de communication Jenkins master-agent (pour les agents Jenkins distants).
> - `-v jenkins-data:/var/jenkins_home` : monte le volume persistant sur le répertoire home de Jenkins- **toutes les données Jenkins** (jobs, plugins, configurations) sont stockées ici.
> - `-v /var/run/docker.sock:/var/run/docker.sock` : monte le socket Docker de l'hôte dans le conteneur, permettant au pipeline Jenkins d'exécuter `docker build` et `docker push` via le daemon hôte (technique DooD).
> - `jenkins/jenkins:lts` : image officielle Jenkins en version LTS (Long Term Support), la plus stable.

![image](https://hackmd.io/_uploads/ByV_3E-Mzx.png)

```bash
# Vérifier que Jenkins démarre correctement
docker logs -f jenkins
# Attendez la ligne : Jenkins is fully up and running
```

>  **Explication :** `docker logs -f` suit les logs en temps réel (`-f` = follow). Jenkins prend 30 à 60 secondes pour démarrer complètement (JVM + chargement des plugins). La ligne `Jenkins is fully up and running` confirme que le serveur est prêt à accepter des connexions sur le port 8080. `Ctrl+C` arrête le suivi sans arrêter Jenkins.

![image](https://hackmd.io/_uploads/HyyLaEbffl.png)

```bash
# Vérifier que Jenkins peut accéder à Docker
docker exec -u jenkins jenkins docker ps
```

>  **Explication :** `docker exec -u jenkins jenkins docker ps` exécute la commande `docker ps` **à l'intérieur** du conteneur Jenkins, avec l'identité de l'utilisateur `jenkins`. Si la commande liste les conteneurs en cours d'exécution, cela confirme que Jenkins peut communiquer avec le daemon Docker de l'hôte via le socket monté.

**Si erreur `executable file not found`** → installer Docker dans le conteneur :

```bash
docker exec -u root jenkins bash -c "
  apt-get update -q &&
  apt-get install -y docker.io
"
```

>  **Explication :** L'image `jenkins/jenkins:lts` n'inclut pas le client Docker. Cette commande s'exécute en tant que `root` dans le conteneur Jenkins pour installer `docker.io` (le client Docker CLI). `apt-get update -q` met à jour la liste des paquets silencieusement (`-q` = quiet). `&&` enchaîne les commandes.

![image](https://hackmd.io/_uploads/Sk6g0Ebfzl.png)

**Si erreur `permission denied`** → corriger les permissions du socket :

![image](https://hackmd.io/_uploads/B1tfA4ZGMx.png)

```bash
docker exec -u root jenkins chmod 666 /var/run/docker.sock

# Retester
docker exec -u jenkins jenkins docker ps
```

>  **Explication :** Par défaut, le socket `/var/run/docker.sock` appartient au groupe `docker` de l'hôte. L'utilisateur `jenkins` du conteneur n'appartient pas nécessairement à ce groupe. `chmod 666` donne les permissions de lecture et écriture à tous les utilisateurs sur le socket. Note : cette solution est simple mais réduit la sécurité- en production, on ajouterait l'utilisateur `jenkins` au groupe `docker`.

![image](https://hackmd.io/_uploads/H1fE04-ffe.png)
![image](https://hackmd.io/_uploads/ryb8R4-MGl.png)

> **Rôle des montages :**
> - `/var/run/docker.sock` : expose le socket Unix du daemon Docker de l'hôte à l'intérieur du conteneur Jenkins. Sans cela, Jenkins ne pourrait pas exécuter `docker build` et `docker push` depuis le pipeline.
> - `jenkins-data` : persiste les jobs, builds, plugins et credentials même si le conteneur est recréé ou mis à jour.

### 1.2 Première configuration Jenkins

1. Ouvrez `http://localhost:8080` dans votre navigateur.
2. Récupérez le mot de passe initial :
   ```bash
   docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
   ```

>  **Explication :** Jenkins génère un mot de passe aléatoire lors du premier démarrage et le stocke dans `/var/jenkins_home/secrets/initialAdminPassword`. `docker exec jenkins cat ...` lit ce fichier depuis l'intérieur du conteneur et l'affiche dans le terminal. Ce mot de passe à usage unique est requis pour débloquer Jenkins lors de la première connexion.

3. Collez ce mot de passe dans l'interface Jenkins.
4. Choisissez **« Install suggested plugins »** et attendez la fin de l'installation.
5. Créez votre compte administrateur (notez login / mot de passe).
6. Cliquez **« Save and Finish »** → **« Start using Jenkins »**.

![image](https://hackmd.io/_uploads/ryrnAVZMGl.png)
![image](https://hackmd.io/_uploads/SkuR0VZMMl.png)
![image](https://hackmd.io/_uploads/B1Q11BWzMe.png)
![image](https://hackmd.io/_uploads/HJo_1HZMzx.png)
![image](https://hackmd.io/_uploads/By5pkB-Mze.png)
![image](https://hackmd.io/_uploads/ryOCkBZGzx.png)
![image](https://hackmd.io/_uploads/rJv1lr-fMx.png)

### 1.3 Installer les plugins nécessaires

Jenkins a besoin du plugin **Docker Pipeline** pour exécuter des commandes Docker dans un Jenkinsfile.

1. Jenkins → Tableau de bord → **Administrer Jenkins** → **Plugins**
2. Onglet **« Available plugins »** → cherchez et installez :
   - `Docker Pipeline`
   - `Git`
   - `Pipeline`
   - `Blue Ocean`
3. Redémarrez Jenkins après l'installation si demandé.

![image](https://hackmd.io/_uploads/B17IgH-fGg.png)

- Vérification
```bash
docker exec jenkins sh -c '
echo "Docker Pipeline:"; ls /var/jenkins_home/plugins/docker-workflow.jpi 2>/dev/null && echo OK;
echo "Git:"; ls /var/jenkins_home/plugins/git.jpi 2>/dev/null && echo OK;
echo "Pipeline:"; ls /var/jenkins_home/plugins/workflow-aggregator.jpi 2>/dev/null && echo OK;
echo "Blue Ocean:"; ls /var/jenkins_home/plugins/blueocean.jpi 2>/dev/null && echo OK;
'
```

>  **Explication :** Ce script vérifie que les fichiers `.jpi` (Jenkins Plugin Interface) des plugins installés existent dans le répertoire des plugins Jenkins. `2>/dev/null` redirige les erreurs (fichier non trouvé) vers `/dev/null` pour ne pas les afficher. `&& echo OK` s'affiche uniquement si le fichier existe- permettant de confirmer que chaque plugin est installé.

![image](https://hackmd.io/_uploads/Sy2NGHbMMe.png)

### 1.4 Configurer les credentials GitHub

Jenkins a besoin d'un token GitHub pour cloner le repo et pousser les images vers `ghcr.io`. **Le token ne doit jamais être écrit en clair dans le Jenkinsfile.**

**Créer un token sur GitHub :**

1. GitHub → Settings → Developer settings → Personal access tokens → **Tokens (classic)**
2. Generate new token → cochez : `repo`, `read:packages`, `write:packages`
3. Copiez le token généré *(affiché une seule fois)*.
![image](https://hackmd.io/_uploads/H1PQoHbGzx.png)

```bash
# Vérifier que GitHub CLI (gh) est installé et afficher sa version
gh --version

# Se connecter à GitHub depuis le terminal (authentification du compte)
gh auth login

# Mettre à jour le token GitHub existant avec les permissions nécessaires :
# - repo : accès aux dépôts GitHub
# - read:packages : lecture des packages GitHub
# - write:packages : écriture/publication des packages GitHub
gh auth refresh -h github.com -s repo,read:packages,write:packages

# Vérifier l'état de la connexion GitHub et les permissions du token
gh auth status

# Afficher le token GitHub actuellement utilisé
gh auth token
```

>  **Explication des commandes `gh` :**
> - `gh --version` : confirme que le CLI GitHub est installé.
> - `gh auth login` : authentification interactive du CLI auprès de GitHub.
> - `gh auth refresh -h github.com -s repo,read:packages,write:packages` : renouvelle le token d'authentification en ajoutant les scopes (permissions) nécessaires pour cloner des dépôts (`repo`), lire (`read:packages`) et écrire (`write:packages`) dans GitHub Container Registry.
> - `gh auth status` : affiche les informations du compte connecté et les scopes accordés- permet de vérifier que toutes les permissions sont présentes.
> - `gh auth token` : affiche le token d'accès personnel actuel. Ce token sera copié dans Jenkins comme credential.

![image](https://hackmd.io/_uploads/SkjdmS-fMg.png)
![image](https://hackmd.io/_uploads/H1Sg4rbMMe.png)
![image](https://hackmd.io/_uploads/HJkm4BbGMg.png)

**Enregistrer le token dans Jenkins :**

1. Jenkins → Administrer Jenkins → Credentials → System → **Global credentials**
2. Add Credentials → Kind : **Username with password**
3. Username : votre pseudo GitHub | Password : le token | ID : `github-token`
4. Cliquez **Create**.
![image](https://hackmd.io/_uploads/HyYc4BWGMe.png)
![image](https://hackmd.io/_uploads/SktjEHWfGe.png)
![image](https://hackmd.io/_uploads/HJmM3SWGzg.png)
![image](https://hackmd.io/_uploads/B1MXhHbfzx.png)

---

###  Questions - Partie 1

**Question 1.1**
Faites un screenshot de la page d'accueil Jenkins (Dashboard) avec votre compte connecté. Quel est le rôle du volume `jenkins-data` monté sur `/var/jenkins_home` ?
![image](https://hackmd.io/_uploads/HkNeUrbfGl.png)

Le volume `jenkins-data` monté sur `/var/jenkins_home` joue le rôle de **stockage persistant** pour Jenkins.

Par défaut, toutes les données Jenkins (jobs, historique des builds, plugins installés, credentials, configuration) sont stockées dans `/var/jenkins_home` à l'intérieur du conteneur. Or, un conteneur Docker est **éphémère** : si on le supprime, recrée ou met à jour, tout son contenu interne est perdu.

En montant le volume `jenkins-data` sur ce chemin, on découple les données du conteneur :

- Si on fait `docker rm jenkins` puis `docker run ... jenkins/jenkins:lts`, Jenkins retrouve exactement l'état où on l'avait laissé- jobs configurés, builds passés, plugins, credentials inclus.
- On peut mettre à jour l'image Jenkins (passage de `lts` à une version plus récente) sans perdre aucune configuration.
- On peut sauvegarder les données Jenkins simplement en sauvegardant le volume.

En résumé : **le conteneur est jetable, les données ne le sont pas**.

**Question 1.2**
Expliquez en deux phrases pourquoi on monte `/var/run/docker.sock` dans le conteneur Jenkins. Quel risque de sécurité cela représente-t-il ? Comment le limiterait-on en production ?

`/var/run/docker.sock` est le socket Unix par lequel on communique avec le daemon Docker de l'hôte. En le montant dans le conteneur Jenkins, on lui permet d'envoyer des commandes Docker (docker build, docker push, docker run) directement au daemon de la machine hôte, sans avoir à faire tourner un second daemon Docker à l'intérieur du conteneur.

---

## Partie 2 - Écrire le Jenkinsfile

### 2.1 Structure de base

Créez le fichier `Jenkinsfile` à la racine de votre projet `sentiment-ai` :

```bash
cat > Jenkinsfile <<'EOF'
pipeline {
  agent any

  environment {
    IMAGE_NAME = 'sentiment-ai'
    REGISTRY   = 'ghcr.io/VOTRE_PSEUDO'

    IMAGE_TAG = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
  }

  stages {
    // Les 4 stages seront ajoutés ici
  }

  post {
    always {
      sh 'docker compose down -v 2>/dev/null || true'
    }
    success {
      echo "Pipeline réussi ! Image : ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
    }
    failure {
      echo 'Pipeline échoué. Consultez les logs ci-dessus.'
    }
  }
}
EOF
```

>  **Explication de la structure de base du Jenkinsfile :**
> - `pipeline { }` : bloc racine obligatoire de tout Jenkinsfile déclaratif. Tout le pipeline est défini à l'intérieur.
> - `agent any` : indique que le pipeline peut s'exécuter sur n'importe quel nœud Jenkins disponible (ici, le nœud master).
> - `environment { }` : bloc de déclaration de variables d'environnement disponibles dans tous les stages.
>   - `IMAGE_NAME` et `REGISTRY` : constantes définissant les coordonnées de l'image Docker.
>   - `IMAGE_TAG = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()` : **évaluation dynamique**- exécute une commande shell pour obtenir le SHA court du dernier commit Git et l'assigne à la variable. `.trim()` supprime le saut de ligne final retourné par la commande shell.
> - `stages { }` : contiendra les 4 stages du pipeline (Checkout, Lint, Build&Test, Push).
> - `post { }` : actions post-pipeline. `always` s'exécute systématiquement, `success` uniquement en cas de succès, `failure` uniquement en cas d'échec.
> - `2>/dev/null` : redirige stderr vers /dev/null (silence les erreurs). `|| true` rend la commande toujours "réussie".

![image](https://hackmd.io/_uploads/ByABUH-zfg.png)

- Modifier le pseudo
![image](https://hackmd.io/_uploads/HyqRIrWGMx.png)
![image](https://hackmd.io/_uploads/HyzlDS-zfg.png)

**Comprendre `environment { }` et `IMAGE_TAG`**
`IMAGE_TAG` utilise `sh(...)` pour exécuter une commande shell et capturer sa sortie. `git rev-parse --short HEAD` retourne les 7 premiers caractères du SHA du dernier commit.
Résultat : chaque build produit une image taguée de façon unique, par exemple `sentiment-ai:a3f8c12`. On peut toujours retrouver exactement quel commit correspond à quelle image déployée en production.

### 2.2 Stage 1 - Checkout

Le stage **Checkout** demande à Jenkins de cloner le code source depuis le repository configuré dans le job. `checkout scm` est une abréviation Groovy qui utilise automatiquement la configuration SCM du job Jenkins.

```groovy
stage('Checkout') {
  steps {
    checkout scm
    echo "Branche : ${env.BRANCH_NAME}"
    echo "Commit  : ${env.GIT_COMMIT}"
    sh 'git log --oneline -5'
  }
}
```

>  **Explication du stage Checkout :**
> - `checkout scm` : commande Jenkins qui clone le dépôt Git configuré dans le job (URL + credentials + branche). `scm` est une variable Groovy magique qui référence la configuration SCM du job.
> - `${env.BRANCH_NAME}` : variable d'environnement Jenkins injectée automatiquement- contient le nom de la branche en cours de build (ex. `main`, `feat/my-feature`).
> - `${env.GIT_COMMIT}` : SHA complet du commit en cours de build- utile pour la traçabilité dans les logs.
> - `sh 'git log --oneline -5'` : affiche les 5 derniers commits dans les logs Jenkins, utile pour confirmer que le bon code a été récupéré.

### 2.3 Stage 2 - Lint

Le **Lint** analyse le code Python avec `flake8` avant même de construire l'image Docker. C'est le principe **Fail Fast** : détecter les erreurs de syntaxe le plus tôt possible. `flake8` est lancé dans un conteneur Docker éphémère - aucune dépendance sur l'agent Jenkins.

```groovy
stage('Lint') {
  steps {
    sh '''
      docker run --rm \
        --volumes-from jenkins \
        -w $WORKSPACE \
        python:3.12-slim \
        sh -c "pip install flake8 -q && flake8 src/ --max-line-length=100"
    '''
  }
}
```

>  **Explication du stage Lint :**
> - `docker run --rm` : lance un conteneur qui sera **automatiquement supprimé** après son exécution (`--rm`). Évite l'accumulation de conteneurs orphelins.
> - `--volumes-from jenkins` : monte tous les volumes du conteneur Jenkins dans ce conteneur temporaire. Cela donne accès au `$WORKSPACE` (répertoire de travail Jenkins contenant le code source cloné).
> - `-w $WORKSPACE` : définit `$WORKSPACE` comme répertoire de travail. `$WORKSPACE` est une variable Jenkins pointant vers le répertoire où le code a été cloné.
> - `python:3.12-slim` : image Python officielle légère- pas besoin de l'image SentimentAI complète pour faire du lint.
> - `pip install flake8 -q && flake8 src/ --max-line-length=100` : installe flake8 silencieusement (`-q`) puis l'exécute sur le dossier `src/`. `--max-line-length=100` tolère des lignes jusqu'à 100 caractères (la limite par défaut est 79).

![image](https://hackmd.io/_uploads/BJuAvSZMzg.png)

> **Erreurs flake8 courantes et corrections**
>
> | Code | Signification | Correction |
> |---|---|---|
> | `W292` | Pas de saut de ligne en fin de fichier | Ajouter une ligne vide à la fin |
> | `W291` | Espaces en fin de ligne | Supprimer les espaces trailing |
> | `E302` | 2 lignes vides attendues | Ajouter des lignes vides entre fonctions |
> | `E501` | Ligne trop longue (> 100 caractères) | Couper la ligne |
> | `F401` | Import non utilisé | Supprimer l'import |

Pour corriger automatiquement :

```bash
pip install autopep8
autopep8 --in-place --aggressive src/main.py src/model.py src/schemas.py
flake8 src/ --max-line-length=100
git add src/
git commit -m "fix: correct flake8 style errors"
git push origin main
```

>  **Explication de la correction automatique :**
> - `autopep8 --in-place --aggressive` : outil qui corrige **automatiquement** les erreurs de style PEP 8 directement dans les fichiers. `--in-place` modifie les fichiers existants. `--aggressive` applique des corrections plus poussées.
> - Après correction, `flake8` vérifie qu'il ne reste plus d'erreurs. On commit et push pour que le prochain build Jenkins passe le stage Lint.

### 2.4 Stage 3 - Build & Test

Ce stage construit l'image Docker avec le SHA Git comme tag, puis lance `pytest` à l'intérieur de cette image. **Tester dans l'image buildée garantit que les tests s'exécutent dans le même environnement que la production.**

```groovy
stage('Build & Test') {
  steps {
    sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
    sh """
      docker run --rm \
        ${IMAGE_NAME}:${IMAGE_TAG} \
        pytest tests/ -v \
          --cov=src \
          --cov-report=xml:coverage.xml \
          --cov-report=term-missing \
          --cov-fail-under=70
    """
  }
  post {
    failure {
      echo 'Tests échoués ou coverage insuffisant (< 70%)'
    }
  }
}
```

>  **Explication du stage Build & Test :**
> - `docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .` : construit l'image Docker taguée avec le SHA Git court. `${IMAGE_NAME}` et `${IMAGE_TAG}` sont interpolées depuis le bloc `environment`.
> - `docker run --rm ${IMAGE_NAME}:${IMAGE_TAG} pytest tests/ -v` : lance pytest **à l'intérieur de l'image fraîchement construite**. Garantit que les tests s'exécutent dans les mêmes conditions qu'en production.
> - `--cov=src` : mesure la couverture de code du package `src/`.
> - `--cov-report=xml:coverage.xml` : génère un rapport XML de couverture (sera consommé par SonarQube au TP3).
> - `--cov-report=term-missing` : affiche dans les logs Jenkins les numéros de lignes non couvertes.
> - `--cov-fail-under=70` : **Quality Gate**- fait échouer pytest (code de sortie non nul) si la couverture est inférieure à 70%, ce qui fait échouer le stage Jenkins.
> - `post { failure { ... } }` : message d'erreur explicite affiché dans les logs si ce stage échoue, guidant le développeur vers la cause probable.

### 2.5 Stage 4 - Push (conditionnel)

Le **Push** ne s'exécute que sur la branche `main`. Les branches de feature sont buildées et testées mais leurs images ne sont pas poussées vers le registry - cela évite de polluer le registry avec des images non validées.

```groovy
stage('Push') {
  when { branch 'main' }
  steps {
    withCredentials([usernamePassword(
      credentialsId: 'github-token',
      usernameVariable: 'REGISTRY_USER',
      passwordVariable: 'REGISTRY_PASS'
    )]) {
      sh """
        echo \$REGISTRY_PASS | docker login ghcr.io \
          -u \$REGISTRY_USER --password-stdin
        docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
        docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${REGISTRY}/${IMAGE_NAME}:latest
        docker push ${REGISTRY}/${IMAGE_NAME}:latest
      """
    }
  }
}
```

>  **Explication du stage Push :**
> - `when { branch 'main' }` : condition Groovy qui exécute ce stage **uniquement si la branche en cours est `main`**. Sur toute autre branche (feature, bugfix, etc.), ce stage est sauté.
> - `withCredentials([usernamePassword(...)])` : injecte le credential Jenkins `github-token` comme variables d'environnement `REGISTRY_USER` et `REGISTRY_PASS`. Les valeurs sont masquées dans les logs.
> - `echo $REGISTRY_PASS | docker login ghcr.io -u $REGISTRY_USER --password-stdin` : authentification à GitHub Container Registry. `--password-stdin` lit le mot de passe depuis stdin (plus sécurisé que de le passer en argument de ligne de commande, visible dans `ps aux`).
> - `docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}` : pousse l'image avec le tag SHA unique.
> - `docker tag ... :latest` + `docker push ... :latest` : crée et pousse le tag `latest` qui pointe toujours vers le dernier build de `main`.

![image](https://hackmd.io/_uploads/HJAUOrWzMg.png)

**Sécurité - `withCredentials`**
Ne jamais écrire un token ou mot de passe directement dans le Jenkinsfile : il serait stocké dans Git et visible par tous. `withCredentials` injecte les secrets comme variables d'environnement au moment de l'exécution. Les valeurs ne sont jamais visibles dans les logs Jenkins (remplacées par `****`). Le Jenkinsfile peut être commité dans Git sans risque.

#### Fichier complet Jenkinsfile

```bash
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

    stage('Build Docker') {
      steps {
        sh '''
          docker build -t sentiment-ai:${IMAGE_TAG} .
        '''
      }
    }

    stage('Test') {
      steps {
        sh '''
          docker run --rm \
            sentiment-ai:${IMAGE_TAG} \
            pytest tests -v
        '''
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
```

>  **Explication du Jenkinsfile complet :**
> - **Stage `Checkout`** : clone le code et calcule `IMAGE_TAG` dynamiquement via un bloc `script { }` (nécessaire car `env.IMAGE_TAG` doit être défini après le checkout pour que `git rev-parse` fonctionne correctement).
> - **Stage `Info`** : stage de diagnostic- affiche les 3 derniers commits et confirme que le workspace est accessible. Utile pour déboguer les problèmes de checkout.
> - **Stage `Lint`** : utilise `-v $WORKSPACE:/app` pour monter le workspace Jenkins directement dans le conteneur (alternative à `--volumes-from jenkins`).
> - **Stage `Build Docker`** : build l'image taguée avec le SHA. Utilise des guillemets simples triples `'''` pour le script shell multi-lignes.
> - **Stage `Test`** : lance pytest dans l'image buildée. Séparé du build pour une meilleure lisibilité dans la vue des stages Jenkins.
> - **Stage `Push to GHCR`** : pousse l'image vers GitHub Container Registry avec les deux tags (SHA et latest).

### 2.6 Commiter le Jenkinsfile

```bash
git add Jenkinsfile
git commit -m "ci: add Jenkinsfile with 4 stages"
git push origin main
```

>  **Explication :** Le préfixe `ci:` (Conventional Commits) indique que ce commit concerne l'infrastructure de CI/CD plutôt que le code applicatif. Commiter le Jenkinsfile dans Git est l'essence même du **Pipeline as Code** : le pipeline est versionné, reviewable et rollbackable comme n'importe quel fichier source.

---

###  Questions - Partie 2

**Question 2.1**
À quoi sert le bloc `post { always { } }` dans le pipeline ? Pourquoi ajoute-t-on `|| true` à la commande `docker compose down` ?

Le bloc `post` définit des actions à exécuter **après la fin des stages**, quel que soit le résultat du pipeline. Il existe plusieurs conditions :

| Condition | Déclenchement |
|---|---|
| `always` | Toujours, succès ou échec |
| `success` | Uniquement si tous les stages ont réussi |
| `failure` | Uniquement si au moins un stage a échoué |
| `unstable` | Si le build est instable (tests avec warnings) |

Dans notre pipeline, `post { always { } }` contient :

```groovy
sh 'docker compose down -v 2>/dev/null || true'
```

Son rôle est de **nettoyer les conteneurs et volumes de test** après chaque build, peu importe ce qui s'est passé. Sans ce bloc, si un stage échoue en plein milieu d'un `docker compose up`, les conteneurs resteraient actifs et consommeraient des ressources inutilement - et les builds suivants pourraient entrer en conflit avec ces conteneurs orphelins.


`|| true` est un opérateur shell qui dit : **"si la commande de gauche échoue, exécute `true` à la place"**. `true` retourne toujours le code de sortie `0` (succès).

Sans `|| true`, deux scénarios posent problème :

**Scénario 1 - Le stage a échoué avant même le `docker compose up`**
Aucun conteneur n'a été lancé. `docker compose down` ne trouve rien à arrêter et retourne une erreur. Jenkins interprète cette erreur et **marque le build comme échoué** à cause du nettoyage, masquant la vraie cause de l'échec.

**Scénario 2 - `docker compose` n'est pas installé sur l'agent**
Même problème : la commande échoue, le pipeline plante sur le nettoyage.

Avec `|| true`, si `docker compose down` échoue pour n'importe quelle raison, le shell retourne `0` et Jenkins continue sans marquer le build comme échoué à cause du nettoyage.


En résumé : `|| true` rend le nettoyage **non bloquant** - il est tenté dans tous les cas, mais son échec éventuel n'impacte pas le résultat final du build.

**Question 2.2**
Expliquez la différence entre `agent any` et `agent { docker { image 'python:3.11' } }`. Dans quel cas utiliseriez-vous le second ?

**Question 2.3**
Pourquoi le stage Push utilise-t-il `when { branch 'main' }` ? Que se passerait-il si on poussait une image pour chaque branche feature ?

---

## Partie 3 - Créer et exécuter le job Jenkins

### 3.1 Créer un job Pipeline dans Jenkins

1. Jenkins → **Nouveau Item** → Nom : `sentiment-ai-pipeline` → Type : **Pipeline** → OK
2. Section **General** : cochez **« GitHub project »** → URL de votre repo GitHub
3. Section **Build Triggers** : cochez **« Poll SCM »** → Schedule : `H/5 * * * *`
   *(Jenkins vérifiera les nouveaux commits toutes les 5 minutes)*
4. Section **Pipeline** :
   - Definition : `Pipeline script from SCM`
   - SCM : `Git`
   - Repository URL : URL HTTPS de votre repo
   - Credentials : `github-token`
   - Branch Specifier : `*/main`
   - Script Path : `Jenkinsfile`
5. Cliquez **Save**.

![image](https://hackmd.io/_uploads/r1mwKBZGMe.png)
![image](https://hackmd.io/_uploads/Sk_TnSZMGe.png)
![image](https://hackmd.io/_uploads/B1wAnB-zGl.png)
![image](https://hackmd.io/_uploads/HyVJ6S-Mfl.png)
![image](https://hackmd.io/_uploads/H1tbTHbGGx.png)
![image](https://hackmd.io/_uploads/rJCf6B-fzg.png)

### 3.2 Lancer le premier build

```bash
# Vérifier que le Jenkinsfile est bien poussé sur main
git log --oneline origin/main | head -3
```

>  **Explication :** `git log --oneline origin/main` affiche l'historique de la branche `main` sur le remote GitHub (pas la branche locale). `| head -3` limite l'affichage aux 3 commits les plus récents. Permet de confirmer que le Jenkinsfile est bien présent dans les derniers commits avant de déclencher le build.

![image](https://hackmd.io/_uploads/rycFpH-GGl.png)

Dans Jenkins, cliquez sur le job `sentiment-ai-pipeline` puis **Build Now**. Surveillez le build en temps réel : cliquez sur le numéro du build → **Console Output**.
![image](https://hackmd.io/_uploads/ry-1WLbffg.png)

![image](https://hackmd.io/_uploads/H1T_mIbzGx.png)


| Indicateur | Signification | Action si problème |
|---|---|---|
| Build stable | Tous les stages ont réussi | Parfait ! |
| Build échoué | Au moins un stage a échoué | Consulter Console Output |
| Build instable | Tests avec warnings | Lire les warnings pytest |

### 3.3 Déboguer un stage en échec

```bash
# Erreur 1 : Docker non accessible depuis Jenkins
docker exec jenkins docker ps
# Si erreur : vérifier que /var/run/docker.sock est bien monté

# Erreur 2 : Permission denied sur docker.sock
docker exec -u root jenkins chmod 666 /var/run/docker.sock

# Erreur 3 : Module Python non trouvé dans les tests
# → Vérifier que "COPY src/" est bien dans le Dockerfile

# Erreur 4 : Credentials incorrects pour le push
# → Revérifier l'ID dans withCredentials(credentialsId: 'github-token')
```

>  **Explication du guide de débogage :**
> - **Erreur 1** : test de connectivité Docker depuis Jenkins. Si `docker ps` retourne une erreur, le socket n'est pas accessible- vérifier les options `-v /var/run/docker.sock:/var/run/docker.sock` dans la commande `docker run` de Jenkins.
> - **Erreur 2** : solution rapide pour les erreurs de permissions sur le socket (à reappliquer si le conteneur Jenkins a été redémarré).
> - **Erreur 3** : `ModuleNotFoundError: No module named 'src'` est l'erreur la plus courante. Elle signifie que le Dockerfile ne copie pas correctement `src/` ou que `__init__.py` est manquant.
> - **Erreur 4** : `unauthorized` lors du push vers ghcr.io- vérifier que l'ID du credential dans Jenkins correspond exactement à celui référencé dans `withCredentials(credentialsId: ...)`.

---

###  Questions - Partie 3

**Question 3.1**
Faites un screenshot du pipeline après le premier build réussi (vue stages ou Console Output). Quel tag a été attribué à l'image Docker construite ? Retrouvez cette valeur dans les logs Jenkins.
![image](https://hackmd.io/_uploads/B1-xZ8bGfx.png)

```Bash
git rev-parse --short HEAD
```

> **Explication :** `git rev-parse --short HEAD` calcule le SHA court (7 caractères) du dernier commit local. Ce hash unique identifie précisément l'état du code au moment du build. Il est utilisé comme tag d'image Docker pour garantir la traçabilité entre le code source et l'image déployée en production.

![image](https://hackmd.io/_uploads/Hk7rbLbGGe.png)

**Tag = 997da42**

**Question 3.2**
Faites un second build en modifiant un fichier source (par exemple, ajouter un commentaire dans `src/main.py`). Le pipeline se relance-t-il automatiquement au bout de 5 minutes ? Vérifiez sur GitHub : l'image apparaît-elle dans les **Packages / Registry** ?

- On ajoute un commentaire dans le fichier 

```bash
echo "# test pipeline second build" >> src/main.py
```

>  **Explication :** `echo "..." >> fichier` ajoute (`>>`) le texte à la fin du fichier sans l'écraser (`>` écraserait). L'ajout d'un commentaire Python (ligne commençant par `#`) est une modification minimale qui ne change pas le comportement de l'application mais force Git à voir un changement- ce qui déclenchera le pipeline Jenkins.

![image](https://hackmd.io/_uploads/S1YAWIZzfx.png)

- Commit + push

```
git add src/main.py
git commit -m "test: trigger second Jenkins build"
git push origin main
```
![image](https://hackmd.io/_uploads/HkWWm8ZzGx.png)

Le pipeline se relance automatiquement après un push GitHub grâce au mécanisme de polling/trigger SCM Jenkins. Cependant, l'image Docker n'est pas encore visible dans GitHub Packages, car la phase de push vers le registry n'est pas exécutée dans le pipeline actuel. 
![image](https://hackmd.io/_uploads/r1tFHL-MMx.png)

Après avoir apporté des modifications au niveau du fichier **Jenkinsfile**,  l'image est visible dans Github Packages et connectée avec le repo.
![image](https://hackmd.io/_uploads/H1HZuL-zfe.png)

---

## Partie 4 - Webhook · Déclenchement automatique

Actuellement Jenkins vérifie les nouveaux commits toutes les 5 minutes (Poll SCM). Avec un webhook, GitHub notifie Jenkins **instantanément** à chaque `git push`.

### 4.1 Exposer Jenkins avec ngrok

Jenkins tourne en local sur votre machine. GitHub ne peut pas y accéder directement. **ngrok** crée un tunnel public temporaire qui rend Jenkins accessible depuis l'extérieur.

```bash
# Ajouter la clé GPG
curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null

# Ajouter le dépôt
echo "deb https://ngrok-agent.s3.amazonaws.com bookworm main" | sudo tee /etc/apt/sources.list.d/ngrok.list

# Mettre à jour et installer
sudo apt update
sudo apt install ngrok

# Vérifier la version
ngrok --version
# Vérifier l'installation
ngrok --version

# Configurer votre token (syntaxe v3)
# Pour avoir le token aller  sur le site officiel et créer un compte; à la fin vous aurez le token. Site : https://dashboard.ngrok.com/
ngrok config add-authtoken + Mettre le token

# Démarrer le tunnel
nohup ngrok http 8080 --log=stdout --log-level=info > ngrok.log 2>&1 &

# Attendre le démarrage
sleep 3

# Récupérer l'URL
curl -s http://localhost:4040/api/tunnels | python3 -c "import sys, json; data=json.load(sys.stdin); print(' URL publique :', data['tunnels'][0]['public_url'])"

```

> **Explication de l'installation et lancement de ngrok :**
> - `curl ... | sudo tee ...` : ajoute la clé GPG de ngrok au trousseau de confiance APT, permettant à `apt` de vérifier l'authenticité des paquets ngrok.
> - `echo "deb ..." | sudo tee ...` : ajoute le dépôt officiel ngrok à la liste des sources APT.
> - `sudo apt update && sudo apt install ngrok` : met à jour la liste des paquets et installe ngrok.
> - `ngrok config add-authtoken <TOKEN>` : associe l'installation ngrok à votre compte. Sans token, les tunnels sont limités (connexions simultanées, durée, etc.).
> - `nohup ngrok http 8080 ... &` : démarre ngrok en arrière-plan (`&`). `nohup` empêche ngrok de s'arrêter si le terminal est fermé. Les logs sont redirigés vers `ngrok.log`.
> - `sleep 3` : attend 3 secondes que ngrok s'initialise et ouvre le tunnel.
> - `curl -s http://localhost:4040/api/tunnels` : ngrok expose une API locale sur le port 4040. Cette commande récupère les informations du tunnel actif, notamment l'URL publique HTTPS qui rend Jenkins accessible depuis internet.

 **ngrok non disponible ?**
Si ngrok n'est pas disponible, continuez avec le Poll SCM configuré à `H/5 * * * *`. Le pipeline se déclenchera automatiquement toutes les 5 minutes - suffisant pour ce TP. En entreprise, Jenkins est généralement hébergé sur un serveur avec une IP publique fixe.

### 4.2 Configurer le webhook sur GitHub

1. Repository GitHub → Settings → **Webhooks** → **Add webhook**
2. Payload URL : `https://VOTRE_URL_NGROK/github-webhook/`
3. Content type : `application/json`
4. Which events : **Just the push event**
5. Active : coché → **Add webhook**

![image](https://hackmd.io/_uploads/HkDSQv-fMx.png)

### 4.3 Activer les triggers GitHub dans Jenkins

1. Jenkins → votre job → **Configurer**
2. Section **Build Triggers** → cochez : `GitHub hook trigger for GITScm polling`
3. Sauvegardez.
![image](https://hackmd.io/_uploads/H1SwpLbMMx.png)

### Tester ngrok
![image](https://hackmd.io/_uploads/HyDaWv-zfx.png)
![image](https://hackmd.io/_uploads/rJ_xzDWffx.png)

### 4.4 Tester le déclenchement automatique

```bash
# Créer une branche feature et faire une modification
git checkout -b feat/test-webhook
echo '# test webhook' >> README.md
git add README.md
git commit -m "test: verify webhook triggers Jenkins pipeline"
git push origin feat/test-webhook

# Observer dans Jenkins : un nouveau build démarre automatiquement
# (dans les secondes qui suivent le push si ngrok est actif)

# Après vérification, nettoyer la branche
git checkout main
git branch -d feat/test-webhook
git push origin --delete feat/test-webhook
```

> **Explication du test de webhook :**
> - `git checkout -b feat/test-webhook` : crée et bascule vers une nouvelle branche de test.
> - `echo '# test webhook' >> README.md` : ajoute une ligne au README- modification minime pour provoquer un push.
> - `git push origin feat/test-webhook` : pousse la branche vers GitHub. GitHub envoie immédiatement une requête POST à l'URL ngrok configurée comme webhook. Jenkins reçoit cette notification et déclenche un nouveau build.
> - Après vérification dans Jenkins (le build doit démarrer en quelques secondes), on nettoie : `git checkout main`, `git branch -d feat/test-webhook`, `git push origin --delete feat/test-webhook`.

![image](https://hackmd.io/_uploads/rJwdMwZMzl.png)

---

### Questions - Partie 4

**Question 4.1**
Le pipeline s'est-il déclenché automatiquement après le push ? Faites un screenshot du build automatique. Quelle est la différence entre Poll SCM et un webhook en termes de délai et de charge serveur ?

![image](https://hackmd.io/_uploads/SJF2XD-zze.png)
Oui le pipeline s'est déclenché automatiquement.
![image](https://hackmd.io/_uploads/By8gEvZGze.png)
![image](https://hackmd.io/_uploads/Bks-NvZMfg.png)

**Poll SCM** : 
Jenkins interroge GitHub à intervalle fixe (ici H/5 * * * *, soit toutes les 5 minutes) pour vérifier si de nouveaux commits sont apparus. C'est Jenkins qui prend l'initiative de demander.

**Webhook** :
GitHub notifie Jenkins instantanément à chaque git push. C'est GitHub qui prend l'initiative d'envoyer une requête HTTP vers Jenkins.

#### Comparaison directe

| Critère | Poll SCM | Webhook |
|----------|----------|----------|
| **Délai de déclenchement** | Jusqu'à 5 min (selon l'intervalle configuré) | Quelques secondes |
| **Qui initie la communication** | Jenkins interroge GitHub | GitHub notifie Jenkins |
| **Charge réseau** | Requêtes constantes même sans commit | Requête uniquement en cas de push |
| **Charge sur Jenkins** | Réveil périodique inutile s'il n'y a pas de commit | Sollicité uniquement lorsque nécessaire |
| **Configuration requise** | Aucune - Jenkins accessible uniquement en local | Jenkins doit être accessible depuis Internet (ngrok, IP publique) |
| **Fiabilité** | Fonctionne même derrière un pare-feu | Dépend de la disponibilité du tunnel ou de l'IP publique |

Console Output :

```
Started by GitHub push by dspitech
Obtained Jenkinsfile from git https://github.com/dspitech/sentiment-ai.git
[Pipeline] Start of Pipeline
[Pipeline] node
Running on Jenkins
 
[Pipeline] End of Pipeline
Finished: SUCCESS

```


---

## Partie 5 - Questions de synthèse

### A - Architecture Jenkins

**A1 - Rôle des 4 stages**

| Stage | Rôle |
|---|---|
| **Checkout** | Clone le code source depuis GitHub vers l'agent Jenkins pour que les stages suivants puissent travailler dessus. |
| **Lint** | Analyse statique du code Python avec `flake8` pour détecter les erreurs de syntaxe et de style avant de builder. |
| **Build & Test** | Construit l'image Docker taguée avec le SHA Git et exécute les tests pytest avec vérification de la couverture de code. |
| **Push** | Pousse l'image validée vers le registry `ghcr.io` uniquement si on est sur la branche `main`. |


**A2 - Qu'est-ce qu'un agent Jenkins ?**

Un **agent** est le nœud (machine ou environnement) sur lequel Jenkins exécute les étapes du pipeline.

| Déclaration | Comportement | Cas d'usage |
|---|---|---|
| `agent any` | S'exécute sur n'importe quel nœud Jenkins disponible, dans l'environnement tel quel de la machine | Pipeline simple, outils déjà installés sur l'agent |
| `agent { docker { image 'python:3.11' } }` | Lance un conteneur Docker éphémère avec l'image spécifiée, le pipeline s'exécute dedans, le conteneur est détruit après | Isolation totale des dépendances, reproductibilité garantie |

Le second est préférable quand on veut s'assurer que le pipeline s'exécute dans un environnement **identique à chaque build**, indépendamment de ce qui est installé sur l'agent Jenkins.



**A3 - Pourquoi `withCredentials` plutôt qu'écrire le token en clair ?**

Un token écrit directement dans le Jenkinsfile est **stocké dans Git** et devient visible par toute personne ayant accès au repo - y compris dans l'historique des commits, même si on le supprime plus tard.

`withCredentials` résout ce problème de trois façons :

- Les secrets sont stockés dans le **coffre-fort chiffré de Jenkins**, pas dans le code
- Ils sont injectés comme variables d'environnement **uniquement au moment de l'exécution**
- Ils sont **masqués dans les logs** Jenkins (remplacés par `****`)

Le Jenkinsfile peut donc être commité publiquement sans aucun risque.

---

### B - CI/CD et Qualité

**B1 - Le concept Fail Fast**

Le **Fail Fast** consiste à placer les vérifications les moins coûteuses en premier dans le pipeline, pour échouer le plus tôt possible si le code est invalide - sans perdre de temps à builder ou tester du code mal écrit.

Si le code est mal écrit, c'est le **stage Lint** qui doit échouer en premier, car il s'exécute sur le code brut sans même construire l'image Docker.

---

**B2 - Pourquoi ne pas pousser une image pour chaque branche feature ?**

Plusieurs raisons :

- **Pollution du registry** : des dizaines de branches feature génèrent des dizaines d'images non validées qui s'accumulent dans `ghcr.io`, rendant le registry ingérable.
- **Fausse impression de stabilité** : une image taguée dans le registry peut laisser croire qu'elle est prête à être déployée, alors qu'elle vient d'une branche non relue et non mergée.
- **Coût de stockage** : chaque image pèse plusieurs centaines de Mo. Pousser pour chaque branche multiplie inutilement les coûts.

Seul `main` représente le code **validé, reviewé et mergé** - c'est le seul état qui mérite d'être publié dans le registry.

---

**B3 - Workflow complet en 5 étapes**

```
1. git push origin main
        │
        ▼
2. GitHub notifie Jenkins via webhook
        │
        ▼
3. Jenkins exécute le pipeline : Lint → Build → Tests
        │
        ▼
4. Si tous les stages sont verts, docker push vers ghcr.io
        │
        ▼
5. Image disponible dans le registry : ghcr.io/pseudo/sentiment-ai:a3f8c12
```

> **Explication du workflow :** Ce flux représente le chemin complet d'un push de code jusqu'à une image publiée. Étape 1 : le développeur pousse son code. Étape 2 : GitHub déclenche Jenkins via webhook (instantané) ou Poll SCM (délai jusqu'à 5 min). Étape 3 : Jenkins exécute chaque stage en séquence- si l'un échoue, le pipeline s'arrête et l'image n'est pas poussée. Étape 4 : le push ne s'effectue que si tous les stages sont verts ET qu'on est sur `main`. Étape 5 : l'image est disponible dans le registry, prête à être déployée en production.

### C - Traçabilité et Versionnement

**C1 - Retrouver le code source d'une image déployée**

`a3f8c12` est le SHA court du commit Git qui a produit cette image. Pour retrouver le code exact :

```bash
# Dans le repo Git local
git checkout a3f8c12
# Ou consulter directement sur GitHub
```

> **Explication :** `git checkout a3f8c12` place le dépôt local dans l'état exact correspondant au commit `a3f8c12`. Tous les fichiers du projet seront exactement tels qu'ils étaient lors du build de cette image. C'est la valeur fondamentale du tagging par SHA : une correspondance **bijective** entre image Docker et état du code source, sans ambiguïté possible.

C'est précisément l'intérêt de taguer avec le SHA plutôt qu'un numéro de version arbitraire : le tag **est** un pointeur direct vers le commit, sans ambiguïté possible.

---

**C2 - Pourquoi deux tags `:SHA` et `:latest` ?**

Les deux tags servent des usages différents et complémentaires :

| Tag | Rôle | Utilisé par |
|---|---|---|
| `:a3f8c12` (SHA) | Tag **immuable** - pointe toujours vers exactement ce build, ne changera jamais | Production, rollback, audit, debugging |
| `:latest` | Tag **mobile** - pointe toujours vers le dernier build de `main` | Développement local, CI des projets dépendants |

En pratique :
- On **déploie en production** avec le tag SHA - on sait exactement ce qu'on déploie et on peut rollback vers un SHA précis.
- On utilise `:latest` pour récupérer rapidement la dernière version stable sans connaître le SHA, mais on ne s'en sert jamais pour un déploiement en production car sa cible change à chaque build.


---
# Déploiement automatisé + Pipeline Jenkins


## Description 

Ce TP met en place un déploiement automatisé de bout en bout de l’infrastructure DevOps.

Ce déploiement constitue un bonus  en automatisant les travaux pratiques **TP1** et **TP2**.

![image](https://hackmd.io/_uploads/Byj12TZzGe.png)


## Objectifs
- Installation de Docker CE et Docker Compose
- Installation de Git, Make et GitHub CLI
- Clonage du projet `sentiment-ai` 
- Configuration des permissions et montage du disque `/data` 
- Installation et démarrage de Jenkins (DooD)
- Configuration de Docker dans Jenkins 
- Installation et configuration de ngrok avec token
- Configuration de l’URL Jenkins via ngrok
- Création automatique du fichier `INFO.txt` contenant toutes les informations de connexion 

## Moins de configuration manuelle

Grâce à cette automatisation, le temps de mise en place passe de plusieurs heures de configuration manuelle à seulement quelques minutes de configuration post-déploiement.

---

## Architecture déployée

| Ressource | Valeur |
|---|---|
| Resource Group | `OpenLab-Sweden-RG` |
| Région | `swedencentral` |
| VM | `OpenLab-VM-Student` - Ubuntu 22.04 LTS |
| Taille | `Standard_B2s_v2` (2 vCPU / 4 Go RAM) |
| Utilisateur | `labadmin` |
| Authentification | Clé SSH générée automatiquement par Terraform |
| IP publique | Standard SKU, statique |
| Disque de données | Premium_LRS 64 Go → monté sur `/data` |
| State Terraform | Azure Blob Storage |

### Ports ouverts (NSG)

| Port | Service |
|---|---|
| 22 | SSH |
| 8080 | Jenkins |
| 8081 | Jenkins (alternatif) |
| 8000 | FastAPI / Uvicorn |
| 50000 | Jenkins Agent JNLP |
| 9000 | SonarQube (TP3) |
| 9090 | Prometheus (TP5) |
| 3000 | Grafana (TP5) |
| 443 | HTTPS |
| 3389 | RDP |
| 5900 | VNC |
| 8006 | Proxmox |
| 8989 | Application custom |

### Ce qui est automatisé vs manuel

| Action | Automatisé | Manuel |
|---|---|---|
| Génération clé SSH |  Terraform `tls` provider |  |
| State distant Azure |  Backend Storage Account |  |
| Installation Docker CE + Compose |  cloud-init |  |
| Installation Git, Make, curl |  cloud-init |  |
| Installation GitHub CLI |  cloud-init |  |
| Installation Terraform |  cloud-init |  |
| Installation ngrok + token |  cloud-init |  |
| Démarrage Jenkins (DooD) |  cloud-init |  |
| Docker dans Jenkins + permissions |  cloud-init |  |
| Configuration URL Jenkins → ngrok |  cloud-init |  |
| Clonage projet `sentiment-ai` |  cloud-init |  |
| Fichier `INFO.txt` avec accès |  cloud-init |  |
| Mot de passe Jenkins initial |  |  À récupérer |
| Plugins Jenkins |  |  À installer |
| Credentials GitHub dans Jenkins |  |  À configurer |
| Job Jenkins `sentiment-ai-pipeline` |  |  À créer |
| Webhook GitHub |  |  À configurer |

---

## Fichiers du projet

```
.
├── main.tf              # Infrastructure complète (VM, réseau, NSG, disque, clé SSH)
├── backend.tf           # State distant Azure Blob Storage
├── cloud-init.yaml      # Provisionnement automatique de la VM
└── scripts/
    └── setup-backend.sh # Création du Storage Account backend
```

---

## Partie 1 - Déploiement de la VM (Azure Cloud Shell)

> Toutes les commandes suivantes s'exécutent dans **Azure Cloud Shell (PowerShell)**.

### Étape 1 - Cloner la configuration Terraform

```powershell
git clone https://github.com/dspitech/DevOps-VM-Ubuntu-Terraform-Azure.git
cd DevOps-VM-Ubuntu-Terraform-Azure
```

![image](https://hackmd.io/_uploads/SkxcmtzzGl.png)


- Lancer Visual Studio Code depuis Cloud Shell
```
code .
```

- Modifier la configuration du fichier `cloud-init.yaml`

```yaml
#cloud-config
# ============================================================
# Cloud-init - Provisionnement automatique au premier démarrage
# Installe : Docker CE + Docker Compose + Git + Make + GitHub CLI + ngrok + Terraform
# Tous les services sont configurés avec les bonnes permissions
# Installation Docker CE + Compose	
# Installation Git, Make, curl	
# Installation GitHub CLI	
# Installation Terraform	
# Installation ngrok v3	
# Configuration token ngrok	
# Démarrage ngrok avec bonnes permissions	
# Récupération URL ngrok	
# Création volume Jenkins	
# Lancement Jenkins (DooD)	
# Installation Docker dans Jenkins	
# Configuration Jenkins avec URL ngrok	
# Récupération mot de passe Jenkins	
# Clonage du projet sentiment-ai	
# Création fichier INFO.txt complet	
# Message MOTD personnalisé	
# Logs dans /var/log/openlab-init.log
# ============================================================

package_update: true
package_upgrade: true

packages:
  - git
  - make
  - curl
  - ca-certificates
  - gnupg
  - lsb-release
  - apt-transport-https
  - unzip
  - jq
  - python3
  - python3-pip

runcmd:
  # ----------------------------------------------------------
  # Installation de Docker CE 
  # ----------------------------------------------------------
  - install -m 0755 -d /etc/apt/keyrings
  - curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  - chmod a+r /etc/apt/keyrings/docker.asc
  - |
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
      https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null
  - apt-get update -y
  - apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # ----------------------------------------------------------
  # Installation de Terraform
  # ----------------------------------------------------------
  - |
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    apt-get update -y
    apt-get install -y terraform

  # ----------------------------------------------------------
  # Installation de GitHub CLI
  # ----------------------------------------------------------
  - curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  - chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  - |
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
    https://cli.github.com/packages stable main" | \
    tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  - apt-get update -y
  - apt-get install -y gh

  # ----------------------------------------------------------
  # Installation de ngrok 
  # ----------------------------------------------------------
  - curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
  - echo "deb https://ngrok-agent.s3.amazonaws.com bookworm main" | sudo tee /etc/apt/sources.list.d/ngrok.list
  - apt-get update -y
  - apt-get install -y ngrok

  # ----------------------------------------------------------
  # Ajouter l'utilisateur admin au groupe docker 
  # ----------------------------------------------------------
  - usermod -aG docker labadmin

  # ----------------------------------------------------------
  # Activer et démarrer Docker au boot
  # ----------------------------------------------------------
  - systemctl enable docker
  - systemctl start docker

  # ----------------------------------------------------------
  # Formater et monter le disque de données (/dev/sdc → /data)
  # ----------------------------------------------------------
  - |
    DISK="/dev/sdc"
    MOUNT="/data"
    if [ -b "$DISK" ] && ! blkid "$DISK" | grep -q TYPE; then
      mkfs.ext4 -F "$DISK"
    fi
    mkdir -p "$MOUNT"
    if ! grep -q "$DISK" /etc/fstab; then
      UUID=$(blkid -s UUID -o value "$DISK")
      echo "UUID=$UUID $MOUNT ext4 defaults,nofail 0 2" >> /etc/fstab
    fi
    mount -a

  # ----------------------------------------------------------
  # Cloner le projet SentimentAI 
  # ----------------------------------------------------------
  - |
    cd /home/labadmin
    git clone https://github.com/dev/sentiment-ai.git 2>/dev/null || echo "Repo déjà existant"
    chown -R labadmin:labadmin /home/labadmin/sentiment-ai
    chmod -R 755 /home/labadmin/sentiment-ai

  # ----------------------------------------------------------
  # CRÉATION DES DOSSIERS NGROK 
  # ----------------------------------------------------------
  - |
    # Supprimer l'ancienne config si elle existe
    rm -rf /home/labadmin/.config/ngrok
    mkdir -p /home/labadmin/.config/ngrok
    chown -R labadmin:labadmin /home/labadmin/.config
    chmod 755 /home/labadmin/.config/ngrok

  # ----------------------------------------------------------
  # CONFIGURATION DU TOKEN NGROK EN TANT QUE LABADMIN
  # REMPLACEZ "METTRE_VOTRE_TOKEN_NGROK_ICI" PAR VOTRE TOKEN
  # Pour obtenir votre token : https://dashboard.ngrok.com/get-started/your-authtoken
  # ----------------------------------------------------------
  - |
    su - labadmin -c "ngrok config add-authtoken METTRE_VOTRE_TOKEN_NGROK_ICI"
    chown labadmin:labadmin /home/labadmin/.config/ngrok/ngrok.yml
    chmod 644 /home/labadmin/.config/ngrok/ngrok.yml

  # ----------------------------------------------------------
  # CRÉER LE SCRIPT DE DÉMARRAGE NGROK
  # ----------------------------------------------------------
  - |
    cat > /home/labadmin/start-ngrok.sh << 'SCRIPT'
    #!/bin/bash
    cd /home/labadmin
    pkill ngrok 2>/dev/null
    rm -f /home/labadmin/ngrok.log
    nohup /usr/bin/ngrok http 8080 --log=stdout --log-level=info > /home/labadmin/ngrok.log 2>&1 &
    sleep 5
    if ps aux | grep -v grep | grep ngrok > /dev/null; then
      echo " ngrok démarré - PID: $(pgrep ngrok)"
    else
      echo " Échec du démarrage de ngrok"
      cat /home/labadmin/ngrok.log
    fi
    SCRIPT
    chmod +x /home/labadmin/start-ngrok.sh
    chown labadmin:labadmin /home/labadmin/start-ngrok.sh

  # ----------------------------------------------------------
  # DÉMARRER NGROK 
  # ----------------------------------------------------------
  - |
    su - labadmin -c "/home/labadmin/start-ngrok.sh"
    sleep 5

  # ----------------------------------------------------------
  # RÉCUPÉRER L'URL NGROK
  # ----------------------------------------------------------
  - |
    sleep 3
    NGROK_URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['tunnels'][0]['public_url'] if data.get('tunnels') else '')" 2>/dev/null)
    echo " URL ngrok : $NGROK_URL" >> /var/log/openlab-init.log

  # ----------------------------------------------------------
  # CRÉER LE VOLUME JENKINS
  # ----------------------------------------------------------
  - |
    docker volume create jenkins-data 2>/dev/null || true
    docker rm -f jenkins 2>/dev/null || true

  # ----------------------------------------------------------
  # LANCER JENKINS VIA DOCKER 
  # ----------------------------------------------------------
  - |
    docker run -d \
      --name jenkins \
      -p 8080:8080 \
      -p 50000:50000 \
      -v jenkins-data:/var/jenkins_home \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v /home/labadmin:/home/labadmin \
      --user root \
      --restart unless-stopped \
      jenkins/jenkins:lts

  # ----------------------------------------------------------
  # ATTENDRE QUE JENKINS SOIT PRÊT
  # ----------------------------------------------------------
  - echo " Attente du démarrage de Jenkins (60 secondes)..."
  - sleep 60

  # ----------------------------------------------------------
  # DOCKER DANS JENKINS 
  # ----------------------------------------------------------
  - |
    docker exec -u root jenkins bash -c "
      apt-get update -q 2>/dev/null || true
      apt-get install -y docker.io 2>/dev/null || true
      chmod 666 /var/run/docker.sock
      mkdir -p /var/lib/jenkins/.docker
      chown jenkins:jenkins /var/lib/jenkins/.docker
    "

  # ----------------------------------------------------------
  # RÉCUPÉRER L'URL NGROK APRÈS LE DÉMARRAGE
  # ----------------------------------------------------------
  - |
    sleep 5
    NGROK_URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['tunnels'][0]['public_url'] if data.get('tunnels') else '')" 2>/dev/null)
    echo " URL ngrok pour Jenkins : $NGROK_URL" >> /var/log/openlab-init.log

  # ----------------------------------------------------------
  # CONFIGURER JENKINS AVEC L'URL NGROK
  # ----------------------------------------------------------
  - |
    NGROK_URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['tunnels'][0]['public_url'] if data.get('tunnels') else '')" 2>/dev/null)
    
    if [ -n "$NGROK_URL" ]; then
      docker exec -u root jenkins bash -c "
        mkdir -p /var/lib/jenkins
        cat > /var/lib/jenkins/config.xml << 'EOF'
    <?xml version='1.1' encoding='UTF-8'?>
    <jenkins>
      <installStateName>NEW</installStateName>
      <numExecutors>2</numExecutors>
      <mode>NORMAL</mode>
      <useSecurity>false</useSecurity>
      <authorizationStrategy class=\"hudson.security.AuthorizationStrategy\$Unsecured\"/>
      <securityRealm class=\"hudson.security.SecurityRealm\$None\"/>
      <jenkinsUrl>$NGROK_URL</jenkinsUrl>
    </jenkins>
    EOF
    "
      docker restart jenkins
      sleep 15
      echo " Jenkins configuré avec URL: $NGROK_URL" >> /var/log/openlab-init.log
    else
      echo " ngrok non disponible - utiliser Poll SCM" >> /var/log/openlab-init.log
    fi

  # ----------------------------------------------------------
  # RÉCUPÉRER LE MOT DE PASSE JENKINS ET CRÉER INFO.txt
  # ----------------------------------------------------------
  - |
    sleep 10
    PASS=$(docker exec jenkins cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo "Non disponible")
    NGROK_URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['tunnels'][0]['public_url'] if data.get('tunnels') else '')" 2>/dev/null)
    
    cat > /home/labadmin/INFO.txt << EOF
    ============================================
    OpenLab VM - Informations de connexion
    ============================================
    
     URL Jenkins : $NGROK_URL
     Mot de passe Jenkins : $PASS
    
     Projet : /home/labadmin/sentiment-ai
    
     Outils installés :
      - Docker CE + Compose
      - Git + GitHub CLI
      - Make
      - Terraform
      - ngrok
      - Jenkins
    
     Commandes utiles :
      docker ps
      docker logs jenkins
      cat /home/labadmin/ngrok.log
      cd /home/labadmin/sentiment-ai && make test
    
     Pour configurer Jenkins :
      1. Ouvrir : $NGROK_URL
      2. Mot de passe : $PASS
      3. Installer les plugins suggérés
      4. Créer un compte admin
      5. Ajouter credentials GitHub (github-token)
    
     Pour le webhook GitHub :
      Payload URL : $NGROK_URL/github-webhook/
    ============================================
    EOF
    
    chown labadmin:labadmin /home/labadmin/INFO.txt

  # ----------------------------------------------------------
  # VÉRIFICATION FINALE
  # ----------------------------------------------------------
  - |
    echo "=== Cloud-init provisioning done ===" >> /var/log/openlab-init.log
    echo "Docker:      $(docker --version)" >> /var/log/openlab-init.log
    echo "Compose:     $(docker compose version)" >> /var/log/openlab-init.log
    echo "Git:         $(git --version)" >> /var/log/openlab-init.log
    echo "Make:        $(make --version | head -1)" >> /var/log/openlab-init.log
    echo "GitHub CLI:  $(gh --version | head -1)" >> /var/log/openlab-init.log
    echo "Terraform:   $(terraform --version | head -1)" >> /var/log/openlab-init.log
    echo "ngrok:       $(ngrok --version)" >> /var/log/openlab-init.log
    NGROK_URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['tunnels'][0]['public_url'] if data.get('tunnels') else '')" 2>/dev/null)
    echo " ngrok URL: $NGROK_URL" >> /var/log/openlab-init.log
    PASS=$(docker exec jenkins cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo "Non disponible")
    echo " Jenkins Password: $PASS" >> /var/log/openlab-init.log
    echo " Infos complètes : cat /home/labadmin/INFO.txt" >> /var/log/openlab-init.log
    echo "Date:        $(date)" >> /var/log/openlab-init.log

  # ----------------------------------------------------------
  # MESSAGE MOTD POUR CONNEXION SSH
  # ----------------------------------------------------------
  - |
    cat > /etc/motd << 'EOF'
    ============================================
     OpenLab VM - Prête pour le développement
    
     Outils installés :
      - Docker CE + Compose
      - Git + GitHub CLI
      - Make
      - Terraform
      - ngrok
      - Jenkins (Docker)
    
     Toutes les infos :
      cat /home/labadmin/INFO.txt
    
     Commandes utiles :
      docker ps
      docker logs jenkins
      docker logs -f jenkins   (logs en temps réel)
      
      cd /home/labadmin/sentiment-ai
      make test
      
      cat /home/labadmin/ngrok.log
      curl http://localhost:4040/api/tunnels | jq
    ============================================
    EOF

final_message: "OpenLab VM prête. Docker, Git, Make, GitHub CLI, Terraform, ngrok et Jenkins installés. Consultez /home/labadmin/INFO.txt pour les accès. Durée : $UPTIME secondes."
```

- Ligne à modifier : su - labadmin -c "ngrok config add-authtoken METTRE_VOTRE_TOKEN_NGROK_ICI"
- git clone https://github.com/dev/sentiment-ai.git : mettez votre vrai URL du projet dans Github.

![image](https://hackmd.io/_uploads/SkP6Qtzzzg.png)


### Étape 2 - Créer le backend Terraform (Storage Account)

Le state Terraform est stocké dans Azure pour persister entre les sessions Cloud Shell.

```powershell
chmod +x ./setup-backend.sh
./setup-backend.sh
```
![image](https://hackmd.io/_uploads/ryQl4KMfGe.png)

Le script affiche le nom du Storage Account généré (ex. `openlabtfstate42871`). Il met à jour `backend.tf` automatiquement.

Si le Storage Account existe déjà, vérifiez son nom et mettez à jour `backend.tf` :

```powershell
az storage account list --resource-group OpenLab-TFState-RG --query "[].name" -o tsv
```
![image](https://hackmd.io/_uploads/Sy0XEYfGze.png)

Pour déployer **sans backend distant**, supprimez simplement `backend.tf` avant de lancer `terraform init`. Le state sera créé localement dans `terraform.tfstate`.

### Étape 3 - Déployer l'infrastructure

```powershell
terraform init && terraform fmt && terraform validate && terraform plan && terraform apply -auto-approve
```
![image](https://hackmd.io/_uploads/BJaHVYMGfg.png)
![image](https://hackmd.io/_uploads/rJUhEKMzfl.png)
![image](https://hackmd.io/_uploads/HJQ0VKGfzl.png)


Terraform crée automatiquement :
- Une paire de clés RSA 4096 bits (provider `tls`)
- 10 ressources Azure (RG, VNet, Subnet, NSG, IP, NIC, Managed Disk, VM, attachements)
- La VM injecte `cloud-init.yaml` → Docker, Jenkins, ngrok, GitHub CLI, Terraform s'installent au premier démarrage (~5 min)

### Étape 4 - Télécharger la clé SSH

```powershell
download ./openlab_rsa
```
![image](https://hackmd.io/_uploads/BkZxStfzMx.png)


### Étape 5 - Se connecter à la VM

```powershell
# Depuis Windows PowerShell
ssh -i "C:\Users\dev\Downloads\openlab_rsa" labadmin@<PUBLIC_IP>
```

Récupérez l'IP publique à tout moment :

```powershell
terraform output public_ip_address
```
![image](https://hackmd.io/_uploads/S18XrYzfGl.png)

---

## Partie 2 - Configuration manuelle après déploiement

Se connecter en SSH à la VM avant de commencer ces étapes.  
Attendre **5 à 8 minutes** après la première connexion SSH pour que cloud-init termine.

### Vérifier l'état du provisionnement

```bash
# Suivre l'avancement cloud-init en temps réel
sudo tail -f /var/log/cloud-init-output.log

# Consulter le log de fin de provisionnement
cat /var/log/openlab-init.log

# Lire le fichier d'informations généré automatiquement
cat /home/labadmin/INFO.txt
```
![image](https://hackmd.io/_uploads/r1h4HKzzfl.png)
![image](https://hackmd.io/_uploads/S1MoHYfzMe.png)
![image](https://hackmd.io/_uploads/S1P3BYMMfe.png)


`INFO.txt` contient l'URL Jenkins (ngrok), le mot de passe initial et toutes les commandes utiles.

### Vérifier que Jenkins tourne

```bash
docker ps
# Doit afficher le conteneur "jenkins" en statut "Up"

docker logs jenkins --tail 20
# Vérifier la ligne : "Jenkins is fully up and running"
```
![image](https://hackmd.io/_uploads/BJQyLYfGMl.png)

---

### Étape 1 - Récupérer le mot de passe Jenkins

```bash
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```
![image](https://hackmd.io/_uploads/BylZIFMzze.png)


Ouvrez Jenkins dans votre navigateur : 

Collez le mot de passe récupéré, puis choisissez **Install suggested plugins**.
![image](https://hackmd.io/_uploads/rJcVIFMffl.png)
![image](https://hackmd.io/_uploads/Sy_L8YfGzg.png)
![image](https://hackmd.io/_uploads/rJVwIKGzfx.png)
![image](https://hackmd.io/_uploads/ByKRIFffzx.png)
![image](https://hackmd.io/_uploads/BJaJDYGMGg.png)
![image](https://hackmd.io/_uploads/r1c7PKMfzx.png)


---

### Étape 2 - Installer les plugins Jenkins

Dans Jenkins : **Administrer Jenkins → Plugins → Available plugins**

Rechercher et installer :

- `Docker Pipeline`
- `Docker Pipeline`
- `Pipeline`
- `Blue Ocean` (optionnel)

Redémarrer Jenkins si demandé.
![image](https://hackmd.io/_uploads/ryDSDYGzzg.png)
![image](https://hackmd.io/_uploads/HJeRwFMfzg.png)

---

### Étape 3 - Configurer les credentials GitHub

**Créer un token GitHub** (si pas déjà fait) :

GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic) → Generate new token

Permissions requises : `repo`, `read:packages`, `write:packages`

**Enregistrer le token dans Jenkins** :

Jenkins → **Administrer Jenkins → Credentials → System → Global credentials → Add Credentials**

| Champ | Valeur |
|---|---|
| Kind | Username with password |
| Username | `votre pseudo github` (votre pseudo GitHub) |
| Password | Votre token GitHub |
| ID | `github-token` |
| Description | `GitHub token for sentiment-ai` |

Cliquer **Create**.
![image](https://hackmd.io/_uploads/Sy9V5FGzGe.png)
![image](https://hackmd.io/_uploads/SyurcKMfGg.png)
![image](https://hackmd.io/_uploads/SkcI5Yzzzx.png)
![image](https://hackmd.io/_uploads/HkkocKffGg.png)
![image](https://hackmd.io/_uploads/S1f3qFGMzx.png)



---

### Étape 4 - Créer le job Jenkins

Jenkins → **Nouveau Item** → Nom : `sentiment-ai-pipeline` → **Pipeline** → OK

Configurer :

| Section | Champ | Valeur |
|---|---|---|
| General | GitHub project | `https://github.com/dspitech/sentiment-ai` |
| Build Triggers | - | `GitHub hook trigger for GITScm polling` |
| Pipeline | Definition | `Pipeline script from SCM` |
| Pipeline | SCM | `Git` |
| Pipeline | Repository URL | `https://github.com/dspitech/sentiment-ai.git` |
| Pipeline | Credentials | `github-token` |
| Pipeline | Branch | `*/main` |
| Pipeline | Script Path | `Jenkinsfile` |

Cliquer **Save**.
![image](https://hackmd.io/_uploads/HkPpqtMGzx.png)
![image](https://hackmd.io/_uploads/B1ZkoYGfMe.png)
![image](https://hackmd.io/_uploads/H1pGjKfMGx.png)
![image](https://hackmd.io/_uploads/SyuVjKfGMe.png)
![image](https://hackmd.io/_uploads/rJ2UiFzGfl.png)
![image](https://hackmd.io/_uploads/SymOjFMzGx.png)
![image](https://hackmd.io/_uploads/SJXtjtfGGx.png)



---

### Étape 5 - Vérifier et relancer ngrok si nécessaire

Si l'URL ngrok n'est plus disponible ou a changé :

```bash
# Arrêter les anciennes instances
pkill ngrok 2>/dev/null

# Relancer ngrok
nohup ngrok http 8080 --log=stdout --log-level=info > ~/ngrok.log 2>&1 &

# Attendre le démarrage
sleep 5

# Récupérer la nouvelle URL
NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | python3 -c \
  "import sys, json; data=json.load(sys.stdin); \
   print(data['tunnels'][0]['public_url'] if data.get('tunnels') else 'Non disponible')")
echo "URL Jenkins : $NGROK_URL"
```
![image](https://hackmd.io/_uploads/BJXy3FMMGx.png)

Si ngrok n'est pas disponible, configurez **Poll SCM** dans le job Jenkins à la place du webhook : Schedule `H/5 * * * *` (déclenchement toutes les 5 minutes).

---

### Étape 6 - Configurer le webhook GitHub

1. Ouvrir : `https://github.com/dspitech/sentiment-ai/settings/hooks`
2. Cliquer **Add webhook**

| Champ | Valeur |
|---|---|
| Payload URL | `https://VOTRE_URL_NGROK/github-webhook/` |
| Content type | `application/json` |
| Which events | Just the push event |
| Active |  coché |

Cliquer **Add webhook**.
![image](https://hackmd.io/_uploads/r1PfnYfGze.png)
![image](https://hackmd.io/_uploads/H1rQhFMMGl.png)

---

## Partie 3 - Tester le pipeline

### Lancer le premier build manuellement

Dans Jenkins, cliquer sur le job `sentiment-ai-pipeline` → **Build Now**.

Surveiller le build : cliquer sur le numéro → **Console Output**.

Le pipeline doit passer par les stages : **Checkout → Lint → Build Docker → Test → Push to GHCR**

### Déclencher automatiquement via git push

```bash
cd /home/labadmin/sentiment-ai

# Configurer l'identité Git (si pas encore fait)
gh auth login
git config --global user.name "votre prénom et nom"
git config --global user.email "votre email"

# Vérification
git config --global --list

# Modifier un fichier pour déclencher le pipeline
echo "# Test déclenchement pipeline Jenkins" >> README.md

git add README.md
git commit -m "test: déclenchement pipeline Jenkins"
git push origin main
```

Jenkins démarre un nouveau build automatiquement dans les secondes qui suivent le push (via webhook) ou dans les 5 minutes suivantes (via Poll SCM).
![image](https://hackmd.io/_uploads/S1NTatMMMe.png)

---

## Commandes utiles

```bash
# État général
docker ps                          # Conteneurs en cours d'exécution
cat /home/labadmin/INFO.txt        # Infos de connexion (URL Jenkins, mot de passe)
cat /var/log/openlab-init.log      # Log de provisionnement cloud-init

# Jenkins
docker logs jenkins                # Logs Jenkins
docker logs -f jenkins             # Logs Jenkins en temps réel
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

# ngrok
cat ~/ngrok.log                    # Logs ngrok
curl -s http://localhost:4040/api/tunnels | jq  # URL publique ngrok

# Projet SentimentAI
cd /home/labadmin/sentiment-ai
make test                          # Lancer les tests
make build                         # Builder l'image Docker
docker compose up -d               # Démarrer la stack

# Disque de données
df -h /data                        # Vérifier le montage

# Versions installées
docker --version
docker compose version
git --version
gh --version
terraform --version
ngrok --version
```

---

## Détruire l'infrastructure

```bash
terraform destroy -auto-approve
```

Le Resource Group du backend (`OpenLab-TFState-RG`) et le Storage Account ne sont **pas** supprimés par `terraform destroy`. Pour les supprimer manuellement :
>
> ```powershell
> az group delete --name OpenLab-TFState-RG --yes --no-wait
> ```

---

## Dépannage

| Symptôme | Cause probable | Solution |
|---|---|---|
| `docker ps` ne montre pas Jenkins | cloud-init encore en cours | Attendre 5–8 min, vérifier `sudo tail -f /var/log/cloud-init-output.log` |
| `Permission denied` sur docker.sock | Permissions socket manquantes | `docker exec -u root jenkins chmod 666 /var/run/docker.sock` |
| URL ngrok absente dans `INFO.txt` | ngrok pas encore démarré | Relancer manuellement avec `~/start-ngrok.sh` |
| Jenkins inaccessible via ngrok | ngrok arrêté ou URL changée | `pkill ngrok && nohup ngrok http 8080 > ~/ngrok.log 2>&1 &` |
| Stage Lint échoue | Erreurs flake8 dans le code Python | `pip install autopep8 && autopep8 --in-place src/*.py` |
| Push GHCR échoue | Token GitHub expiré ou permissions insuffisantes | Régénérer un token avec `repo`, `read:packages`, `write:packages` |
| Backend Terraform 404 | Nom Storage Account incorrect dans `backend.tf` | `az storage account list --resource-group OpenLab-TFState-RG --query "[].name" -o tsv` |
| Timeout SSH après `terraform apply` | VM pas encore démarrée | Attendre 2 minutes avant de se connecter |
---

## Prérequis pour le TP3

Le TP3 ajoutera **SonarQube** et **Trivy** au pipeline Jenkins pour l'analyse de qualité du code et le scan de sécurité des images Docker. Avant de passer au TP3, vérifiez que :

- Votre `Jenkinsfile` est commité sur `main` et le pipeline passe en **vert**
-  L'image Docker est visible dans GitHub Packages (`ghcr.io`)
-  Le fichier `coverage.xml` est bien généré dans le workspace Jenkins

---

# TP 3 - Qualité & Sécurité : SonarQube + Trivy

Objectif : intégrer l'analyse de code statique (SonarQube) et le scan de vulnérabilités (Trivy) dans le pipeline CI/CD de SentimentAI.

---

## Vue d'ensemble

```
TP 1              TP 2                  TP 3                TP 4         TP 5
Git + Docker   Jenkins pipeline     SonarQube + Trivy   Terraform    Monitoring
+ Compose      build + test + push  Qualité & Sécurité  IaC Docker   Prometheus
SentimentAI v0.1                                                      + Grafana
```

Le pipeline du TP2 buildait et testait SentimentAI automatiquement. Ce TP ajoute deux outils complémentaires :

| Outil | Rôle | Ce qu'il inspecte |
|---|---|---|
| **SonarQube** | Analyse statique du code source | Bugs, vulnérabilités, code smells, couverture, duplication |
| **Trivy** | Scan de vulnérabilités CVE | Paquets OS + dépendances Python de l'image Docker |

> Si l'un ou l'autre détecte un problème au-delà du seuil configuré, le pipeline s'arrête et l'image n'est **jamais poussée** vers le registry.

---

## Prérequis

- Docker installé et en cours d'exécution
- Jenkins opérationnel (depuis le TP2) sur le réseau `cicd-network`
- Pipeline TP2 fonctionnel (build + test + push vers GHCR)
- Accès à `http://localhost:8080` (Jenkins) et `http://localhost:9000` (SonarQube)

---

## Concepts clés

### SonarQube - 5 dimensions analysées

| Dimension | Définition |
|---|---|
| **Bugs** | Erreurs certaines dans le code - comportement anormal garanti à l'exécution |
| **Vulnérabilités** | Failles de sécurité exploitables (injections, secrets en dur, etc.) |
| **Code Smells** | Code qui fonctionne mais difficile à maintenir, lire ou faire évoluer |
| **Couverture** | Pourcentage de lignes de code exécutées par les tests automatisés |
| **Duplication** | Blocs de code identiques ou très similaires répétés à plusieurs endroits |

### Quality Gate

Un **Quality Gate** est un ensemble de seuils configurés dans SonarQube. Si l'un est dépassé, l'analyse est marquée comme **échec** et Jenkins arrête le pipeline avant le push. C'est la porte de qualité qui garantit que seul du code sain part en production.

### CVE - Common Vulnerabilities and Exposures

Une **CVE** est un identifiant unique (ex : `CVE-2023-1234`) attribué à une faille de sécurité connue dans un logiciel. Trivy compare les paquets de votre image Docker contre une base de données de CVE pour détecter celles qui sont présentes.

### Dette technique

La **dette technique** représente le coût futur engendré par des choix de développement rapides mais sous-optimaux. Les Code Smells SonarQube sont une mesure directe de cette dette : chaque smell non corrigé alourdit la maintenance et ralentit les futures évolutions.

---

## 1 - Installer et configurer SonarQube

### 1.1 Lancer SonarQube via Docker

SonarQube utilise Elasticsearch en interne, qui nécessite une limite mémoire système spécifique.

```bash
# Linux uniquement - ajuster la limite mémoire système
sudo sysctl -w vm.max_map_count=262144
```
![image](https://hackmd.io/_uploads/Hk-tAFffMg.png)

- Vérifier quel réseau utilise Jenkins

```
docker inspect jenkins --format '{{json .NetworkSettings.Networks}}'
```
![image](https://hackmd.io/_uploads/S1qo15zzGe.png)

Résultat : Jenkins = réseau bridge

On remarque le réseau : `cicd-network` n'existe pas.

- Création du réseau : `cicd-network`

```
docker network create cicd-network
docker network connect cicd-network jenkins
```
![image](https://hackmd.io/_uploads/SJinl9MGzg.png)


- On relance le conteneur SonarQube : 

```bash
# Lancer SonarQube (Linux)
docker run -d \
  --name sonarqube \
  --network cicd-network \
  -p 9000:9000 \
  sonarqube:lts-community
```
![image](https://hackmd.io/_uploads/H1MgycfzMg.png)
![image](https://hackmd.io/_uploads/Hk7M-qzzMl.png)


```bash
# Attendre que SonarQube soit prêt (~60 secondes)
docker logs -f sonarqube | grep 'SonarQube is operational'
```
![image](https://hackmd.io/_uploads/BkzLbqGMGg.png)


**Pourquoi `--network cicd-network` ?**  
Jenkins envoie les résultats d'analyse à SonarQube via l'URL `http://sonarqube:9000` - le nom DNS interne Docker du conteneur. Ce nom n'est résolu que si les deux conteneurs partagent le même réseau Docker. Sans réseau commun, Jenkins ne peut pas contacter SonarQube et l'analyse échoue.

On vérifie si les deux sont dans le même réseau : 
```bash
# Jenkins
docker inspect jenkins --format '{{json .NetworkSettings.Networks}}'

# SonarQube
docker inspect sonarqube --format '{{json .NetworkSettings.Networks}}'
```
![image](https://hackmd.io/_uploads/B1UUfqzGzl.png)


### 1.2 Première connexion et configuration

1. Ouvrez `http://localhost:9000`
2. Login par défaut : `admin` / `admin` → modifiez le mot de passe
3. Créez un projet manuellement :
   - **Project display name** : `SentimentAI`
   - **Project key** : `sentiment-ai` *(noter cette valeur, elle apparaîtra dans le Jenkinsfile)*
   - **Main branch** : `main`
4. Méthode d'analyse : **With Jenkins**
5. Générez un token d'analyse :
   - `My Account` → `Security` → `Generate Token`
   - Name : `jenkins-token` | Type : `Global Analysis Token`
   - **Copiez le token immédiatement** (il n'est affiché qu'une seule fois)

![image](https://hackmd.io/_uploads/S1VFG5ffzl.png)
![image](https://hackmd.io/_uploads/S18cz5fMzg.png)
![image](https://hackmd.io/_uploads/HyP3GcMGGl.png)
![image](https://hackmd.io/_uploads/BkFafczMMg.png)
![image](https://hackmd.io/_uploads/Skxym5zffl.png)
![image](https://hackmd.io/_uploads/r1zmm9zMzl.png)
![image](https://hackmd.io/_uploads/rJ2V7qzGMl.png)
![image](https://hackmd.io/_uploads/ry3L7czGGe.png)
![image](https://hackmd.io/_uploads/HycHVcMMMe.png)
![image](https://hackmd.io/_uploads/SJTPV9zMMl.png)
![image](https://hackmd.io/_uploads/r1eq4czGfx.png)


### 1.3 Configurer SonarQube dans Jenkins

**Étape 1 - Installer le plugin SonarQube Scanner**

```
Jenkins → Plugins → Available → SonarQube Scanner → Install
```
![image](https://hackmd.io/_uploads/rJvnV5Gfzg.png)
![image](https://hackmd.io/_uploads/Hyg0VqzGfx.png)
![image](https://hackmd.io/_uploads/ryllS9zMGg.png)


**Étape 2 - Enregistrer le token**

```
Jenkins → Administrer Jenkins → Credentials → System → Global credentials
→ Add Credentials → Kind : Secret text
→ Secret : <votre token SonarQube>
→ ID : sonar-token
```
![image](https://hackmd.io/_uploads/HJuWr5MMGx.png)
![image](https://hackmd.io/_uploads/rkTSrcfMfg.png)
![image](https://hackmd.io/_uploads/SJnoBqzzfl.png)
![image](https://hackmd.io/_uploads/SJQ6rcMfMg.png)


**Étape 3 - Configurer le serveur SonarQube**

```
Jenkins → Administrer Jenkins → System → SonarQube servers
→ Add SonarQube : Name = sonarqube | URL = http://sonarqube:9000
→ Server authentication token : sonar-token
```
![image](https://hackmd.io/_uploads/BkPr8qMGfx.png)
![image](https://hackmd.io/_uploads/SkbTUqzzzl.png)

**Étape 4 - Configurer le webhook SonarQube → Jenkins**

```
SonarQube → Administration → Configuration → Webhooks
→ Add webhook : Name = jenkins
→ URL = http://jenkins:8080/sonarqube-webhook/
```
![image](https://hackmd.io/_uploads/B1tU_cMffl.png)
![image](https://hackmd.io/_uploads/rJIvd9zffl.png)
![image](https://hackmd.io/_uploads/BkRCd9fGzg.png)
![image](https://hackmd.io/_uploads/rkiJF5MMfe.png)

Le **slash final** dans l'URL du webhook est obligatoire. Sans lui, Jenkins ne recevra pas la notification du Quality Gate.

---

###  Réponse 1.1 - Page d'accueil SonarQube

> **Note :** Un screenshot réel doit être joint au rendu. La page `http://localhost:9000` affiche après connexion le projet **SentimentAI** dans le dashboard avec ses métriques initiales (0 bugs, 0 code smells, coverage non encore calculée). Le projet apparaît avec la clé `sentiment-ai` et la branche `main`.
![image](https://hackmd.io/_uploads/By5MKqfzfx.png)

---

###  Réponse 1.2 - Pourquoi `--network cicd-network` ?

Docker isole les conteneurs dans des réseaux virtuels distincts. Par défaut, deux conteneurs lancés sans réseau commun ne peuvent pas se joindre par nom - ils ne partagent pas de DNS interne.

En plaçant `sonarqube` et `jenkins` sur `cicd-network` :

- Jenkins peut résoudre `http://sonarqube:9000` via le DNS interne Docker (le nom du conteneur devient un nom d'hôte).
- Le scanner SonarQube lancé depuis Jenkins peut envoyer les résultats d'analyse au serveur SonarQube.
- Le webhook SonarQube → Jenkins (`http://jenkins:8080/sonarqube-webhook/`) fonctionne également par ce même mécanisme.

**Sans ce paramètre**, Jenkins tenterait de résoudre `sonarqube` et obtiendrait une `UnknownHostException: sonarqube`. Le stage **Quality Gate** échouerait immédiatement car `waitForQualityGate` ne peut pas joindre le serveur pour récupérer le résultat.

---

### Réponse 1.3 - Bug vs Code Smell en Python

| | Bug | Code Smell |
|---|---|---|
| **Définition** | Erreur qui **va** provoquer un comportement incorrect à l'exécution | Code qui **fonctionne** mais est difficile à comprendre, maintenir ou faire évoluer |
| **Risque** | Crash, résultat faux, exception non gérée | Pas de dysfonctionnement immédiat, mais accumulation de dette technique |
| **Action SonarQube** | Bloque le Quality Gate si sévérité ≥ seuil configuré | Comptabilisé en "dette technique" (temps estimé de correction) |

SonarQube signale : *"A 'KeyError' exception might be thrown here"*. Le code plantera en production si `analyze()` retourne un dict sans la clé `score`.

**Exemple de Code Smell en Python :**

```python
def p(t, l, s, m):          # Code Smell : noms de paramètres non explicites
    for i in range(len(l)):  # Code Smell : utiliser enumerate() à la place
        if l[i] == t:
            s = s + l[i]     # Code Smell : utiliser s += l[i]
    return s
```
Le code s'exécute correctement, mais un développeur qui reprend ce code ne comprend pas ce que `p`, `t`, `l`, `s`, `m` représentent - maintenance et debugging difficiles.

---

## 2 - Intégrer SonarQube dans le Jenkinsfile

### 2.1 Modifier le stage Build & Test pour générer `coverage.xml`

SonarQube lit le rapport de couverture produit par `pytest`. Il faut modifier le stage Build & Test pour nommer le conteneur de test et copier `coverage.xml` vers le workspace Jenkins.

```groovy
stage('Build & Test') {
  steps {
    sh '''
      docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

      # Supprimer un éventuel conteneur test-runner résiduel
      docker rm -f test-runner 2>/dev/null || true

      # set +e : désactive l'arrêt automatique sur erreur
      # Permet de copier coverage.xml même si pytest échoue
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
      set -e  # Réactive l'arrêt automatique sur erreur

      # Copier coverage.xml depuis le conteneur vers le workspace
      docker cp test-runner:/tmp/coverage.xml ./coverage.xml 2>/dev/null || true
      docker rm -f test-runner 2>/dev/null || true

      # Retourner le code de sortie original des tests
      exit $TEST_EXIT_CODE
    '''
  }
  post {
    failure { echo 'Tests échoués ou coverage insuffisant (< 70%)' }
  }
}
```

Fichier Jenkinsfile : 

```bash
cat > Jenkinsfile << 'EOF'
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
EOF
```

![image](https://hackmd.io/_uploads/B1cQjczfGx.png)

- Faire un test

```bash
git add Jenkinsfile
git commit -m "Add coverage + build test"
git push origin main
```
![image](https://hackmd.io/_uploads/B15dscGMfg.png)

- Trouver le fichier coverage.xml

```bash
docker exec -it jenkins ls -l /var/jenkins_home/workspace/sentiment-ai-pipeline
```
![image](https://hackmd.io/_uploads/BJzcncfMGx.png)

- Afficher le contenu coverage.xml

```bash
docker exec -it jenkins cat /var/jenkins_home/workspace/sentiment-ai-pipeline/coverage.xml
```
![image](https://hackmd.io/_uploads/BkC0n5zfzl.png)
![image](https://hackmd.io/_uploads/Skt4a5GMMx.png)

**Pourquoi `set +e` / `set -e` ?**  
Par défaut, Bash arrête le script dès qu'une commande retourne un code non nul (`set -e`). On désactive temporairement ce comportement (`set +e`) pour pouvoir copier `coverage.xml` même en cas d'échec de pytest, puis on restaure le comportement strict (`set -e`) avant de retourner le bon code de sortie. Sans ce mécanisme, un échec de `pytest` bloquerait la copie du fichier et SonarQube n'aurait pas accès au rapport.

### 2.2 Ajouter le stage SonarQube Analysis

Placez ce stage **après** Build & Test et **avant** Quality Gate :

```groovy
stage('SonarQube Analysis') {
  environment {
    SONARQUBE_TOKEN = credentials('sonar-token')
  }
  steps {
    withSonarQubeEnv('sonarqube') {
      sh '''
        docker run --rm \
          --network cicd-network \
          --volumes-from jenkins \
          -w "$WORKSPACE" \
          -e SONAR_HOST_URL="$SONAR_HOST_URL" \
          -e SONAR_TOKEN="$SONARQUBE_TOKEN" \
          sonarsource/sonar-scanner-cli:latest \
          sonar-scanner \
            -Dsonar.projectKey=sentiment-ai \
            -Dsonar.projectName=SentimentAI \
            -Dsonar.projectBaseDir="$WORKSPACE" \
            -Dsonar.sources=src \
            -Dsonar.python.version=3.11 \
            -Dsonar.python.coverage.reportPaths=coverage.xml \
            -Dsonar.sourceEncoding=UTF-8 \
            -Dsonar.scanner.metadataFilePath=$WORKSPACE/report-task.txt
      '''
    }
  }
}
```

- Fichier Jenkinsfile : 
```bash
cat > Jenkinsfile << 'EOF'
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

    stage('SonarQube Analysis') {
      environment {
        SONARQUBE_TOKEN = credentials('sonar-token')
      }

      steps {
        withSonarQubeEnv(installationName: 'sonarqube') {
          sh '''
            docker run --rm \
              -v $WORKSPACE:/usr/src \
              -w /usr/src \
              -e SONAR_HOST_URL=$SONAR_HOST_URL \
              -e SONAR_TOKEN=$SONARQUBE_TOKEN \
              sonarsource/sonar-scanner-cli:latest \
              sonar-scanner \
                -Dsonar.projectKey=sentiment-ai \
                -Dsonar.projectName=SentimentAI \
                -Dsonar.projectBaseDir=/usr/src \
                -Dsonar.sources=. \
                -Dsonar.python.version=3.11 \
                -Dsonar.python.coverage.reportPaths=coverage.xml \
                -Dsonar.sourceEncoding=UTF-8
          '''
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
EOF
```
![image](https://hackmd.io/_uploads/BJYWRqzGGx.png)


**`--volumes-from jenkins`** : monte les volumes du conteneur Jenkins dans le conteneur sonar-scanner-cli. Le workspace Jenkins (avec le code source et `coverage.xml`) devient ainsi accessible au scanner sans avoir à le copier manuellement.  
**`-Dsonar.scanner.metadataFilePath`** : indique à SonarQube où écrire le fichier `report-task.txt` contenant l'ID de l'analyse - nécessaire pour que `waitForQualityGate` sache quelle analyse attendre.

- Test 

```bash
git add Jenkinsfile
git commit -m "fix: adjust sonar sources path and base directory"
git push origin main
```
![image](https://hackmd.io/_uploads/Bke73sGGfg.png)

#### Résultat du build
![image](https://hackmd.io/_uploads/r1QL3oMGfe.png)
![image](https://hackmd.io/_uploads/B1I_3iGMzg.png)



### 2.3 Ajouter le stage Quality Gate

```groovy
stage('Quality Gate') {
  steps {
    timeout(time: 15, unit: 'MINUTES') {
      // Attend le résultat asynchrone du Quality Gate SonarQube via webhook
      // abortPipeline: true => arrête le pipeline si le gate échoue
      waitForQualityGate abortPipeline: true
    }
  }
}
```

#### Fichier Jenkinsfile

```bash
cat > Jenkinsfile << 'EOF'
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
        SONAR_HOST_URL  = 'http://4.223.165.64:9000/'
      }

      steps {
        sh '''
          if [ ! -d "$HOME/.sonar/sonar-scanner-5.0.1.3006-linux" ]; then
            echo "Téléchargement du Sonar Scanner natif..."
            mkdir -p $HOME/.sonar
            curl -sSLo $HOME/.sonar/sonar-scanner.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip
            unzip -q -o $HOME/.sonar/sonar-scanner.zip -d $HOME/.sonar/
          fi

          echo "Exécution du scan natif..."
          $HOME/.sonar/sonar-scanner-5.0.1.3006-linux/bin/sonar-scanner \
            -Dsonar.host.url=$SONAR_HOST_URL \
            -Dsonar.login=$SONARQUBE_TOKEN \
            -Dsonar.projectKey=sentiment-ai \
            -Dsonar.projectName=SentimentAI \
            -Dsonar.sources=src \
            -Dsonar.python.version=3.11 \
            -Dsonar.python.coverage.reportPaths=coverage.xml \
            -Dsonar.sourceEncoding=UTF-8

          echo "Vérification du Quality Gate..."
          sleep 5
          STATUS=$(curl -s -u "${SONARQUBE_TOKEN}:" "${SONAR_HOST_URL}api/qualitygates/project_status?projectKey=sentiment-ai" | grep -o '"status":"[^"]*"' | head -1 | cut -d'"' -f4)
          echo "Le statut du Quality Gate SonarQube est : $STATUS"
          
          if [ "$STATUS" = "ERROR" ]; then
            echo "Le Quality Gate a échoué !"
            exit 1
          fi
        '''
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
EOF
```
![image](https://hackmd.io/_uploads/HJSA3jzfMx.png)


**Fonctionnement de `waitForQualityGate`**  
SonarQube analyse le code de façon **asynchrone** après réception des données du scanner. `waitForQualityGate` suspend Jenkins en attendant la notification via le webhook configuré. Si le Quality Gate échoue (ex : coverage < 70%), `abortPipeline: true` arrête le pipeline - l'image ne sera jamais poussée vers le registry.

#### Test
```bash
git add Jenkinsfile
git commit -m "fix: pass explicitly SONAR_HOST_URL env variable"
git push origin main
```
![image](https://hackmd.io/_uploads/S1J54hGzGx.png)



#### Résultat 
![image](https://hackmd.io/_uploads/HyJRN3MGzl.png)

### 2.4 Configurer le Quality Gate personnalisé

Dans SonarQube :

```
Quality Gates → Create → Nom : SentimentAI-Gate
→ Add Condition : Coverage ≥ 70% (sur Overall Code)
→ Add Condition : Reliability Rating ≥ B
→ SentimentAI → Project Settings → Quality Gate → SentimentAI-Gate
```

---

### Réponse 2.1 - Dashboard SonarQube de SentimentAI

**Note :** Un screenshot réel doit être joint au rendu. Le dashboard affiche les 5 métriques principales du projet `sentiment-ai` : Bugs, Vulnerabilities, Code Smells, Coverage (en %), et Duplications (en %). Après une première analyse, les valeurs typiques pour SentimentAI seraient par exemple : 0 bugs, 0 vulnérabilités, 3 code smells, 82% coverage, 0% duplication.
![image](https://hackmd.io/_uploads/Hy_tt3GGfl.png)
![image](https://hackmd.io/_uploads/Hk-N9nfzzg.png)


---

### Réponse 2.2 - Résultat du Quality Gate

Le Quality Gate configuré définit deux conditions :
- Coverage ≥ 70% sur Overall Code
- Reliability Rating ≥ B (c'est-à-dire 0 bug bloquant)

**Si le coverage dépasse 70% et qu'aucun bug de sévérité A n'est détecté → Quality Gate vert (Passed).**

Le pipeline continue jusqu'au stage Push et l'image est poussée vers GHCR.

**Si le coverage est inférieur à 70% ou qu'un bug critique est présent → Quality Gate rouge (Failed).**

`waitForQualityGate abortPipeline: true` reçoit la notification d'échec via le webhook et déclenche l'arrêt immédiat du pipeline. Les stages Security Scan, Push et Deploy Staging ne sont jamais exécutés.

---

### Réponse 2.3 - Exemple de Code Smell signalé par SonarQube

Un exemple typique que SonarQube signale dans du code Python :

```
src/sentiment.py:45 - Remove this commented-out code.
```

Ou encore :

```
src/api.py:12 - Merge this if statement with the enclosing one.
```

**Correction :** Supprimer le code commenté (il doit vivre dans Git, pas dans le fichier source) ou fusionner les conditions `if` imbriquées en une seule expression avec `and` :

```python
# Avant (Code Smell - if imbriqués)
if text:
    if len(text) > 0:
        return analyze(text)

# Après (corrigé)
if text and len(text) > 0:
    return analyze(text)
```

---

### Réponse 2.4 - Impact d'un Quality Gate échoué dans Jenkins

Quand le Quality Gate échoue :

1. SonarQube envoie une notification `FAILED` au webhook Jenkins (`http://jenkins:8080/sonarqube-webhook/`).
2. `waitForQualityGate abortPipeline: true` reçoit ce statut et **lève une exception** dans le pipeline.
3. Jenkins marque le build comme **FAILED** (rouge) et **arrête l'exécution immédiatement**.
4. Le stage **Security Scan** (stage 6) n'est jamais atteint.
5. Le stage **Push to GHCR** (stage 7) n'est jamais exécuté - l'image reste locale et n'est pas publiée.
6. Le stage **Deploy Staging** (stage 8) n'est jamais exécuté - aucune mise en production.

C'est précisément l'objectif : empêcher qu'une image de mauvaise qualité soit distribuée ou déployée.

---

## 3 - Scanner l'image avec Trivy

**Trivy** (Aqua Security) est un scanner de vulnérabilités open source. Là où SonarQube inspecte le code source, Trivy inspecte l'**image Docker produite** : il liste toutes les CVE connues dans les paquets OS installés et les dépendances Python.

### 3.1 Tester Trivy manuellement

Avant d'intégrer Trivy dans le pipeline, testez-le pour comprendre le format du rapport :

```bash
# Scanner l'image SentimentAI avec Trivy via Docker
# --exit-code 0 : affiche les vulnérabilités sans faire échouer la commande
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $HOME/.cache/trivy:/root/.cache/trivy \
  aquasec/trivy:latest image \
  --severity HIGH,CRITICAL \
  --exit-code 0 \
  sentiment-ai:e41f837
```
![image](https://hackmd.io/_uploads/SJEashffMe.png)
![image](https://hackmd.io/_uploads/H1SRj3zzMl.png)
![image](https://hackmd.io/_uploads/SJbk2nMzfe.png)


Le rapport affiché contient :

| Colonne | Signification |
|---|---|
| `SEVERITY` | Niveau de risque : `HIGH` ou `CRITICAL` |
| `Vulnerability` | Identifiant CVE (ex : `CVE-2023-1234`) |
| `Fixed Version` | Version corrigée disponible (vide = pas encore de correctif) |

**Corriger une CVE dans `requirements.txt`** :

```bash
# 1. Repérez la colonne "Fixed Version" dans le rapport Trivy
# 2. Mettez à jour requirements.txt
#    ex: requests==2.31.0  →  requests==2.32.0

# 3. Rebuildez et re-scannez
docker build -t sentiment-ai:latest .
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image \
  --severity HIGH,CRITICAL \
  --exit-code 0 \
  sentiment-ai:latest
```
![image](https://hackmd.io/_uploads/BkoK2hfzzx.png)


> Si la colonne `Fixed Version` est **vide**, il n'existe pas encore de correctif disponible pour cette CVE.

### 3.2 Ajouter le stage Security Scan au Jenkinsfile

Placez ce stage **après** Quality Gate et **avant** Push :

```groovy
stage('Security Scan') {
  steps {
    // --exit-code 1 : fait échouer le stage si une CVE HIGH ou CRITICAL est trouvée
    // --format table : rapport lisible dans les logs Jenkins
    // trivy-cache : volume Docker nommé pour mettre en cache la base de données CVE
    sh '''
      docker run --rm \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v trivy-cache:/root/.cache/trivy \
        aquasec/trivy:latest image \
        --severity HIGH,CRITICAL \
        --exit-code 1 \
        --format table \
    ''' + "${IMAGE_NAME}:${IMAGE_TAG}"
  }
  post {
    failure {
      echo 'Vulnérabilités CRITICAL ou HIGH détectées !'
      echo 'Corrigez les dépendances avant de déployer.'
    }
  }
}
```

#### Fichier Jenkinsfile

```bash
cat > Jenkinsfile << 'EOF'
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
        SONAR_HOST_URL  = 'http://4.223.165.64:9000/'
      }

      steps {
        sh '''
          if [ ! -d "$HOME/.sonar/sonar-scanner-5.0.1.3006-linux" ]; then
            echo "Téléchargement du Sonar Scanner natif..."
            mkdir -p $HOME/.sonar
            curl -sSLo $HOME/.sonar/sonar-scanner.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip
            unzip -q -o $HOME/.sonar/sonar-scanner.zip -d $HOME/.sonar/
          fi

          echo "Exécution du scan natif..."
          $HOME/.sonar/sonar-scanner-5.0.1.3006-linux/bin/sonar-scanner \
            -Dsonar.host.url=$SONAR_HOST_URL \
            -Dsonar.login=$SONARQUBE_TOKEN \
            -Dsonar.projectKey=sentiment-ai \
            -Dsonar.projectName=SentimentAI \
            -Dsonar.sources=src \
            -Dsonar.python.version=3.11 \
            -Dsonar.python.coverage.reportPaths=coverage.xml \
            -Dsonar.sourceEncoding=UTF-8

          echo "Vérification du Quality Gate..."
          sleep 5
          STATUS=$(curl -s -u "${SONARQUBE_TOKEN}:" "${SONAR_HOST_URL}api/qualitygates/project_status?projectKey=sentiment-ai" | grep -o '"status":"[^"]*"' | head -1 | cut -d'"' -f4)
          echo "Le statut du Quality Gate SonarQube est : $STATUS"
          
          if [ "$STATUS" = "ERROR" ]; then
            echo "Le Quality Gate a échoué !"
            exit 1
          fi
        '''
      }
    }

    stage('Security Scan') {
      steps {
        sh '''
          docker run --rm \
            -v /var/run/docker.sock:/var/run/docker.sock \
            -v trivy-cache:/root/.cache/trivy \
            aquasec/trivy:latest image \
            --severity HIGH,CRITICAL \
            --exit-code 1 \
            --format table \
        ''' + "${IMAGE_NAME}:${IMAGE_TAG}"
      }
      post {
        failure {
          echo 'Vulnérabilités CRITICAL ou HIGH détectées !'
          echo 'Corrigez les dépendances avant de déployer.'
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
EOF
```

#### Test 
```bash
git add Jenkinsfile
git commit -m "feat: add automated trivy security scan stage"
git push origin main
```
![image](https://hackmd.io/_uploads/BJI7pnGzfl.png)


**`-v /var/run/docker.sock:/var/run/docker.sock`**  
Trivy a besoin d'accéder au **daemon Docker** de l'hôte pour inspecter l'image. Le fichier `/var/run/docker.sock` est la socket Unix qui permet de communiquer avec ce daemon. Sans ce montage, Trivy tourne dans un conteneur isolé qui ne voit pas les images Docker de l'hôte - l'analyse est impossible.

**Stratégie progressive**  
Commencez avec `--exit-code 0` pour découvrir l'état réel de vos images sans bloquer le pipeline. Une fois les CVE CRITICAL corrigées, passez à `--exit-code 1`. En production, on bloque systématiquement sur CRITICAL et souvent sur HIGH également.

---

### Réponse 3.1 - Résumé du rapport Trivy



Le rapport Trivy met en évidence plusieurs vulnérabilités détectées dans l'image Docker analysée.

### 1. Vulnérabilités du système d'exploitation

- **Système détecté :** Debian 13.5
- Trivy a identifié que l'image Docker repose sur une base **Debian 13.5**.
- Sur cette couche système, **11 vulnérabilités de niveau HIGH ou CRITICAL** ont été détectées.

### 2. Vulnérabilités des dépendances Python

Au niveau des bibliothèques Python utilisées par l'application :

- **starlette** (dépendance installée automatiquement par **FastAPI**) contient :
  - **3 vulnérabilités de niveau HIGH ou CRITICAL**

- **wheel** :
  - **1 vulnérabilité détectée**

- **setuptools** (notamment via le sous-package `jaraco.context`) :
  - **1 vulnérabilité détectée**

### Conclusion

L'analyse Trivy révèle des vulnérabilités à deux niveaux :

1. **Système d'exploitation (Debian 13.5)** : 11 vulnérabilités HIGH/CRITICAL.
2. **Dépendances applicatives Python** : plusieurs vulnérabilités affectant notamment `starlette`, `wheel` et `setuptools`.

Ces résultats indiquent la nécessité de :
- Mettre à jour l'image de base Docker.
- Mettre à jour les dépendances Python concernées.
- Relancer une analyse Trivy après correction afin de vérifier la disparition des vulnérabilités détectées.

Dans cet exemple : **3 CRITICAL** et **12 HIGH** détectées au total entre les paquets OS Debian et les dépendances Python.

---

###  Réponse 3.2 - Analyse d'une CVE et correction

#### Correction dans Dockerfile (Pour les 11 CVE Debian)

```bash
cat > Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app
# --- AJOUTER CETTE LIGNE POUR CORRIGER LES CVE SYSTÈME ---
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF
```
![image](https://hackmd.io/_uploads/Hya-ypfGzx.png)

#### Correction dans requirements.txt (Pour Starlette, Requests, etc.)

```bash
cat > requirements.txt << 'EOF'
fastapi>=0.111.0
uvicorn==0.27.0
requests>=2.31.0
httpx
pytest
pytest-cov
EOF
```

![image](https://hackmd.io/_uploads/HyCHlafffe.png)


#### Mise à jour du dépôt

```bash
git add Dockerfile requirements.txt
git commit -m "fix: patch dependencies and base image to satisfy security requirements"
git push origin main
```
![image](https://hackmd.io/_uploads/H12j1TzMMe.png)

---

### Réponse 3.3 - Pourquoi `-v /var/run/docker.sock:/var/run/docker.sock` ?

`/var/run/docker.sock` est la **socket Unix** du daemon Docker de l'hôte - l'interface de communication entre les clients Docker et le moteur qui gère les conteneurs et les images.

Trivy lui-même s'exécute dans un conteneur Docker. Sans ce montage, ce conteneur Trivy est complètement isolé et ne voit pas les images présentes sur l'hôte. En montant la socket Docker de l'hôte dans le conteneur Trivy, on lui donne accès au daemon Docker de la machine hôte : il peut ainsi lister les images locales et inspecter leurs layers pour y détecter les CVE.

**En résumé :** sans `-v /var/run/docker.sock:/var/run/docker.sock`, Trivy ne peut pas voir l'image `sentiment-ai:latest` et le scan est impossible.

---

## 4 - Pipeline complet 8 stages

### 4.1 Vue d'ensemble

| # | Stage | Ce qu'il fait | Condition |
|---|---|---|---|
| 1 | **Checkout** | Clone le repo Git + calcule l'`IMAGE_TAG` | Toujours |
| 2 | **Lint** | Vérifie la syntaxe Python avec `flake8` | Toujours |
| 3 | **Build & Test** | Docker build + `pytest` + génère `coverage.xml` | Toujours |
| 4 | **SonarQube Analysis** | Analyse statique du code source | Toujours |
| 5 | **Quality Gate** | Bloque si coverage < 70% ou bugs critiques | Toujours |
| 6 | **Security Scan** | Scan CVE Trivy - bloque si CRITICAL ou HIGH | Toujours |
| 7 | **Push to GHCR** | Pousse l'image vers `ghcr.io` | Branche `main` uniquement |
| 8 | **Deploy Staging** | Déploie en staging via `docker compose` | Branche `main` uniquement |



### 4.3 Commit final 

```bash
cat >> README.md << 'EOF'

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
EOF
```

```bash
git add README.md
git commit -m "ci: finalize pipeline with 8 stages (sonar, trivy, deploy)"
git push origin main
```
![image](https://hackmd.io/_uploads/BkdffpzGfl.png)
![image](https://hackmd.io/_uploads/H1ROm6zfGl.png)



---

### Réponse 4.1 - Pipeline Jenkins 8 stages en vert

> **Note :** Un screenshot réel doit être joint au rendu. Il doit montrer les 8 stages - Checkout, Lint, Build & Test, SonarQube Analysis, Quality Gate, Security Scan, Push to GHCR, Deploy Staging - tous affichés en vert dans la vue Blue Ocean ou la vue classique de Jenkins.

---

### Réponse 4.2 - Durée totale et stage le plus long

La durée totale attendue est de **5 à 10 minutes** selon les performances de la machine hôte et la disponibilité du cache Trivy.

Le stage le plus long est généralement **Build & Test** ou **SonarQube Analysis** :

- **Build & Test** : Docker doit construire l'image complète (téléchargement des layers si pas en cache, installation des dépendances Python), puis exécuter pytest sur l'ensemble des tests avec calcul de la couverture.
- **SonarQube Analysis** : le scanner télécharge `sonarsource/sonar-scanner-cli:latest` (si absent du cache Docker), analyse l'intégralité du code source et envoie les résultats. `waitForQualityGate` ajoute également un temps d'attente asynchrone lié à l'analyse serveur SonarQube.

Sur une machine sans cache Docker préconstruit, **Build & Test** est souvent le plus long car il cumule build d'image + téléchargement de paquets + exécution des tests.

---

###  Réponse 4.3 - Arrêt du pipeline sur CVE CRITICAL

Le pipeline s'arrête au **stage 6 - Security Scan**.

Trivy détecte la CVE CRITICAL, retourne un code de sortie `1` (grâce à `--exit-code 1`), ce qui fait échouer la commande `sh` dans Jenkins. Le stage est marqué FAILED et le pipeline s'arrête.

**Conséquences :**

| Stage | Exécuté ? |
|---|---|
| 1 Checkout |  Oui |
| 2 Lint |  Oui |
| 3 Build & Test |  Oui |
| 4 SonarQube Analysis | Oui |
| 5 Quality Gate |  Oui |
| 6 Security Scan |  FAILED - pipeline arrêté |
| **7 Push to GHCR** | ** Jamais exécuté** |
| **8 Deploy Staging** | ** Jamais exécuté** |

L'image reste uniquement en local et n'est **jamais publiée** sur GHCR, empêchant sa propagation en staging ou en production.

---

###  Réponse 4.4 - Déploiement Blue/Green

Le déploiement **Blue/Green** consiste à maintenir **deux environnements de production identiques** : l'un actif (Blue, qui reçoit le trafic), l'autre en attente (Green). Lors d'un déploiement, la nouvelle version est déployée sur Green, testée, puis le trafic est basculé instantanément de Blue vers Green via un load balancer ou un DNS.

**Avantage principal par rapport au déploiement direct (notre `docker compose up -d`) :**

En cas de problème sur la nouvelle version, le rollback est **immédiat** - il suffit de re-basculer le trafic vers Blue, sans downtime ni reconstruction d'image. Notre approche actuelle (`down` puis `up`) implique une interruption de service pendant le redémarrage et nécessite un rebuild si le rollback est nécessaire.

---

## Questions de synthèse

###  Synthèse 1 - SonarQube vs Trivy : différences fondamentales

| | SonarQube | Trivy |
|---|---|---|
| **Ce qu'il inspecte** | Le **code source** (fichiers `.py`, logique applicative) | L'**image Docker** (layers OS + dépendances installées) |
| **Ce qu'il détecte** | Bugs logiques, failles dans le code applicatif, mauvaises pratiques, coverage insuffisant | CVE dans les paquets Debian/Alpine/Ubuntu et les librairies Python (`pip`) |
| **Ce qu'il ne voit PAS** | Les vulnérabilités dans les paquets système de l'image Docker | Les bugs logiques, code smells, ou manque de tests dans le code source |

En résumé : SonarQube protège contre les **erreurs du développeur**, Trivy protège contre les **failles des dépendances tierces**. Les deux sont complémentaires et indispensables.

---

### Synthèse 2 - Ordre Quality Gate → Security Scan → Push

L'ordre est délibéré et suit le principe du **fail fast** (échouer le plus tôt possible) :

1. **Quality Gate avant Security Scan** : inutile de scanner une image si le code source est de mauvaise qualité ou sous-testé. On évite de perdre du temps à analyser une image qui de toute façon ne passerait pas.
2. **Security Scan avant Push** : inutile de pousser une image vulnérable sur le registry. Une image sur GHCR peut être récupérée par d'autres pipelines ou déployée par erreur.
3. **Push en dernier** (avant Deploy) : l'image ne quitte la machine locale que si elle a passé **toutes** les vérifications précédentes.

Cet ordre minimise également les coûts : pousser une image vers un registry consomme de la bande passante et du temps - autant ne le faire que si l'image est sûre et de qualité.

---

###  Synthèse 3 - Coverage 65% et Quality Gate à 70%

Non, une image avec 65% de coverage **ne passe pas** le Quality Gate configuré à 70%.

Voici ce qui se passe exactement dans Jenkins :

1. `pytest` s'exécute avec `--cov-fail-under=70` → le stage **Build & Test** échoue déjà (code de sortie non nul).
2. Si on corrige ce seuil dans pytest mais pas dans SonarQube : l'analyse SonarQube reçoit `coverage.xml`, calcule 65%, et marque le Quality Gate comme **FAILED**.
3. SonarQube notifie Jenkins via le webhook.
4. `waitForQualityGate abortPipeline: true` reçoit le statut FAILED et **lève une exception** dans le pipeline.
5. Jenkins marque le build en rouge et arrête l'exécution.
6. Les stages Security Scan, Push to GHCR et Deploy Staging ne sont jamais atteints.

---

###  Synthèse 4 - Dette technique et Code Smells SonarQube

La **dette technique** est une métaphore financière : comme une dette d'argent, elle s'accumule avec intérêts. Chaque fois qu'un développeur choisit une solution rapide mais sous-optimale (code dupliqué, variable mal nommée, fonction trop longue, absence de tests), il contracte une dette - le code fonctionne aujourd'hui, mais sera plus difficile et coûteux à modifier demain.

Les **Code Smells SonarQube** sont la mesure concrète de cette dette : SonarQube estime pour chaque smell le temps nécessaire pour le corriger (en minutes) et les somme pour afficher une **dette technique totale** (ex : "3h 20min"). Plus la dette est élevée, plus les futures évolutions, corrections de bugs et montées en version seront lentes et risquées.

**Lien direct :** chaque Code Smell non corrigé = une ligne de la dette. Ignorer les Code Smells pendant des mois conduit à un code impossible à tester, refactoriser ou transférer à un nouveau développeur.

---

###  Synthèse 5 - `git log --oneline` sur `main`

> **Note :** La liste ci-dessous doit être remplacée par la sortie réelle de `git log --oneline -5` sur votre machine. Voici un exemple conforme aux commits conventionnels attendus :

```bash
git log --oneline -5
```

```
a3f9c12 ci: finalize pipeline with 8 stages (sonar, trivy, deploy)
b7d2e41 ci: add security scan stage with Trivy
c1f8a03 ci: add sonarqube analysis and quality gate stages
d4e9b17 test: add coverage reporting with pytest-cov
e2c5f88 feat: initial SentimentAI application with Docker setup
```

Les messages suivent la convention **Conventional Commits** : `type(scope): description` où `type` est `feat`, `fix`, `ci`, `test`, `docs`, `refactor`, etc.

---
# TP 4 - Terraform & Infrastructure as Code


Provisionner l'environnement staging de SentimentAI avec Terraform

---

## Objectif

Remplacer le `docker compose up` manuel par Terraform : l'infrastructure devient **déclarative**, **versionnée dans Git** et **intégrée au pipeline Jenkins**.

| Livrable attendu | Critère de validation |
|---|---|
| Dossier `infra/` commité | `main.tf`, `variables.tf`, `outputs.tf` présents |
| `terraform apply` fonctionnel | Conteneur staging démarré sur le port 8001 |
| Pipeline Jenkins 10 stages | Tous les stages verts sur `main` |

---


Terraform décrit **ce qu'on veut** (un réseau, une image, un conteneur) et `terraform apply` le crée : idempotent, reproductible, traçable.

---

## 1. Installer Terraform

### 1.1 Installation

**Linux (Ubuntu/Debian)**

```bash
wget -O - https://apt.releases.hashicorp.com/gpg | \
  sudo gpg --dearmor -o /usr/share/keyrings/hashicorp.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update && sudo apt install terraform -y
```

**Ce que font ces commandes :**
1. On importe la clé GPG officielle de HashiCorp pour vérifier l'authenticité des paquets.
2. On ajoute le dépôt HashiCorp dans les sources APT en le liant à cette clé.
3. On met à jour la liste des paquets et on installe Terraform.



**Vérification**

```bash
terraform version
```
![image](https://hackmd.io/_uploads/H1OVOpGfMx.png)


---

### 1.2 Structure du projet

```bash
mkdir -p infra
touch infra/main.tf infra/variables.tf infra/outputs.tf
find infra/ | sort
```
![image](https://hackmd.io/_uploads/BJUnuazMfl.png)


> **Convention de découpage en 3 fichiers :**
>
> | Fichier | Rôle |
> |---|---|
> | `main.tf` | Provider + ressources Docker (réseau, image, conteneur) |
> | `variables.tf` | Paramètres configurables (port, nom, tag d'image…) |
> | `outputs.tf` | Valeurs exposées après `apply` (URL, ID conteneur…) |
>
> Ce découpage est une convention Terraform, pas une obligation technique. Il améliore la lisibilité et permet de modifier les paramètres sans toucher aux ressources.

---

### 1.3 Mettre à jour `.gitignore`

```bash
cat >> .gitignore << 'EOF'
# Terraform
.terraform/
*.tfstate
*.tfstate.backup
.terraform.lock.hcl
EOF
```
![image](https://hackmd.io/_uploads/HyOHYpMzGg.png)

>  **Important - à faire avant le premier `terraform init`**
>
> - `.terraform/` contient les **plugins providers** téléchargés (binaires lourds, inutiles à versionner).
> - `*.tfstate` et `*.tfstate.backup` contiennent l'**état de l'infrastructure** : IDs de ressources, parfois des secrets. Ce fichier ne doit **jamais** être dans Git en production (utiliser un backend distant comme S3 à la place).
> - `.terraform.lock.hcl` fixe les versions des providers ; peut être commité selon les équipes, mais souvent ignoré.

---

###  Question 1.1

Faites un screenshot de `terraform version`. Quelle version est installée sur votre machine ?
![image](https://hackmd.io/_uploads/BJBctTfzfl.png)
Version : v1.15.6

###  Question 1.2

Pourquoi ajoute-t-on `.terraform/` dans `.gitignore` ? Que contient ce dossier après `terraform init` ?

**Réponse :** Après `terraform init`, `.terraform/` contient les binaires des providers téléchargés (ici `kreuzwerker/docker`). Ces binaires sont compilés pour l'OS courant, volumineux, et régénérables à la demande - les committer alourdirait le dépôt inutilement.

---

## 2. Écrire les Fichiers HCL

### 2.1 Configurer le provider Docker - `infra/main.tf`

Avant d'écrire le fichier, vérifiez l'emplacement du socket Docker :

```bash
# Linux : socket standard
ls -la /var/run/docker.sock
```
![image](https://hackmd.io/_uploads/H110KpGzGe.png)


```bash
cat > infra/main.tf << 'EOF'
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
EOF
```
![image](https://hackmd.io/_uploads/BJKU9pGMzl.png)


**Rôle du provider Docker**

Le provider `kreuzwerker/docker` est un **plugin Terraform** qui communique avec le daemon Docker via le socket Unix - exactement comme Docker Compose, mais de façon déclarative.

- `source = "kreuzwerker/docker"` : identifiant du provider dans le registre Terraform public.
- `version = "~> 3.0"` : opérateur pessimiste - accepte `3.0`, `3.1`, `3.x`… mais pas `4.0`. Protège contre les breaking changes.
- `terraform init` télécharge ce provider dans `.terraform/` (ignoré par Git).

---

### 2.2 Déclarer les variables - `infra/variables.tf`

```bash
cat > infra/variables.tf << 'EOF'
# infra/variables.tf

variable "image_tag" {
  description = "Tag de l'image Docker a deployer"
  type        = string
  default     = "latest"
}

# Port 8080 réservé à Jenkins -- staging sur 8001
variable "app_port" {
  description = "Port expose en staging"
  type        = number
  default     = 8001
}

variable "container_name" {
  description = "Nom du conteneur staging"
  type        = string
  default     = "sentiment-staging"
}

variable "registry" {
  description = "Registry Docker (ex: ghcr.io/monpseudo)"
  type        = string
  default     = "ghcr.io/dspitech"
}
EOF
```
![image](https://hackmd.io/_uploads/S1Hsc6zzfx.png)


> **Pourquoi des variables ?**
>
> Les variables Terraform permettent de **paramétrer la configuration sans modifier les ressources**. On les déclare dans `variables.tf` et on les référence dans `main.tf` via `${var.nom}`.
>
> Avantages :
> - Changer le port ou le tag de l'image ne nécessite qu'une modification dans `variables.tf`.
> - Les valeurs peuvent être surchargées au moment du `terraform apply` via `-var='app_port=9000'` ou un fichier `.tfvars`.
>
>  **Conflit de port :** Jenkins occupe le port 8080 depuis le TP2. `app_port` est fixé à `8001` pour éviter tout conflit.

---

### 2.3 Déclarer les ressources - suite de `infra/main.tf`

```bash
cat >> infra/main.tf << 'EOF'

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
EOF
```
![image](https://hackmd.io/_uploads/SkfHs6fGMg.png)


> **Anatomie des ressources**
>
> **`docker_network "cicd"`**
> Crée (ou référence) le réseau `cicd-network` partagé entre Jenkins, SonarQube et SentimentAI. Si ce réseau existe déjà depuis le TP2, voir la section 3.3 pour l'importer dans le state.
>
> **`docker_image "sentiment"`**
> - `name = "sentiment-ai:${var.image_tag}"` : référence l'image locale buildée par Jenkins - pas de `docker pull` depuis un registry distant, donc pas d'authentification nécessaire.
> - `keep_locally = true` : indique à Terraform de **ne pas supprimer l'image locale** lors d'un `terraform destroy`. Sans ce paramètre, `destroy` effacerait l'image de votre machine.
>
> **`docker_container "sentiment_staging"`**
> - `image = docker_image.sentiment.image_id` : référence l'**ID réel** de l'image (SHA256), pas son nom. Cela garantit que le conteneur utilise exactement l'image buildée, même si le tag `latest` a été réassigné entre-temps.
> - `restart = "unless-stopped"` : le conteneur redémarre automatiquement après un crash ou un reboot, sauf s'il a été arrêté manuellement.
> - `healthcheck` : Docker vérifie toutes les 30s que l'API répond sur `/health`. Après 3 échecs, le conteneur est marqué `unhealthy`.

---

### 2.4 Déclarer les outputs - `infra/outputs.tf`

```bash
cat > infra/outputs.tf << 'EOF'
# infra/outputs.tf

output "container_id" {
  description = "ID du conteneur staging"
  value       = docker_container.sentiment_staging.id
}

output "app_url" {
  description = "URL de l'application staging"
  value       = "http://localhost:${var.app_port}"
}

output "network_name" {
  description = "Nom du réseau Docker créé"
  value       = docker_network.cicd.name
}
EOF
```
![image](https://hackmd.io/_uploads/BkKBhaMzGx.png)


> **À quoi servent les outputs ?**
>
> Les outputs sont les **valeurs que Terraform expose après un `apply`**. Ils permettent de consulter rapidement les informations clés sans fouiller dans `terraform.tfstate`.
>
> Usages concrets :
> - `terraform output app_url` → affiche l'URL de staging dans les logs Jenkins.
> - `terraform output -raw container_id` → récupère l'ID dans un script shell.
> - Dans un pipeline CI/CD, le stage `Deploy Staging` peut utiliser `terraform output -raw app_url` pour construire l'URL de health check dynamiquement.

---

###  Question 2.1

Expliquez la ligne `image = docker_image.sentiment.image_id`. Pourquoi utiliser cette référence plutôt que le nom de l'image directement ?

**Réponse :** `docker_image.sentiment.image_id` référence le **SHA256 réel** de l'image, résolu par Terraform après avoir inspecté le daemon Docker. Utiliser directement `"sentiment-ai:latest"` serait une chaîne statique : si le tag `latest` est réassigné à une nouvelle image après le build, le conteneur pourrait pointer sur une version incorrecte. La référence par ID garantit la cohérence exacte.

###  Question 2.2

À quoi sert `keep_locally = true` sur la ressource `docker_image` ? Que se passerait-il sans ce paramètre lors d'un `terraform destroy` ?

**Réponse :** Sans `keep_locally = true`, un `terraform destroy` supprimerait l'image locale `sentiment-ai` de votre machine. L'image ayant été buildée par Jenkins (potentiellement long), la perdre obligerait à relancer un build complet. Ce paramètre protège l'image locale tout en permettant de détruire le conteneur.

---

## 3. Exécuter Terraform

> **Convention :** Toutes les commandes suivantes s'exécutent depuis le dossier `infra/`. Faites `cd infra/` une seule fois, ou utilisez `terraform -chdir=infra <commande>` depuis la racine du projet.

### 3.1 Initialiser le provider

```bash
cd infra/
terraform init
```

![image](https://hackmd.io/_uploads/HJ9i26fGMe.png)


> `terraform init` télécharge le provider `kreuzwerker/docker` dans `.terraform/` et crée `.terraform.lock.hcl` qui fixe la version exacte utilisée. C'est l'équivalent d'un `npm install` ou `pip install` pour Terraform.

---

### 3.2 Vérifier la syntaxe

```bash
# Formater les fichiers (style canonique HCL)
terraform fmt

# Valider la syntaxe sans contacter Docker
terraform validate
# Success! The configuration is valid.
```
![image](https://hackmd.io/_uploads/r1W166Gzfx.png)


> - `terraform fmt` : reformate les fichiers `.tf` selon le style officiel HCL (indentation, alignement). Idempotent - peut être intégré en pre-commit hook.
> - `terraform validate` : vérifie la **syntaxe et la cohérence** de la configuration (références valides, types corrects) sans aucun appel au daemon Docker. Rapide, utile en CI sur toutes les branches.

---

### 3.3 Prévisualiser les changements

```bash
terraform plan
```
![image](https://hackmd.io/_uploads/BJMGapMzfx.png)


> `terraform plan` calcule le **diff entre l'état désiré** (vos fichiers `.tf`) **et l'état actuel** (`.tfstate`). Il n'applique rien. C'est la commande à utiliser pour revue de code avant tout déploiement.

#### Réseau cicd-network déjà existant

Si `terraform apply` échoue avec `network with name cicd-network already exists` (créé manuellement au TP2/TP3), importez-le dans le state Terraform :

```bash
# Récupérer l'ID du réseau existant
docker network inspect cicd-network --format '{{.Id}}'

# Importer dans le state Terraform
terraform import docker_network.cicd <ID_DU_RESEAU>
```
![image](https://hackmd.io/_uploads/rk6Ba6fMGe.png)
![image](https://hackmd.io/_uploads/H1R_6TfGGg.png)


Si un conteneur `sentiment-staging` existe déjà :

```bash
docker stop sentiment-staging
docker rm sentiment-staging
```

---

### 3.4 Appliquer et tester l'idempotence

```bash
# Créer le réseau, télécharger l'image, démarrer le conteneur
terraform apply 
# Taper 'yes' pour confirmer, ou -auto-approve pour Jenkins
```
![image](https://hackmd.io/_uploads/BJa4ApGfze.png)


```bash
# Vérifier que le conteneur tourne
docker ps | grep sentiment-staging
```
![image](https://hackmd.io/_uploads/r1P8AaMMMg.png)

```bash
# Tester l'API
curl http://localhost:8001/health
```
![image](https://hackmd.io/_uploads/S1TDApGfMe.png)


```bash
# Afficher les outputs calculés
terraform output
```
![image](https://hackmd.io/_uploads/rJwcATMMze.png)

```bash
# Tester l'idempotence : relancer apply sans rien changer
terraform apply -auto-approve
# Résultat attendu : No changes. Your infrastructure matches the configuration.
```
![image](https://hackmd.io/_uploads/rySTCTzffe.png)


> **Idempotence** : appliquer la même configuration plusieurs fois produit toujours le même résultat. Terraform compare l'état désiré à l'état réel et **ne modifie que ce qui diffère**. En CI/CD, cela garantit que relancer un pipeline ne crée pas de ressources dupliquées ni ne perturbe un environnement déjà conforme.

---

###  Question 3.1

Faites un screenshot de `terraform plan` affichant les ressources à créer.

![image](https://hackmd.io/_uploads/SkV-JAzGzl.png)



###  Question 3.2

Faites un screenshot de `terraform apply` réussi et de `terraform output`.

![image](https://hackmd.io/_uploads/HJhGJCfGGx.png)
![image](https://hackmd.io/_uploads/BJImJRGGzx.png)

###  Question 3.3

Faites un screenshot du 2e `terraform apply` confirmant l'idempotence (`No changes`). Expliquez en une phrase ce que garantit ce comportement en CI/CD.

![image](https://hackmd.io/_uploads/SkzU1CzfMg.png)


**Réponse :** L'idempotence garantit qu'un pipeline peut être rejoué sans risque de créer des ressources dupliquées ou de perturber un environnement déjà dans l'état désiré.

###  Question 3.4

Inspectez `terraform.tfstate` : quelles informations y trouvez-vous sur le conteneur staging ? Pourquoi ce fichier ne doit-il pas être dans Git ?
![image](https://hackmd.io/_uploads/S1Pc1Cfffg.png)


**Réponse :** `terraform.tfstate` contient les IDs des ressources créées, les valeurs des attributs (ports, variables d'environnement, ID de réseau…) et potentiellement des secrets. Le commiter exposerait ces informations sensibles et créerait des conflits lors de travail en équipe (chaque `apply` modifie le fichier). En production, on utilise un backend distant (S3, Terraform Cloud) avec verrouillage.

---

## 4. Intégration Jenkins

### 4.1 Installer Terraform dans le conteneur Jenkins

Le conteneur Jenkins tourne toujours sur Linux, quelle que soit la machine hôte. La méthode fiable est le téléchargement direct du binaire officiel (le dépôt APT HashiCorp est souvent incompatible avec la distribution Debian embarquée) :

```bash
docker exec -u root jenkins bash -c "
  apt-get update -q &&
  apt-get install -y wget unzip &&
  wget https://releases.hashicorp.com/terraform/1.7.0/terraform_1.7.0_linux_amd64.zip &&
  unzip terraform_1.7.0_linux_amd64.zip &&
  mv terraform /usr/local/bin/ &&
  terraform version
"

# Vérifier
docker exec jenkins terraform version
```
![image](https://hackmd.io/_uploads/SyIwe0fzzx.png)
![image](https://hackmd.io/_uploads/ryZFgAMzMx.png)


> **Pourquoi `linux_amd64` même sur macOS ou Windows ?**
> Le binaire à télécharger est toujours la version Linux car c'est le **conteneur Jenkins** qui exécute Terraform, pas la machine hôte. Docker Desktop sur macOS et Windows fait tourner les conteneurs dans une VM Linux x86-64.

---



### 4.2 Jenkinsfile - Pipeline 10 stages complet

```bash
cat > Jenkinsfile << 'EOF'
pipeline {
  agent any

  environment {
    IMAGE_NAME = 'sentiment-ai'
    REGISTRY   = 'ghcr.io/dspitech'
    REGISTRY_IMAGE = "${REGISTRY}/${IMAGE_NAME}"
    SONAR_HOST_URL = 'http://4.223.165.64:9000/'
    SONAR_USER_TOKEN = 'sqa_5e07e6f28100271b73d2b76bcbc49d72e2bc70ee'
  }

  stages {
    stage('1. Checkout') { steps { checkout scm; script { env.IMAGE_TAG = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim() } } }
    stage('2. Lint') { steps { sh 'docker run --rm -v $WORKSPACE:/app -w /app python:3.12-slim sh -c "pip install flake8 -q && flake8 ."' } }
    stage('3. Build') { steps { sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ." } }
    stage('4. Test') { steps { sh "docker run --name test-runner ${IMAGE_NAME}:${IMAGE_TAG} pytest tests/ -v --cov=src --cov-report=xml:/tmp/coverage.xml --cov-fail-under=70" } }
    stage('5. Extract Coverage') { steps { sh "docker cp test-runner:/tmp/coverage.xml ./coverage.xml && docker rm -f test-runner" } }
    stage('6. Install Scanner') { steps { sh 'if [ ! -d "$HOME/.sonar/bin" ]; then mkdir -p $HOME/.sonar; curl -sSL https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip -o $HOME/.sonar/scanner.zip; unzip -q -o $HOME/.sonar/scanner.zip -d $HOME/.sonar/; mv $HOME/.sonar/sonar-scanner-5.0.1.3006-linux/* $HOME/.sonar/; rm $HOME/.sonar/scanner.zip; fi' } }
    stage('7. Sonar Analysis') { steps { sh '$HOME/.sonar/bin/sonar-scanner -Dsonar.host.url=$SONAR_HOST_URL -Dsonar.login=$SONAR_USER_TOKEN -Dsonar.projectKey=sentiment-ai -Dsonar.sources=src -Dsonar.python.coverage.reportPaths=coverage.xml' } }
    stage('8. Quality Gate') { steps { sh 'STATUS=$(curl -s -u "$SONAR_USER_TOKEN:" "${SONAR_HOST_URL}api/qualitygates/project_status?projectKey=sentiment-ai" | grep -o \'"status":"[^"]*"\'); if [ "$STATUS" = \'"status":"ERROR"\' ]; then exit 1; fi' } }
    stage('9. Push Image') { steps { sh 'docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${REGISTRY_IMAGE}:${IMAGE_TAG} && docker push ${REGISTRY_IMAGE}:${IMAGE_TAG}' } }
    
    stage('10. Deploy Terraform') {
      steps {
        script {
          sh """
            cat > deploy.sh << 'SCRIPT_EOF'
#!/bin/sh
# 1. On arrête et supprime le conteneur existant s'il tourne ou existe
if [ \$(docker ps -aq -f name=sentiment-staging) ]; then
    echo "Nettoyage : arrêt et suppression du conteneur existant..."
    docker rm -f sentiment-staging
fi

# 2. On exécute le déploiement Terraform
terraform init -upgrade
terraform apply -auto-approve
SCRIPT_EOF
            chmod +x deploy.sh

            docker build -t terraform-deploy -f- . <<DOCKERFILE
FROM hashicorp/terraform:latest
COPY infra/ /terraform/
COPY deploy.sh /terraform/
RUN rm -f /terraform/terraform.tfstate /terraform/terraform.tfstate.backup /terraform/.terraform.lock.hcl
WORKDIR /terraform
DOCKERFILE

            docker run --rm \
              --entrypoint /bin/sh \
              -v /var/run/docker.sock:/var/run/docker.sock \
              -v \${HOME}/.aws:/root/.aws \
              -e TF_VAR_image_tag=${IMAGE_TAG} \
              terraform-deploy /terraform/deploy.sh
          """
        }
      }
    }
  }
}
EOF
```
![image](https://hackmd.io/_uploads/rJPx3gmzMg.png)


#### Création du fichier deploy.sh

```bash
cat > deploy.sh << 'SCRIPT_EOF'
#!/bin/sh
terraform init -upgrade
terraform import docker_network.cicd $(docker network inspect cicd-network --format='{{.Id}}') 2>/dev/null || true
terraform apply -auto-approve
SCRIPT_EOF
```
![image](https://hackmd.io/_uploads/H16bhlQMGg.png)


> **IaC Validate vs IaC Apply - deux rôles distincts**
>
> | Stage | Branches | Commandes | Objectif |
> |---|---|---|---|
> | `IaC Validate` | Toutes | `fmt -check` + `validate` | Vérification syntaxique rapide en Fail Fast. `-backend=false` évite toute connexion distante. |
> | `IaC Apply` | `main` seulement | `apply -auto-approve` | Provisionne l'infra réelle avec l'image du commit exact. |
>
> **Pourquoi `-var='image_tag=${IMAGE_TAG}'` ?**
>
> `IMAGE_TAG` est le hash court du commit Git (`git rev-parse --short HEAD`). En passant ce tag à Terraform, on s'assure que le conteneur staging fait toujours tourner **exactement le code du commit qui vient de passer tous les tests**. C'est une amélioration de traçabilité majeure par rapport au TP3 où le tag `latest` ne permettait pas de savoir quelle version était déployée.


#### Test 
```bash
git add .
git commit -m "ci: deploy full pipeline with terraform integration"
git push origin main
```
![image](https://hackmd.io/_uploads/BkqtZCMGze.png)

---

###  Question 4.1

Faites un screenshot du pipeline Jenkins avec les 10 stages tous verts.

![image](https://hackmd.io/_uploads/BymunlXzMx.png)
![image](https://hackmd.io/_uploads/Byco2eQzzx.png)



###  Question 4.2

Pourquoi `IaC Validate` s'exécute sur toutes les branches mais `IaC Apply` seulement sur `main` ?

**Réponse :** `IaC Validate` est une vérification syntaxique légère (Fail Fast) : détecter une erreur HCL dès une feature branch évite de la découvrir sur `main`. `IaC Apply` provisionne de vraies ressources - le limiter à `main` garantit qu'on ne crée jamais d'environnement staging à partir d'un code non validé par la Quality Gate et non mergé.

###  Question 4.3

À quoi sert `-var='image_tag=${IMAGE_TAG}'` dans le stage `IaC Apply` ? En quoi cela améliore-t-il la traçabilité par rapport au TP3 ?

**Réponse :** Le hash court Git passé comme `image_tag` lie l'image déployée à un commit précis. Au TP3, le tag `latest` ne permettait pas de savoir quelle version tournait en staging ; ici, `docker inspect sentiment-staging` révèle immédiatement le commit correspondant.

---

## 5. Pour aller plus loin - Autres Environnements

Ce TP utilise le Docker provider pour apprendre Terraform sans compte cloud. En entreprise, le **même workflow** s'applique en changeant uniquement le provider.

### 5.1 Cloud public

| Provider | Service équivalent | Remplace | Coût |
|---|---|---|---|
| `provider "aws"` | ECS / EKS / EC2 | `docker_container` | Payant (Free Tier) |
| `provider "google"` | Cloud Run / GKE | `docker_container` | Payant (300$ crédit) |
| `provider "azurerm"` | ACI / AKS | `docker_container` | Payant (200$ crédit) |

Le changement est minimal : remplacer le bloc `provider "docker"` par `provider "aws"` et les ressources `docker_container` par des ressources `aws_ecs_service`.

### 5.2 Cloud local (self-hosted, sans frais)

| Outil | Description |
|---|---|
| **Minikube / Kind** | Cluster Kubernetes local. Le provider `kubernetes` Terraform provisionne pods, services et ingress. |
| **LocalStack** | Émule les services AWS (S3, EC2, Lambda, RDS) localement sur `http://localhost:4566`. |
| **k3s** | Distribution Kubernetes ultra-légère, installable en une commande. |
| **Vagrant + VirtualBox** | VMs locales via le provider `virtualbox`. Proche d'un environnement bare-metal. |

### 5.3 Adaptation de SentimentAI

Seuls 3 fichiers changent pour porter SentimentAI en production - le code applicatif et les TPs précédents restent intacts :

| Fichier | TP4 (Docker local) | Production (ex: AWS) |
|---|---|---|
| `infra/main.tf` | `provider "docker"` | `provider "aws"` |
| `infra/variables.tf` | `app_port = 8001` | `region = "eu-west-1"` |
| `Jenkinsfile` | `terraform apply` | `terraform apply` (inchangé) |

> **Principe fondamental :**
> Apprendre Terraform avec le Docker provider, c'est apprendre Terraform tout court. Le workflow `init → plan → apply`, les variables, les outputs et l'idempotence fonctionnent **exactement de la même façon** sur AWS, GCP, Azure ou Kubernetes. Seul le provider et les noms de ressources changent.

---

# TP 5- Monitoring & Observabilité

Exposer les métriques de SentimentAI et les visualiser dans Grafana  
**Outils :** Prometheus · Grafana · FastAPI · Jenkins · Terraform · Docker

---

## Objectif

Ajouter une couche d'observabilité complète à SentimentAI (déployé en staging via Terraform au TP4) :

1. L'API expose ses métriques sur `GET /metrics` (format Prometheus)
2. Prometheus scrape ces métriques automatiquement toutes les **15 secondes**
3. Grafana les visualise avec des dashboards en temps réel
4. Un smoke test Jenkins vérifie que tout fonctionne après chaque déploiement

---

## Prérequis

- SentimentAI déployé en staging (TP4, réseau `cicd-network` existant)
- Environnement virtuel Python actif (`source venv/bin/activate`)
- Docker et Docker Compose installés

---

## 1. Exposer les Métriques dans FastAPI

### 1.1 Installer les dépendances

Ajoutez ces lignes à `requirements.txt` :

```
cat <<EOF >> requirements.txt
prometheus-fastapi-instrumentator==6.1.0
prometheus-client==0.19.0
EOF
```
![image](https://hackmd.io/_uploads/SJmGb-7zGx.png)

- Corriger les permissions 

```bash
ls -ld ~/.local
sudo chown -R $USER:$USER ~/.local
```
![image](https://hackmd.io/_uploads/SJlzGZQMGl.png)

Puis installez :

```bash
pip install -r requirements.txt
```
![image](https://hackmd.io/_uploads/rJRrMbQzGg.png)


> **Vérification du venv**  
> Avant d'installer, assurez-vous que votre environnement virtuel est actif :
> ```bash
> which python3
> which pip
> # Les deux doivent pointer vers .venv/bin/... ou venv/bin/...
> # et NON vers un Python système (/usr/bin, /Library/Frameworks, anaconda3...)
> ```
![image](https://hackmd.io/_uploads/rkRdMW7GGg.png)

> Si ce n'est pas le cas : `source venv/bin/activate`

Pour que python3 et pip pointent vers votre dossier local de projet, vous devez créer et activer un environnement virtuel.

```bash
sudo apt update
sudo apt install python3.10-venv
python3 -m venv venv
source venv/bin/activate
```

### 1.2 Instrumenter l'application

Modifiez `src/main.py` pour exposer les métriques HTTP automatiquement et les métriques métier SentimentAI :

```bash
cat <<'EOF' > src/main.py
from fastapi import FastAPI
from prometheus_fastapi_instrumentator import Instrumentator
from prometheus_client import Counter, Gauge, Histogram
from src.schemas import PredictionRequest, PredictionResponse
from src.model import SentimentModel
import time

app = FastAPI(title="SentimentAI", version="0.1.0")
model = SentimentModel()

# Métriques métier SentimentAI
predictions_total = Counter(
    "sentiment_predictions_total",
    "Nombre total de prédictions",
    ["label", "status"]  # ex: label=POSITIVE, status=ok
)

confidence_gauge = Gauge(
    "sentiment_confidence_score",
    "Score de confiance de la dernière prédiction",
    ["label"]
)

prediction_duration = Histogram(
    "sentiment_prediction_duration_seconds",
    "Durée des prédictions en secondes",
    buckets=[0.01, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5]
)

# Instrumentation automatique HTTP (expose GET /metrics)
Instrumentator().instrument(app).expose(app)

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/predict", response_model=PredictionResponse)
def predict(request: PredictionRequest):
    start = time.time()
    try:
        result = model.predict(request.text)
        duration = time.time() - start
        predictions_total.labels(label=result["label"], status="ok").inc()
        confidence_gauge.labels(label=result["label"]).set(result["score"])
        prediction_duration.observe(duration)
        return result
    except Exception:
        predictions_total.labels(label="UNKNOWN", status="error").inc()
        raise
EOF
```
![image](https://hackmd.io/_uploads/S1SH4WmGfx.png)


> **Ce que fait `Instrumentator().instrument(app).expose(app)` :**  
> Ajoute automatiquement les métriques HTTP suivantes :
> - `http_requests_total{method, handler, status}` → Counter
> - `http_request_duration_seconds{method, handler}` → Histogram  
> Et expose `GET /metrics` au format texte Prometheus.  
> Les métriques métier (`predictions_total`, etc.) sont ajoutées **manuellement** pour mesurer la logique applicative spécifique à SentimentAI.

### 1.3 Tester l'exposition des métriques

```bash
# Lancer l'app localement
python3 -m uvicorn src.main:app --reload --port 8000

# En d'erreur :
pip install --upgrade pip
pip install -r requirements.txt
which uvicorn
```
![image](https://hackmd.io/_uploads/ryNMS-mMGe.png)


```bash
# Dans un autre terminal- vérifier /metrics
curl -s http://localhost:8000/metrics | grep sentiment
```
![image](https://hackmd.io/_uploads/HyEyUWXzGg.png)

```bash
# Envoyer une prédiction pour incrémenter les compteurs
curl -s -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "Excellent produit"}'
```
![image](https://hackmd.io/_uploads/r18MI-7GMx.png)
![image](https://hackmd.io/_uploads/B1GQLb7Mfx.png)

```bash
# Re-vérifier- le counter doit avoir augmenté
curl -s http://localhost:8000/metrics | grep sentiment_predictions_total
```
![image](https://hackmd.io/_uploads/B1iBIbmMGg.png)

---

### Questions- Section 1

#### Question 1.1
Faites un screenshot de `curl /metrics` montrant vos métriques `sentiment_predictions_total` et `sentiment_confidence_score`.

![image](https://hackmd.io/_uploads/Sk9_IbQGMx.png)


**Réponse :** Après avoir lancé l'app et envoyé au moins une requête `POST /predict`, la commande `curl -s http://localhost:8000/metrics | grep sentiment` doit retourner quelque chose comme :

```
# HELP sentiment_predictions_total Nombre total de prédictions
# TYPE sentiment_predictions_total counter
sentiment_predictions_total{label="POSITIVE",status="ok"} 1.0
# HELP sentiment_confidence_score Score de confiance de la dernière prédiction
# TYPE sentiment_confidence_score gauge
sentiment_confidence_score{label="POSITIVE"} 0.9876
```

*(Fournir un screenshot de ce résultat dans votre rendu.)*
![image](https://hackmd.io/_uploads/r1ijI-7Mfg.png)

---

#### Question 1.2
Quelle est la différence entre un **Counter** et un **Gauge** ? Donnez un exemple de chaque dans votre code.

**Réponse :**

| Type | Comportement | Exemple dans le code |
|------|-------------|----------------------|
| **Counter** | Valeur **monotone croissante**- elle ne peut qu'augmenter ou être remise à zéro au redémarrage du processus | `predictions_total` : compte le nombre total de prédictions effectuées depuis le démarrage de l'app |
| **Gauge** | Valeur **arbitraire**- elle peut monter ou descendre librement | `confidence_gauge` : reflète le score de confiance de la *dernière* prédiction, qui varie entre 0 et 1 |

En résumé : un Counter mesure un **cumul** (nombre d'événements), un Gauge mesure un **état instantané** (une valeur courante).

---

#### Question 1.3
À quoi sert le label `status='ok'` dans `predictions_total` ? Quel serait l'intérêt d'avoir aussi un `status='error'` ?

**Réponse :**

Le label `status='ok'` permet de **distinguer les prédictions réussies des prédictions en erreur** au sein d'un même counter. Cela évite d'avoir deux counters séparés et permet des requêtes PromQL comme :


Avoir `status='error'` est crucial pour :
- **Alerter** dès que le taux d'erreurs dépasse un seuil
- **Corréler** les erreurs avec des déploiements ou des pics de trafic
- **Séparer** les métriques de disponibilité des métriques de performance

Sans ce label, il serait impossible de différencier une prédiction réussie d'une exception dans les dashboards.

---

## 2. Installer Prometheus

### 2.1 Créer la configuration Prometheus

```bash
mkdir -p monitoring
touch monitoring/prometheus.yml monitoring/alerts.yml
```
![image](https://hackmd.io/_uploads/BkLDDbXMze.png)

**`monitoring/prometheus.yml` :**

```bash
cat <<'EOF' > monitoring/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - 'alerts.yml'

scrape_configs:
  - job_name: 'sentiment-ai'
    static_configs:
      - targets:
          - 'sentiment-staging:8000'  # nom DNS Docker
    metrics_path: /metrics

  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
EOF
```
![image](https://hackmd.io/_uploads/rJP3PbXGfl.png)


**`monitoring/alerts.yml` :**

```bash
cat <<'EOF' > monitoring/alerts.yml
groups:
  - name: sentimentai
    rules:
      - alert: HighLatency
        expr: |
          histogram_quantile(0.99,
            rate(sentiment_prediction_duration_seconds_bucket[5m])
          ) > 0.5
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: 'Latence p99 elevee sur SentimentAI'

      - alert: HighErrorRate
        expr: |
          rate(http_requests_total{status=~"5.."}[5m])
          / rate(http_requests_total[5m]) * 100 > 5
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Taux d'erreurs 5xx > 5%"

      - alert: LowConfidenceScore
        expr: avg(sentiment_confidence_score) < 0.85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: 'Modele peu confiant - verifier le drift'
EOF
```
![image](https://hackmd.io/_uploads/BkUZO-7zMx.png)


### 2.2 Lancer la stack monitoring

Créez `monitoring/docker-compose.yml` :

```bash
cat <<'EOF' > monitoring/docker-compose.yml
version: '3.9'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports: ['9090:9090']
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./alerts.yml:/etc/prometheus/alerts.yml:ro
      - prometheus_data:/prometheus
    networks: [cicd-network]
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.retention.time=15d'
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports: ['3000:3000']
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana_data:/var/lib/grafana
    networks: [cicd-network]
    restart: unless-stopped

networks:
  cicd-network:
    external: true  # créé par Terraform (TP4)

volumes:
  prometheus_data:
  grafana_data:
EOF
```
![image](https://hackmd.io/_uploads/Hy38ubXGGe.png)


**Note :** `monitoring/docker-compose.yml` est **indépendant** du `docker-compose.yml` de SentimentAI à la racine du projet. Les deux coexistent sans conflit (ports différents, réseau partagé via `external: true`). Ne modifiez pas le `docker-compose.yml` existant.

```bash
# Lancer la stack
cd monitoring/
docker compose up -d

# Vérifier
docker ps | grep -E 'prometheus|grafana'

# Accès :
# Prometheus : http://localhost:9090
# Grafana    : http://localhost:3000  (admin / admin)
```
![image](https://hackmd.io/_uploads/rJp5_WQGzx.png)
![image](https://hackmd.io/_uploads/SJOhOWXzMe.png)


### 2.3 Vérifier les targets Prometheus

**Attention :** Si le conteneur `sentiment-staging` a été créé par Terraform **avant** vos modifications de `src/main.py`, il faut rebuilder l'image et relancer Terraform :

```bash
# Rebuilder l'image avec le code à jour (incluant /metrics)
docker build -t sentiment-ai:latest .

# Recréer le conteneur staging avec la nouvelle image
cd infra/
terraform apply -auto-approve-auto-approve
```
![image](https://hackmd.io/_uploads/H1mS5-XGGx.png)
![image](https://hackmd.io/_uploads/SyFYFWmMGe.png)



**Symptôme si l'image n'est pas à jour :** Prometheus affiche `sentiment-ai DOWN` avec l'erreur `"server returned HTTP status 404 Not Found"` sur `http://sentiment-staging:8000/metrics`.

```bash
# Via l'API Prometheus- sentiment-ai doit être UP
curl -s http://localhost:9090/api/v1/targets | \
  python3 -m json.tool | grep health
# Résultat attendu : "health": "up"

# Tester une requête PromQL dans l'interface Prometheus
# http://localhost:9090 -> Graph -> Expression :
# rate(http_requests_total[1m])
```
![image](https://hackmd.io/_uploads/SyjWj-mGGx.png)
![image](https://hackmd.io/_uploads/SJtUoZ7Gfg.png)
![image](https://hackmd.io/_uploads/rkHPfGXGGg.png)


---

### Questions- Section 2

#### Question 2.1
> Faites un screenshot de `http://localhost:9090/targets` montrant `sentiment-ai` avec le statut **UP**.

**Réponse :** La page `/targets` de Prometheus liste tous les jobs configurés dans `prometheus.yml`. Le job `sentiment-ai` doit apparaître en vert avec `State: UP`. Si le statut est `DOWN`, vérifier que le conteneur `sentiment-staging` tourne bien avec l'endpoint `/metrics` exposé (cf. section 2.3).

*(Fournir un screenshot de cette page dans votre rendu.)*
![image](https://hackmd.io/_uploads/SJGmzfmfzg.png)

---

#### Question 2.2
Dans Prometheus (Graph), tapez `rate(http_requests_total[1m])`. Faites un screenshot du résultat après avoir envoyé quelques requêtes à `/predict`. Si le résultat est vide (`Empty query result`), qu'est-ce que cela signifie ?
![image](https://hackmd.io/_uploads/BytWQGXMzl.png)


**Réponse :**

Un résultat vide (`Empty query result`) signifie que **Prometheus n'a pas encore collecté de données** pour cette métrique. Les causes possibles sont :

- Le conteneur `sentiment-staging` n'a pas encore été scrappé (attendre le prochain cycle de 15 s)
- L'endpoint `/metrics` n'est pas accessible depuis Prometheus (target `DOWN`)
- Aucune requête n'a encore été envoyée à `/predict` (le counter `http_requests_total` n'existe pas encore car Prometheus n'expose les métriques qu'après le premier événement)

Solution : envoyer quelques requêtes `POST /predict`, attendre ~30 s, puis relancer la requête PromQL.

*(Fournir un screenshot du graphe avec des données dans votre rendu.)*

---

#### Question 2.3
> Pourquoi utilise-t-on `sentiment-staging:8000` comme target plutôt que `localhost:8000` ?

**Réponse :**

Prometheus tourne dans un **conteneur Docker** distinct. Dans ce contexte, `localhost` fait référence au réseau interne du conteneur Prometheus lui-même- pas à la machine hôte ni aux autres conteneurs.

`sentiment-staging` est le **nom DNS Docker** attribué au conteneur SentimentAI sur le réseau `cicd-network`. Docker fournit une résolution DNS interne entre conteneurs d'un même réseau, ce qui permet à Prometheus d'atteindre `sentiment-staging:8000` sans exposer le port sur la machine hôte.

C'est le principe fondamental des réseaux Docker : les conteneurs se parlent **par leur nom de service**, pas par `localhost`.

---

## 3. Configurer Grafana

### 3.1 Ajouter Prometheus comme datasource

1. Ouvrez `http://localhost:3000` → login `admin / admin`
2. Menu gauche → **Connections** → **Data sources** → **Add data source**
3. Choisir **Prometheus**
4. URL : `http://prometheus:9090` *(pas `localhost` !)*
5. Cliquer **Save & Test** → message vert *"Data source is working"*

![image](https://hackmd.io/_uploads/Bk7_4zmfGx.png)
![image](https://hackmd.io/_uploads/rk6pSGQzGl.png)
![image](https://hackmd.io/_uploads/ByPgIzmMMx.png)
![image](https://hackmd.io/_uploads/SJAzUzXGfx.png)


### 3.2 Créer le dashboard SentimentAI

**Étapes pour créer chaque panel :**

1. Menu gauche → **Dashboards** → bouton **New** → **New Dashboard**
2. Cliquer **Add visualization**
3. Sélectionner la datasource **Prometheus**
4. Dans l'éditeur de requête (onglet **Code**, pas Builder) : coller la requête PromQL
5. Le graphique se met à jour automatiquement
6. Dans le panneau **Panel options** (droite) : donner un titre au panel
7. Changer le type de visualisation si besoin (liste déroulante en haut à droite)
8. Cliquer **Apply** pour ajouter le panel
9. Répéter pour chacun des 4 panels
10. Cliquer **Save dashboard** (icône disquette)

![image](https://hackmd.io/_uploads/B1XrIMQffx.png)
![image](https://hackmd.io/_uploads/B1N8IMXGzg.png)
![image](https://hackmd.io/_uploads/HJVQwzXfGg.png)

**Les 4 panels à créer :**

| Panel | Type | Requête PromQL |
|-------|------|----------------|
| Requêtes/s | Time series | `rate(http_requests_total{handler="/predict"}[1m])` |
| Latence p99 | Time series | `histogram_quantile(0.99, rate(sentiment_prediction_duration_seconds_bucket[5m]))` |
| Taux erreurs | Stat | `rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) * 100` |
| Confiance | Gauge | `avg(sentiment_confidence_score)` |

> **Types de visualisation :**  
> - **Time series** → courbe dans le temps  
> - **Stat** → grande valeur unique  
> - **Gauge** → jauge circulaire ou linéaire

![image](https://hackmd.io/_uploads/HyqDFz7zzl.png)
![image](https://hackmd.io/_uploads/HkRkcM7fGx.png)
![image](https://hackmd.io/_uploads/r156cfXzfx.png)
![image](https://hackmd.io/_uploads/BkTR5fXMGe.png)

![image](https://hackmd.io/_uploads/SJH2qG7ffl.png)

### 3.3 Générer du trafic pour tester

```bash
# Envoyer 50 requêtes pour voir les métriques évoluer
for i in $(seq 1 50); do curl -s -X POST http://localhost:8000/predict -H "Content-Type: application/json" -d '{"text": "Ce produit est vraiment bien"}' > /dev/null; sleep 0.5; done
```
![image](https://hackmd.io/_uploads/r1KK6MXzMx.png)

![image](https://hackmd.io/_uploads/Sy4dTMXMzl.png)
![image](https://hackmd.io/_uploads/rkl3pMQzzg.png)

---

### Questions- Section 3

#### Question 3.1
Faites un screenshot de votre dashboard Grafana avec les 4 panels affichant des données.
![image](https://hackmd.io/_uploads/Syl6pfmMzl.png)


**Réponse :** Après avoir généré du trafic avec la boucle ci-dessus et attendu ~30 s, les 4 panels doivent afficher des données. Le panel **Requêtes/s** montre une courbe de trafic, **Latence p99** la latence au 99e percentile, **Taux erreurs** un pourcentage (idéalement 0 %), et **Confiance** une jauge avec le score moyen du modèle.


---

#### Question 3.2
Quelle est la requête PromQL pour calculer le percentile 99 de la latence ? Pourquoi utilise-t-on `histogram_quantile()` plutôt qu'un simple `avg()` ?

**Réponse :**

```promql
histogram_quantile(0.99, rate(sentiment_prediction_duration_seconds_bucket[5m]))
```

**Pourquoi `histogram_quantile()` et pas `avg()` ?**

`avg()` calcule la **moyenne** des durées, qui peut être très trompeuse : si 99 % des requêtes répondent en 50 ms mais 1 % met 10 s, la moyenne sera peut-être 150 ms- une valeur qui masque complètement le problème.

`histogram_quantile(0.99, ...)` calcule le **percentile 99** : la valeur en dessous de laquelle se trouvent 99 % des observations. C'est la métrique standard en SRE/DevOps car elle révèle l'expérience des **utilisateurs les plus lents**- ceux qui souffrent vraiment d'un problème de latence.

En résumé :
- `avg()` → performance *typique* (peut cacher les outliers)
- `histogram_quantile(0.99)` → performance dans le *pire cas plausible* (les 1 % les plus lents)

---

## 4. Intégration Jenkins- Pipeline 11 Stages

### 4.1 Provisionner le monitoring avec Terraform

Créez `infra/monitoring.tf` :

```bash
cat <<EOF > infra/monitoring.tf
resource "docker_image" "prometheus" {
  name         = "prom/prometheus:latest"
  keep_locally = true
}

resource "docker_container" "prometheus" {
  name    = "prometheus"
  image   = docker_image.prometheus.image_id
  restart = "unless-stopped"

  networks_advanced { name = docker_network.cicd.name }
  ports { internal = 9090; external = 9090 }

  volumes {
    host_path      = abspath("\${path.module}/../monitoring/prometheus.yml")
    container_path = "/etc/prometheus/prometheus.yml"
    read_only      = true
  }
}

resource "docker_image" "grafana" {
  name         = "grafana/grafana:latest"
  keep_locally = true
}

resource "docker_container" "grafana" {
  name    = "grafana"
  image   = docker_image.grafana.image_id
  restart = "unless-stopped"

  networks_advanced { name = docker_network.cicd.name }
  ports { internal = 3000; external = 3000 }
  env = ["GF_SECURITY_ADMIN_PASSWORD=admin"]
}
EOF

```
![image](https://hackmd.io/_uploads/ByAEAGmMMl.png)


### 4.2 Ajouter le stage Smoke Test dans le Jenkinsfile

Ajoutez ce **11e stage** après `Deploy Staging` :

```groovy
stage('Smoke Test') {
    when { branch 'main' }
    steps {
        sh '''
            echo "Attente démarrage (10s)..."
            sleep 10

            # 1. L'app répond
            curl -f http://localhost:8001/health || exit 1
            echo "/health OK"

            # 2. Les métriques sont exposées
            curl -s http://localhost:8001/metrics | \
              grep -q sentiment_predictions_total || exit 1
            echo "/metrics OK -- métriques SentimentAI présentes"

            # 3. Prometheus scrape l'app
            sleep 20  # attendre au moins 1 scrape (15s)
            curl -s "http://localhost:9090/api/v1/query?\
query=up{job='sentiment-ai'}" | \
              grep -q '"value":.*1' || exit 1
            echo "Prometheus scrape sentiment-ai : UP"

            # 4. Grafana répond
            curl -f http://localhost:3000/api/health || exit 1
            echo "Grafana OK"
        '''
    }
    post {
        failure {
            sh 'docker logs prometheus || true'
            sh 'docker logs sentiment-staging || true'
            echo 'Smoke Test KO -- voir logs ci-dessus'
        }
    }
}
```

#### Fichier Jenkinsfile

```bash
cat <<'EOF' > Jenkinsfile
pipeline {
  agent any

  environment {
    IMAGE_NAME = 'sentiment-ai'
    REGISTRY   = 'ghcr.io/dspitech'
    REGISTRY_IMAGE = "${REGISTRY}/${IMAGE_NAME}"
    SONAR_HOST_URL = 'http://4.223.165.64:9000/'
    SONAR_USER_TOKEN = 'sqa_5e07e6f28100271b73d2b76bcbc49d72e2bc70ee'
    DOCKER_HOST_IP  = '172.17.0.1'
  }

  stages {
    stage('1. Checkout') { steps { checkout scm; script { env.IMAGE_TAG = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim() } } }
    stage('2. Lint') { steps { sh 'docker run --rm -v $WORKSPACE:/app -w /app python:3.12-slim sh -c "pip install flake8 -q && flake8 ."' } }
    stage('3. Build') { steps { sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ." } }
    stage('4. Test') { steps { sh "docker run --name test-runner ${IMAGE_NAME}:${IMAGE_TAG} pytest tests/ -v --cov=src --cov-report=xml:/tmp/coverage.xml --cov-fail-under=70" } }
    stage('5. Extract Coverage') { steps { sh "docker cp test-runner:/tmp/coverage.xml ./coverage.xml && docker rm -f test-runner" } }
    stage('6. Install Scanner') { steps { sh 'if [ ! -d "$HOME/.sonar/bin" ]; then mkdir -p $HOME/.sonar; curl -sSL https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip -o $HOME/.sonar/scanner.zip; unzip -q -o $HOME/.sonar/scanner.zip -d $HOME/.sonar/; mv $HOME/.sonar/sonar-scanner-5.0.1.3006-linux/* $HOME/.sonar/; rm $HOME/.sonar/scanner.zip; fi' } }
    stage('7. Sonar Analysis') { steps { sh '$HOME/.sonar/bin/sonar-scanner -Dsonar.host.url=$SONAR_HOST_URL -Dsonar.login=$SONAR_USER_TOKEN -Dsonar.projectKey=sentiment-ai -Dsonar.sources=src -Dsonar.python.coverage.reportPaths=coverage.xml' } }
    stage('8. Quality Gate') { steps { sh 'STATUS=$(curl -s -u "$SONAR_USER_TOKEN:" "${SONAR_HOST_URL}api/qualitygates/project_status?projectKey=sentiment-ai" | grep -o \'"status":"[^"]*"\'); if [ "$STATUS" = \'"status":"ERROR"\' ]; then exit 1; fi' } }
    stage('9. Push Image') { steps { sh 'docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${REGISTRY_IMAGE}:${IMAGE_TAG} && docker push ${REGISTRY_IMAGE}:${IMAGE_TAG}' } }

    stage('10. Deploy Terraform') {
      steps {
        script {
          sh """
            docker build -t terraform-deploy -f- . <<DOCKERFILE
FROM hashicorp/terraform:latest
RUN apk add --no-cache docker-cli
COPY infra/      /terraform/
COPY monitoring/ /monitoring/
COPY deploy.sh   /terraform/
RUN rm -f /terraform/terraform.tfstate /terraform/terraform.tfstate.backup /terraform/.terraform.lock.hcl
WORKDIR /terraform
DOCKERFILE
            docker run --rm \\
              --entrypoint /bin/sh \\
              -v /var/run/docker.sock:/var/run/docker.sock \\
              -v \${HOME}/.aws:/root/.aws \\
              -e TF_VAR_image_tag=${IMAGE_TAG} \\
              terraform-deploy /terraform/deploy.sh
          """
        }
      }
    }

    stage('11. Smoke Test') {
      when { expression { env.GIT_BRANCH ==~ /.*main/ } }
      steps {
        sh '''
          echo "Attente démarrage (10s)..."
          sleep 10
          curl -f http://${DOCKER_HOST_IP}:8001/health || exit 1
          echo "/health OK"
          curl -s http://${DOCKER_HOST_IP}:8001/metrics | grep -q sentiment_predictions_total || exit 1
          echo "/metrics OK"
          sleep 20
          PROM_RESULT=$(curl -s "http://${DOCKER_HOST_IP}:9090/api/v1/query?query=up%7Bjob%3D%27sentiment-ai%27%7D")
          echo "Prometheus response: $PROM_RESULT"
          echo "$PROM_RESULT" | grep -q '"value"' || exit 1
          echo "Prometheus scrape OK"
          curl -f http://${DOCKER_HOST_IP}:3000/api/health || exit 1
          echo "Smoke Test OK : Tous les services sont opérationnels."
        '''
      }
      post {
        failure {
          sh 'docker logs prometheus || true'
          sh 'docker logs sentiment-staging || true'
        }
      }
    }
  }
}
EOF

```

> **Ports importants :**
> - `8080` → réservé à Jenkins (depuis TP2)
> - `8001` → SentimentAI staging (configuré dans `infra/variables.tf` au TP4)
> - `9090` → Prometheus
> - `3000` → Grafana

#### Fichier deploy.sh

```bash
cat > deploy.sh << 'EOF'
#!/bin/sh
docker rm -f sentiment-staging prometheus grafana 2>/dev/null || true
terraform init -upgrade
terraform apply -auto-approve
EOF
chmod +x deploy.sh
git add deploy.sh
git commit -m "fix: ensure deploy.sh removes containers"
git push
```

#### Fichier monitorign.fr

```bash
cat > infra/monitoring.tf << 'EOF'
resource "docker_image" "prometheus" {
  name         = "prom/prometheus:latest"
  keep_locally = true
}

resource "docker_container" "prometheus" {
  name    = "prometheus"
  image   = docker_image.prometheus.image_id
  restart = "unless-stopped"

  networks_advanced {
    name = data.docker_network.cicd.name
  }

  ports {
    internal = 9090
    external = 9090
  }

  volumes {
    host_path      = "/home/labadmin/sentiment-ai/monitoring/prometheus.yml"
    container_path = "/etc/prometheus/prometheus.yml"
    read_only      = true
  }

  volumes {
    host_path      = "/home/labadmin/sentiment-ai/monitoring/alerts.yml"
    container_path = "/etc/prometheus/alerts.yml"
    read_only      = true
  }
}

resource "docker_image" "grafana" {
  name         = "grafana/grafana:latest"
  keep_locally = true
}

resource "docker_container" "grafana" {
  name    = "grafana"
  image   = docker_image.grafana.image_id
  restart = "unless-stopped"

  networks_advanced {
    name = data.docker_network.cicd.name
  }

  ports {
    internal = 3000
    external = 3000
  }

  env = ["GF_SECURITY_ADMIN_PASSWORD=admin"]
}
EOF
```
#### Test 

```bash
cat <<EOF >> README.md

## Progression des TP
- [x] TP 1 à 5 : Terminés
EOF

git add .
git commit -m "docs : Final TP (1 à 5)"
git push origin main
```
![image](https://hackmd.io/_uploads/HJX9TQ7Mzg.png)

![image](https://hackmd.io/_uploads/ByOl2XQGGx.png)
![image](https://hackmd.io/_uploads/S1zG3XQfMx.png)
![image](https://hackmd.io/_uploads/HJAdTXXfze.png)

---

### Questions- Section 4

#### Question 4.1
Faites un screenshot du pipeline Jenkins avec les 11 stages tous verts.
![image](https://hackmd.io/_uploads/BJtzhX7GGg.png)


**Réponse :** Le pipeline doit afficher les 11 stages en vert dans la vue **Stage View** de Jenkins. Le stage **Smoke Test** (11e) doit être le dernier et passer avec les 4 vérifications (health, metrics, Prometheus UP, Grafana). En cas d'échec, les logs `docker logs prometheus` et `docker logs sentiment-staging` sont automatiquement affichés.



---

#### Question 4.2
Pourquoi le smoke test attend-il **20 secondes** avant de vérifier que Prometheus scrape l'app ? Que se passerait-il si on n'attendait pas ?

**Réponse :**

Le smoke test attend 20 s car Prometheus est configuré avec `scrape_interval: 15s`. Cela signifie que Prometheus collecte les métriques **toutes les 15 secondes**. Si on vérifiait immédiatement après le démarrage :

- Prometheus n'aurait pas encore eu le temps d'effectuer un premier scrape
- La métrique `up{job='sentiment-ai'}` ne serait pas encore présente dans la base de données de Prometheus
- La requête PromQL retournerait un résultat vide, et le `grep -q '"value":.*1'` échouerait

En attendant 20 s (légèrement plus que l'intervalle de 15 s), on garantit qu'**au moins un cycle de scrape** s'est écoulé et que Prometheus a pu confirmer que l'app est bien `UP`.

---

#### Question 4.3
Que se passe-t-il si le smoke test échoue à l'étape 3 (Prometheus scrape) ? Quels logs sont affichés dans Jenkins ?

**Réponse :**

Si l'étape 3 échoue (la valeur `up{job='sentiment-ai'}` n'est pas `1`) :

1. Le `exit 1` déclenche l'échec du stage `Smoke Test`
2. Jenkins marque le build en **FAILURE** (rouge)
3. Le bloc `post { failure { ... } }` s'exécute automatiquement et affiche dans la console Jenkins :
   - `docker logs prometheus` → logs de Prometheus (erreurs de configuration, échecs de scrape, etc.)
   - `docker logs sentiment-staging` → logs de SentimentAI (erreurs au démarrage, exceptions, etc.)
4. Le message `Smoke Test KO -- voir logs ci-dessus` est affiché

Les causes probables d'un tel échec : le conteneur `sentiment-staging` n'est pas démarré, l'endpoint `/metrics` n'est pas accessible depuis le réseau Docker, ou le nom DNS `sentiment-staging` ne résout pas correctement.

---

## Architecture finale du pipeline CI/CD

```
Git push
    │
    ▼
Jenkins (build + test + push)
    │
    ├── SonarQube  ──── Qualité du code
    ├── Trivy      ──── Sécurité des images
    │
    ▼
Terraform (IaC)
    │
    ├── sentiment-staging:8001  ──── API FastAPI
    ├── prometheus:9090         ──── Collecte métriques (15s)
    └── grafana:3000            ──── Dashboards temps réel
    │
    ▼
Smoke Test Jenkins
    ├── /health         ✓
    ├── /metrics        ✓
    ├── Prometheus UP   ✓
    └── Grafana UP      ✓
```

---




