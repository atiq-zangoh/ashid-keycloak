# FastAPI Authentication Service Setup Guide

## Prerequisites

- Docker and Docker Compose
- Python 3.11+
- PostgreSQL client (for migrations)
- Keycloak instance running (from the previous setup)

## Quick Start

### 1. Clone and Setup

```bash
git clone https://github.com/atiq-zangoh/ashid-fastapi-auth.git
cd ashid-fastapi-auth
```

### 2. Environment Configuration

```bash
cp .env.example .env
# Edit .env with your configuration
# Make sure to update:
# - Database passwords
# - Secret keys
# - Keycloak configuration
# - Vault token
```

### 3. Start Services

```bash
# Start all services
docker-compose up -d

# Check logs
docker-compose logs -f
```

### 4. Initialize Vault

```bash
# Make script executable
chmod +x scripts/init-vault.sh

# Initialize Vault
docker-compose exec app ./scripts/init-vault.sh

# Update .env with the generated Vault token
```

### 5. Run Database Migrations

```bash
# Generate initial migration
chmod +x scripts/generate-migration.sh
docker-compose exec app ./scripts/generate-migration.sh

# Run migrations
chmod +x scripts/run-migrations.sh
docker-compose exec app ./scripts/run-migrations.sh
```

### 6. Access the Application

- API Documentation: http://localhost:8000/docs
- Alternative Docs: http://localhost:8000/redoc
- Health Check: http://localhost:8000/health
- Vault UI: http://localhost:8200 (Token: myroot)

## API Usage Examples

### Register a New User

```bash
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "username": "johndoe",
    "password": "SecurePass123!",
    "full_name": "John Doe"
  }'
```

### Login

```bash
curl -X POST http://localhost:8000/api/v1/auth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=johndoe&password=SecurePass123!"
```

### Use Access Token

```bash
# Get current user info
curl -X GET http://localhost:8000/api/v1/users/me \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### Refresh Token

```bash
curl -X POST http://localhost:8000/api/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{
    "refresh_token": "YOUR_REFRESH_TOKEN"
  }'
```

### Validate Token

```bash
curl -X GET http://localhost:8000/api/v1/auth/validate?token=YOUR_TOKEN
```

### Revoke Token

```bash
curl -X POST http://localhost:8000/api/v1/auth/revoke \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "token": "TOKEN_TO_REVOKE",
    "reason": "User logout"
  }'
```

## Vault Integration

### View Stored Tokens

1. Access Vault UI: http://localhost:8200
2. Login with token: myroot
3. Navigate to: secret/auth-tokens/
4. Tokens are organized by user_id/jti

### Token Structure in Vault

```json
{
  "jti": "unique-token-id",
  "type": "access",
  "exp": 1234567890,
  "token": "actual.jwt.token",
  "stored_at": "2024-01-01T00:00:00",
  "user_id": 1,
  "revoked": false,
  "revoked_at": null
}
```

## Production Deployment

### Build Docker Image

```bash
docker build -t ashid-auth-service:latest .
```

### Deploy to Kubernetes

```bash
# Apply configurations
kubectl apply -f k8s/dependencies.yaml
kubectl apply -f k8s/deployment.yaml

# Check deployment
kubectl get pods -n auth-service
kubectl logs -n auth-service -l app=auth-service
```

### Configure Production Secrets

```bash
# Edit k8s/deployment.yaml
# Update all secret values
# Use proper secret management (e.g., Sealed Secrets, External Secrets)
```

## Security Considerations

1. **Password Requirements**
   - Minimum 8 characters
   - At least one uppercase letter
   - At least one lowercase letter
   - At least one digit

2. **Token Security**
   - Access tokens expire in 30 minutes
   - Refresh tokens expire in 7 days
   - All tokens stored encrypted in Vault
   - Token revocation tracked in database

3. **Rate Limiting**
   - Registration: 5 requests/minute
   - Login: 10 requests/minute
   - Other endpoints: 60 requests/minute

4. **Audit Logging**
   - All authentication events logged
   - IP addresses and user agents tracked
   - Success/failure status recorded

## Monitoring

### Health Endpoints

- `/health` - Basic health check
- `/metrics` - Prometheus metrics

### Logs

```bash
# Application logs
docker-compose logs -f app

# Database logs
docker-compose logs -f postgres

# Vault logs
docker-compose logs -f vault
```

## Troubleshooting

### Database Connection Issues

```bash
# Check database is running
docker-compose ps postgres

# Test connection
docker-compose exec postgres psql -U authuser -d authdb
```

### Vault Connection Issues

```bash
# Check Vault status
curl http://localhost:8200/v1/sys/health

# Verify token
docker-compose exec app vault token lookup
```

### Migration Issues

```bash
# Reset database
docker-compose down -v
docker-compose up -d postgres
docker-compose exec app alembic upgrade head
```

## Development

### Run Tests

```bash
# Install test dependencies
pip install -r requirements.txt

# Run tests
pytest tests/

# Run with coverage
pytest --cov=app tests/
```

### Code Quality

```bash
# Format code
black app/

# Lint
flake8 app/

# Type checking
mypy app/
```
