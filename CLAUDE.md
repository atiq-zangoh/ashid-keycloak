# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Docker-based Development (Recommended)
```bash
# Start all services
make up

# Run tests
make test

# View logs
make logs

# Access application shell
make shell

# Run database migrations
make migrate

# Initialize Vault
make vault-init

# Stop services
make down

# Clean up (removes volumes)
make clean
```

### Direct Python Development
```bash
# Install dependencies
pip install -r requirements.txt

# Format code
make dev-format  # or: black app/

# Lint code
make dev-lint    # or: flake8 app/

# Type checking
make dev-typecheck  # or: mypy app/

# Run tests locally
pytest tests/
```

### Database Operations
```bash
# Generate new migration
make db-migration MSG="description of changes"
# or: docker-compose exec app alembic revision --autogenerate -m "message"

# Reset database (careful!)
make db-reset

# Access database shell
make db-shell
```

## Architecture Overview

This is a FastAPI-based authentication service with the following key components:

### Core Services Integration
- **FastAPI**: Main web framework with automatic OpenAPI docs
- **PostgreSQL**: Primary database for user data and audit logs
- **HashiCorp Vault**: Secure storage for JWT tokens (encrypted)
- **Redis**: Caching layer for rate limiting and sessions
- **Keycloak**: External identity provider integration

### Application Structure
```
app/
├── api/v1/           # API endpoints (auth, users)
├── core/             # Configuration and security utilities
├── crud/             # Database operations layer
├── db/               # Database models and connection
├── schemas/          # Pydantic models for request/response
└── services/         # Business logic (keycloak, vault)
```

### Key Security Features
- JWT tokens with RS256 algorithm
- Tokens stored encrypted in Vault (path: `secret/auth-tokens/`)
- Rate limiting on all endpoints
- Password hashing with bcrypt
- Token revocation tracking
- Audit logging for all auth events

### Environment Configuration
- Copy `.env.example` to `.env` before development
- All services configured via environment variables
- See `app/core/config.py` for all settings

### Testing Strategy
- Tests located in `tests/` directory
- Uses pytest with asyncio support
- Test database isolation
- API endpoint testing with httpx

### Deployment
- Docker Compose for local development
- Kubernetes manifests in `k8s/` directory
- Multi-stage Dockerfile for production builds
- Health checks at `/health` and metrics at `/metrics`

## Development Workflow

1. **Initial Setup**: Run `make up` to start all services
2. **Vault Setup**: Run `make vault-init` and update `.env` with new token
3. **Database**: Run `make migrate` to apply database schema
4. **Development**: Code changes auto-reload in Docker container
5. **Testing**: Use `make test` for containerized tests
6. **Code Quality**: Run `make dev-format`, `make dev-lint`, `make dev-typecheck`

## Important Notes

- Always use the Makefile commands for consistency
- Vault integration requires initialization script on first run
- Database migrations use Alembic - never modify migration files directly
- All JWT tokens are stored encrypted in Vault for security
- Rate limiting is enforced on authentication endpoints
- The service integrates with external Keycloak for identity management