# Keycloak Setup Guide for Ashid Project

This guide explains how to set up the Keycloak realm with custom configuration for the Ashid project.

## Overview

The Keycloak setup includes:
- **Realm**: `ashid-dev`
- **Client**: `ashid-client` 
- **Roles**: `ashi_admin`, `customer`, `retailer`
- **Default Users**: 4 users with assigned roles

## Quick Setup

### 1. Start Services
```bash
make up
```

### 2. Setup Keycloak Realm (Method 1: Automatic Import)
The realm will be automatically imported when Keycloak starts with the `--import-realm` flag.

### 3. Setup Keycloak Realm (Method 2: Manual Script)
```bash
make keycloak-setup
```

### 4. Test the Setup
```bash
make keycloak-test
```

## Configuration Details

### Realm Configuration
- **Name**: `ashid-dev`
- **Display Name**: "Ashid Development"
- **Registration**: Disabled
- **Email Login**: Enabled
- **Remember Me**: Enabled
- **Email Verification**: Disabled
- **Required Actions**: None (as requested)

### Client Configuration
- **Client ID**: `ashid-client`
- **Client Secret**: `ashid-client-secret`
- **Protocol**: `openid-connect`
- **Access Type**: Confidential
- **Direct Access Grants**: Enabled
- **Service Accounts**: Enabled
- **Standard Flow**: Enabled

### Roles
1. **ashi_admin** - Administrator role with full access
2. **customer** - Customer role for end users  
3. **retailer** - Retailer role for business partners

### Default Users

| Username | Email | Password | Role | Full Name |
|----------|-------|----------|------|-----------|
| admin | admin@ashid.com | admin123 | ashi_admin | System Administrator |
| customer1 | customer1@ashid.com | customer123 | customer | John Doe |
| customer2 | customer2@ashid.com | customer123 | customer | Jane Smith |
| retailer1 | retailer1@ashid.com | retailer123 | retailer | Mike Johnson |

## Manual Setup Steps

If you need to set up manually through the Keycloak admin console:

### 1. Access Keycloak Admin Console
- URL: http://localhost:8080/admin
- Username: `admin`
- Password: `admin`

### 2. Create Realm
1. Click "Add realm"
2. Name: `ashid-dev`
3. Enable the realm

### 3. Create Client
1. Go to Clients → Create
2. Client ID: `ashid-client`
3. Client Protocol: `openid-connect`
4. Save and configure:
   - Access Type: `confidential`
   - Direct Access Grants Enabled: `ON`
   - Service Accounts Enabled: `ON`

### 4. Create Roles
1. Go to Roles → Add Role
2. Create three roles: `ashi_admin`, `customer`, `retailer`

### 5. Create Users
1. Go to Users → Add user
2. Create 4 users as per the table above
3. Set passwords in Credentials tab (temporary: OFF)
4. Assign roles in Role Mappings tab

## Testing Authentication

### Using cURL
```bash
# Test admin user
curl -X POST "http://localhost:8080/realms/ashid-dev/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin" \
  -d "password=admin123" \
  -d "grant_type=password" \
  -d "client_id=ashid-client" \
  -d "client_secret=ashid-client-secret"

# Test customer user
curl -X POST "http://localhost:8080/realms/ashid-dev/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=customer1" \
  -d "password=customer123" \
  -d "grant_type=password" \
  -d "client_id=ashid-client" \
  -d "client_secret=ashid-client-secret"
```

### Using Test Script
```bash
./scripts/test-keycloak-realm.sh
```

## Application Integration

The FastAPI application is configured to use:
- **Realm**: `ashid-dev`
- **Client ID**: `ashid-client`
- **Client Secret**: `ashid-client-secret`

Configuration is set in `.env` file:
```
KEYCLOAK_REALM=ashid-dev
KEYCLOAK_CLIENT_ID=ashid-client
KEYCLOAK_CLIENT_SECRET=ashid-client-secret
```

## URLs

- **Keycloak Admin Console**: http://localhost:8080/admin
- **Realm Info**: http://localhost:8080/realms/ashid-dev
- **Token Endpoint**: http://localhost:8080/realms/ashid-dev/protocol/openid-connect/token
- **User Account Console**: http://localhost:8080/realms/ashid-dev/account

## Troubleshooting

### Realm Not Found
If you get "realm not found" errors:
1. Check if Keycloak is running: `docker compose ps`
2. Verify realm import: `docker compose logs keycloak`
3. Run manual setup: `make keycloak-setup`

### Authentication Fails
1. Verify user credentials in Keycloak admin console
2. Check if realm roles are assigned to users
3. Ensure client secret is correct

### Application Can't Connect
1. Check `KEYCLOAK_URL` in docker-compose.yml (should be `http://keycloak:8080`)
2. Verify network connectivity between containers
3. Check application logs: `docker compose logs app`

## Next Steps

After setting up Keycloak:
1. Test authentication with all user types
2. Integrate role-based access control in your FastAPI application
3. Configure additional client scopes if needed
4. Set up proper production configuration for deployment