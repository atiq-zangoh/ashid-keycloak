# Ashid FastAPI Authentication Service

A FastAPI-based authentication service with user registration, JWT token generation, and HashiCorp Vault integration for secure token storage.

## Features

- User registration with password hashing
- JWT token generation with Keycloak integration
- Token storage in HashiCorp Vault
- Token validation and refresh
- Rate limiting and security headers
- PostgreSQL database for user storage
- Docker and Kubernetes deployment ready

## Quick Start

### Local Development

1. Clone the repository:
```bash
git clone https://github.com/atiq-zangoh/ashid-fastapi-auth.git
cd ashid-fastapi-auth
```

2. Copy environment variables:
```bash
cp .env.example .env
# Edit .env with your configuration
```

3. Start services:
```bash
docker-compose up -d
```

4. Run migrations:
```bash
docker-compose exec app alembic upgrade head
```

5. Access the API:
- API Documentation: http://localhost:8000/docs
- Alternative Docs: http://localhost:8000/redoc
- Health Check: http://localhost:8000/health

## API Endpoints

### Authentication
- `POST /api/v1/auth/register` - Register new user
- `POST /api/v1/auth/token` - Generate access token
- `POST /api/v1/auth/refresh` - Refresh access token
- `POST /api/v1/auth/revoke` - Revoke token
- `GET /api/v1/auth/validate` - Validate token

### User Management
- `GET /api/v1/users/me` - Get current user info
- `PUT /api/v1/users/me` - Update user profile
- `POST /api/v1/users/change-password` - Change password

## Architecture

```
ashid-fastapi-auth/
├── app/
│   ├── api/           # API endpoints
│   ├── core/          # Core configurations
│   ├── crud/          # Database operations
│   ├── db/            # Database models
│   ├── schemas/       # Pydantic schemas
│   ├── services/      # Business logic
│   └── utils/         # Utility functions
├── migrations/        # Alembic migrations
├── tests/            # Test cases
├── docker-compose.yml
└── Dockerfile
```

## Environment Variables

See `.env.example` for all configuration options.

## Security

- Passwords hashed with bcrypt
- JWT tokens with RS256 algorithm
- Tokens stored encrypted in Vault
- Rate limiting on auth endpoints
- CORS configuration
- Security headers

## License

[Your License]
