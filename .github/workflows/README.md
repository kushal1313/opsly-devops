# CI/CD Pipeline Documentation

## Overview

Automated CI/CD pipeline for the AI Chatbot Framework using GitHub Actions. The pipeline handles testing, building, and deploying containerized applications to AWS EKS via ArgoCD.

## Architecture

```
Source Code → Tests → Build Images → Update GitOps → ArgoCD Sync
```

## Pipeline Jobs

### 1. Determine Target Environment
- Determines target environment (dev/prod) based on branch or manual input
- Generates image tags with timestamp and commit SHA
- Sets appropriate values file path

### 2. Backend Tests
- Runs Python linting (pylint)
- Executes unit tests with coverage
- Uploads coverage reports to Codecov
- Uses pip caching for faster builds

### 3. Frontend Tests
- Runs Node.js linting
- Executes unit tests with coverage
- Builds frontend for production validation
- Uses npm caching for faster builds

### 4. Build and Push Docker Images
- Builds backend and frontend Docker images in parallel
- Uses Docker Buildx with registry caching
- Pushes images to ECR with versioned and latest tags
- Only runs on push events (not PRs)

### 5. Update GitOps Repository
- Updates Helm values files with new image tags
- Validates YAML syntax
- Commits changes with descriptive messages
- Only runs on push events

### 6. Trigger ArgoCD Sync
- Connects to EKS cluster
- Authenticates with ArgoCD
- Triggers application sync for dev environment
- Monitors sync status
- Only runs for dev environment

## Environment Configuration

### Environments
- **dev**: Triggered from `develop` branch, auto-syncs ArgoCD
- **prod**: Triggered from `main` branch, manual ArgoCD sync required

### Image Tagging Strategy
- Format: `{environment}-{timestamp}-{commit-sha}`
- Example: `dev-20241215-143022-a1b2c3d4`
- Latest tag also pushed for convenience

## Required Secrets

Configure the following secrets in GitHub repository settings:

| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | AWS access key for ECR and EKS access |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key |
| `EKS_CLUSTER_NAME` | Name of the EKS cluster |
| `GITOPS_REPO_TOKEN` | GitHub token with write access to GitOps repository |

## Workflow Triggers

- **Push to `main` or `develop`**: Full pipeline execution
- **Pull Request**: Test jobs only (no builds/deployments)
- **Manual (`workflow_dispatch`)**: Full pipeline with environment selection

## Performance Optimizations

- Parallel test execution (backend and frontend)
- Docker layer caching via ECR
- Dependency caching (pip, npm)
- Conditional job execution based on event type

## Error Handling

- Tests fail fast on errors
- Build failures prevent deployment
- GitOps updates validated before commit
- ArgoCD sync monitored with timeout

## Monitoring

- Test coverage reports uploaded to Codecov
- Build status visible in GitHub Actions UI
- ArgoCD application status displayed after sync
