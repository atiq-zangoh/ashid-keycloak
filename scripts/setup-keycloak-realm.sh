#!/bin/bash

# Setup Keycloak realm for Ashid project
# This script creates the ashid-dev realm with required clients, roles, and users

set -e

KEYCLOAK_URL="http://localhost:8080"
ADMIN_USER="admin"
ADMIN_PASS="admin"
REALM_NAME="ashid-dev"
CLIENT_ID="ashid-client"

echo "🚀 Setting up Keycloak realm: $REALM_NAME"

# Wait for Keycloak to be ready
echo "⏳ Waiting for Keycloak to be ready..."
while ! curl -s "$KEYCLOAK_URL/realms/master" > /dev/null; do
    echo "Waiting for Keycloak..."
    sleep 2
done

echo "✅ Keycloak is ready!"

# Get admin access token
echo "🔑 Getting admin access token..."
ADMIN_TOKEN=$(curl -s -X POST "$KEYCLOAK_URL/realms/master/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=$ADMIN_USER" \
    -d "password=$ADMIN_PASS" \
    -d "grant_type=password" \
    -d "client_id=admin-cli" | jq -r '.access_token')

if [ "$ADMIN_TOKEN" = "null" ] || [ -z "$ADMIN_TOKEN" ]; then
    echo "❌ Failed to get admin token"
    exit 1
fi

echo "✅ Got admin token"

# Create realm
echo "🏗️  Creating realm: $REALM_NAME"
curl -s -X POST "$KEYCLOAK_URL/admin/realms" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "realm": "'$REALM_NAME'",
        "enabled": true,
        "displayName": "Ashid Development",
        "displayNameHtml": "<strong>Ashid Development</strong>",
        "registrationAllowed": false,
        "loginWithEmailAllowed": true,
        "duplicateEmailsAllowed": false,
        "rememberMe": true,
        "verifyEmail": false,
        "loginTheme": "keycloak",
        "accountTheme": "keycloak",
        "adminTheme": "keycloak",
        "emailTheme": "keycloak",
        "requiredActions": [],
        "passwordPolicy": "length(8)",
        "accessTokenLifespan": 1800,
        "accessTokenLifespanForImplicitFlow": 900,
        "ssoSessionIdleTimeout": 1800,
        "ssoSessionMaxLifespan": 36000,
        "offlineSessionIdleTimeout": 2592000,
        "accessCodeLifespan": 60,
        "accessCodeLifespanUserAction": 300,
        "accessCodeLifespanLogin": 1800
    }' || echo "Realm might already exist"

echo "✅ Realm created/verified"

# Create client
echo "🔧 Creating client: $CLIENT_ID"
curl -s -X POST "$KEYCLOAK_URL/admin/realms/$REALM_NAME/clients" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "clientId": "'$CLIENT_ID'",
        "name": "Ashid Client",
        "description": "Main client for Ashid application",
        "enabled": true,
        "clientAuthenticatorType": "client-secret",
        "secret": "ashid-client-secret",
        "redirectUris": ["*"],
        "webOrigins": ["*"],
        "bearerOnly": false,
        "consentRequired": false,
        "standardFlowEnabled": true,
        "implicitFlowEnabled": false,
        "directAccessGrantsEnabled": true,
        "serviceAccountsEnabled": true,
        "publicClient": false,
        "frontchannelLogout": false,
        "protocol": "openid-connect",
        "attributes": {
            "access.token.lifespan": "1800",
            "client.secret.creation.time": "1642000000"
        },
        "fullScopeAllowed": true
    }' || echo "Client might already exist"

echo "✅ Client created/verified"

# Create realm roles
echo "👥 Creating realm roles..."

# retailer_admin role
curl -s -X POST "$KEYCLOAK_URL/admin/realms/$REALM_NAME/roles" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "retailer_admin",
        "description": "Retailer Administrator with store management permissions",
        "composite": false,
        "clientRole": false,
        "containerId": "'$REALM_NAME'"
    }' || echo "Role retailer_admin might already exist"

# ashi_sales_representative role
curl -s -X POST "$KEYCLOAK_URL/admin/realms/$REALM_NAME/roles" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "ashi_sales_representative",
        "description": "ASHI Sales Representative managing sales operations",
        "composite": false,
        "clientRole": false,
        "containerId": "'$REALM_NAME'"
    }' || echo "Role ashi_sales_representative might already exist"

# sales_associate role
curl -s -X POST "$KEYCLOAK_URL/admin/realms/$REALM_NAME/roles" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "sales_associate",
        "description": "Sales Associate handling day-to-day sales",
        "composite": false,
        "clientRole": false,
        "containerId": "'$REALM_NAME'"
    }' || echo "Role sales_associate might already exist"

# purchasing_manager role
curl -s -X POST "$KEYCLOAK_URL/admin/realms/$REALM_NAME/roles" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "purchasing_manager",
        "description": "Purchasing Manager overseeing procurement",
        "composite": false,
        "clientRole": false,
        "containerId": "'$REALM_NAME'"
    }' || echo "Role purchasing_manager might already exist"

# accounting_manager role
curl -s -X POST "$KEYCLOAK_URL/admin/realms/$REALM_NAME/roles" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "accounting_manager",
        "description": "Accounting Manager handling financial operations",
        "composite": false,
        "clientRole": false,
        "containerId": "'$REALM_NAME'"
    }' || echo "Role accounting_manager might already exist"

# marketing_manager role
curl -s -X POST "$KEYCLOAK_URL/admin/realms/$REALM_NAME/roles" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "marketing_manager",
        "description": "Marketing Manager managing promotional activities",
        "composite": false,
        "clientRole": false,
        "containerId": "'$REALM_NAME'"
    }' || echo "Role marketing_manager might already exist"

echo "✅ Roles created/verified"

# Create users
echo "👤 Creating default users..."

# Admin user
echo "Creating admin user..."
ADMIN_USER_ID=$(curl -s -X POST "$KEYCLOAK_URL/admin/realms/$REALM_NAME/users" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "username": "admin",
        "email": "admin@ashid.com",
        "firstName": "System",
        "lastName": "Administrator",
        "enabled": true,
        "emailVerified": true,
        "requiredActions": [],
        "credentials": [{
            "type": "password",
            "value": "admin123",
            "temporary": false
        }]
    }' -w '%{http_code}' -o /dev/null)

# Customer users
echo "Creating customer users..."
curl -s -X POST "$KEYCLOAK_URL/admin/realms/$REALM_NAME/users" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "username": "customer1",
        "email": "customer1@ashid.com",
        "firstName": "John",
        "lastName": "Doe",
        "enabled": true,
        "emailVerified": true,
        "requiredActions": [],
        "credentials": [{
            "type": "password",
            "value": "customer123",
            "temporary": false
        }]
    }' || echo "Customer1 might already exist"

curl -s -X POST "$KEYCLOAK_URL/admin/realms/$REALM_NAME/users" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "username": "customer2",
        "email": "customer2@ashid.com",
        "firstName": "Jane",
        "lastName": "Smith",
        "enabled": true,
        "emailVerified": true,
        "requiredActions": [],
        "credentials": [{
            "type": "password",
            "value": "customer123",
            "temporary": false
        }]
    }' || echo "Customer2 might already exist"

# Retailer user
echo "Creating retailer user..."
curl -s -X POST "$KEYCLOAK_URL/admin/realms/$REALM_NAME/users" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "username": "retailer1",
        "email": "retailer1@ashid.com",
        "firstName": "Mike",
        "lastName": "Johnson",
        "enabled": true,
        "emailVerified": true,
        "requiredActions": [],
        "credentials": [{
            "type": "password",
            "value": "retailer123",
            "temporary": false
        }]
    }' || echo "Retailer1 might already exist"

echo "✅ Users created/verified"

# Assign roles to users
echo "🎭 Assigning roles to users..."

# Function to get user ID
get_user_id() {
    local username=$1
    curl -s -G "$KEYCLOAK_URL/admin/realms/$REALM_NAME/users" \
        -H "Authorization: Bearer $ADMIN_TOKEN" \
        -d "username=$username" | jq -r '.[0].id'
}

# Function to get role
get_role() {
    local role_name=$1
    curl -s "$KEYCLOAK_URL/admin/realms/$REALM_NAME/roles/$role_name" \
        -H "Authorization: Bearer $ADMIN_TOKEN"
}

# Assign retailer_admin role to admin user
ADMIN_USER_ID=$(get_user_id "admin")
ADMIN_ROLE=$(get_role "retailer_admin")
if [ "$ADMIN_USER_ID" != "null" ] && [ "$ADMIN_USER_ID" != "" ]; then
    curl -s -X POST "$KEYCLOAK_URL/admin/realms/$REALM_NAME/users/$ADMIN_USER_ID/role-mappings/realm" \
        -H "Authorization: Bearer $ADMIN_TOKEN" \
        -H "Content-Type: application/json" \
        -d "[$ADMIN_ROLE]"
    echo "✅ Assigned retailer_admin role to admin user"
fi

# Assign sales_associate role to customer users
SALES_ROLE=$(get_role "sales_associate")
for username in "customer1" "customer2"; do
    USER_ID=$(get_user_id "$username")
    if [ "$USER_ID" != "null" ] && [ "$USER_ID" != "" ]; then
        curl -s -X POST "$KEYCLOAK_URL/admin/realms/$REALM_NAME/users/$USER_ID/role-mappings/realm" \
            -H "Authorization: Bearer $ADMIN_TOKEN" \
            -H "Content-Type: application/json" \
            -d "[$SALES_ROLE]"
        echo "✅ Assigned sales_associate role to $username"
    fi
done

# Assign ashi_sales_representative role to retailer user
RETAILER_USER_ID=$(get_user_id "retailer1")
REP_ROLE=$(get_role "ashi_sales_representative")
if [ "$RETAILER_USER_ID" != "null" ] && [ "$RETAILER_USER_ID" != "" ]; then
    curl -s -X POST "$KEYCLOAK_URL/admin/realms/$REALM_NAME/users/$RETAILER_USER_ID/role-mappings/realm" \
        -H "Authorization: Bearer $ADMIN_TOKEN" \
        -H "Content-Type: application/json" \
        -d "[$REP_ROLE]"
    echo "✅ Assigned ashi_sales_representative role to retailer1"
fi

echo ""
echo "🎉 Keycloak realm setup completed successfully!"
echo ""
echo "📋 Summary:"
echo "  Realm: $REALM_NAME"
echo "  Client: $CLIENT_ID"
echo "  Client Secret: ashid-client-secret"
echo ""
echo "👥 Users created:"
echo "  admin (retailer_admin): admin@ashid.com / admin123"
echo "  customer1 (sales_associate): customer1@ashid.com / customer123"
echo "  customer2 (sales_associate): customer2@ashid.com / customer123"
echo "  retailer1 (ashi_sales_representative): retailer1@ashid.com / retailer123"
echo ""
echo "🌐 Access URLs:"
echo "  Keycloak Admin: $KEYCLOAK_URL/admin"
echo "  Realm URL: $KEYCLOAK_URL/realms/$REALM_NAME"
echo "  Token URL: $KEYCLOAK_URL/realms/$REALM_NAME/protocol/openid-connect/token"
echo ""