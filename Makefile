.PHONY: help build up down logs shell test migrate vault-init clean keycloak-setup keycloak-test

help:
	@echo "Available commands:"
	@echo "  make build       - Build Docker images"
	@echo "  make up          - Start all services"
	@echo "  make down        - Stop all services"
	@echo "  make logs        - View logs"
	@echo "  make shell       - Access app shell"
	@echo "  make test        - Run tests"
	@echo "  make migrate     - Run database migrations"
	@echo "  make vault-init  - Initialize Vault"
	@echo "  make clean       - Clean up volumes and containers"
	@echo "  make keycloak-setup - Setup Keycloak realm with users and roles"
	@echo "  make keycloak-test  - Test Keycloak realm authentication"

build:
	docker-compose build

up:
	docker-compose up -d

down:
	docker-compose down

logs:
	docker-compose logs -f

shell:
	docker-compose exec app /bin/bash

test:
	docker-compose exec app pytest tests/

migrate:
	docker-compose exec app alembic upgrade head

vault-init:
	docker-compose exec app ./scripts/init-vault.sh

clean:
	docker-compose down -v
	rm -rf postgres_data/ vault_data/ redis_data/

# Development commands
dev-install:
	pip install -r requirements.txt

dev-format:
	black app/

dev-lint:
	flake8 app/

dev-typecheck:
	mypy app/

# Database commands
db-shell:
	docker-compose exec postgres psql -U authuser -d authdb

db-reset:
	docker-compose exec app alembic downgrade base
	docker-compose exec app alembic upgrade head

# Generate new migration
db-migration:
	docker-compose exec app alembic revision --autogenerate -m "$(MSG)"

# Keycloak commands
keycloak-setup:
	@echo "Setting up Keycloak realm..."
	./scripts/setup-keycloak-realm.sh

keycloak-test:
	@echo "Testing Keycloak realm..."
	./scripts/test-keycloak-realm.sh

keycloak-update-roles:
	@echo "Updating Keycloak roles..."
	./scripts/update-keycloak-roles.sh
