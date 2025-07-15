.PHONY: help build up down logs shell test migrate vault-init clean

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
