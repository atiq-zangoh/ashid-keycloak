#!/bin/bash

# Git setup script for ashid-fastapi-auth repository
cd /Users/atiqmansoori/ashid-fastapi-auth

echo "Initializing git repository..."
git init

echo "Adding all files..."
git add .

echo "Creating initial commit..."
git commit -m "Initial commit: FastAPI Authentication Service with Vault integration

- Complete FastAPI application with user registration and JWT authentication
- HashiCorp Vault integration for secure token storage
- Keycloak integration for centralized authentication
- PostgreSQL database with Alembic migrations
- Redis for caching and rate limiting
- Docker Compose setup for local development
- Kubernetes manifests for production deployment
- Comprehensive API documentation
- Unit tests and security best practices
- Audit logging and token management"

echo "Adding remote repository..."
git remote add origin https://github.com/atiq-zangoh/ashid-fastapi-auth.git

echo "Creating and pushing to main branch..."
git branch -M main
git push -u origin main

echo "Done! Repository has been pushed to GitHub."
echo "You can view it at: https://github.com/atiq-zangoh/ashid-fastapi-auth"
