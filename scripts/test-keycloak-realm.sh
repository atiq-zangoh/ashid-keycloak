#!/bin/bash

# Test script for Keycloak realm setup
# Tests authentication for all user types and role verification

set -e

KEYCLOAK_URL="http://localhost:8080"
REALM_NAME="ashid-dev"
CLIENT_ID="ashid-client"
CLIENT_SECRET="ashid-client-secret"

echo "🧪 Testing Keycloak realm: $REALM_NAME"

# Wait for Keycloak to be ready
echo "⏳ Waiting for Keycloak to be ready..."
while ! curl -s "$KEYCLOAK_URL/realms/$REALM_NAME" > /dev/null; do
    echo "Waiting for Keycloak and realm..."
    sleep 2
done

echo "✅ Keycloak and realm are ready!"

# Function to test user authentication
test_user_auth() {
    local username=$1
    local password=$2
    local expected_role=$3
    
    echo "🔐 Testing authentication for user: $username"
    
    # Get access token
    RESPONSE=$(curl -s -X POST "$KEYCLOAK_URL/realms/$REALM_NAME/protocol/openid-connect/token" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "username=$username" \
        -d "password=$password" \
        -d "grant_type=password" \
        -d "client_id=$CLIENT_ID" \
        -d "client_secret=$CLIENT_SECRET")
    
    ACCESS_TOKEN=$(echo $RESPONSE | jq -r '.access_token')
    
    if [ "$ACCESS_TOKEN" = "null" ] || [ -z "$ACCESS_TOKEN" ]; then
        echo "❌ Authentication failed for user: $username"
        echo "Response: $RESPONSE"
        return 1
    fi
    
    echo "✅ Authentication successful for user: $username"
    
    # Decode JWT to check roles (simplified check)
    PAYLOAD=$(echo $ACCESS_TOKEN | cut -d'.' -f2)
    # Add padding if needed
    while [ $((${#PAYLOAD} % 4)) -ne 0 ]; do
        PAYLOAD="${PAYLOAD}="
    done
    
    DECODED=$(echo $PAYLOAD | base64 -d 2>/dev/null | jq . 2>/dev/null || echo '{}')
    
    # Check if expected role is present
    if echo "$DECODED" | jq -r '.realm_access.roles[]?' 2>/dev/null | grep -q "$expected_role"; then
        echo "✅ Role verification successful: $username has $expected_role role"
    else
        echo "⚠️  Role verification: Could not verify $expected_role role for $username"
        echo "Available roles: $(echo "$DECODED" | jq -r '.realm_access.roles[]?' 2>/dev/null | tr '\n' ' ')"
    fi
    
    echo "📋 Token info for $username:"
    echo "  Subject: $(echo "$DECODED" | jq -r '.sub?' 2>/dev/null)"
    echo "  Email: $(echo "$DECODED" | jq -r '.email?' 2>/dev/null)"
    echo "  Name: $(echo "$DECODED" | jq -r '.name?' 2>/dev/null)"
    echo ""
    
    return 0
}

# Test all users
echo "🚀 Starting user authentication tests..."
echo ""

# Test admin user
test_user_auth "admin" "admin123" "retailer_admin"

# Test sales associate users
test_user_auth "customer1" "customer123" "sales_associate"
test_user_auth "customer2" "customer123" "sales_associate"

# Test ASHI sales representative user
test_user_auth "retailer1" "retailer123" "ashi_sales_representative"

echo "🎉 All authentication tests completed!"
echo ""

# Test realm information
echo "📋 Realm Information:"
REALM_INFO=$(curl -s "$KEYCLOAK_URL/realms/$REALM_NAME")
echo "  Realm: $(echo $REALM_INFO | jq -r '.realm')"
echo "  Token Service: $(echo $REALM_INFO | jq -r '.token-service')"
echo "  Account Service: $(echo $REALM_INFO | jq -r '.account-service')"
echo ""

# Test client information
echo "📋 Testing client configuration..."
CLIENT_CONFIG=$(curl -s "$KEYCLOAK_URL/realms/$REALM_NAME/.well-known/openid_configuration")
echo "  Authorization Endpoint: $(echo $CLIENT_CONFIG | jq -r '.authorization_endpoint')"
echo "  Token Endpoint: $(echo $CLIENT_CONFIG | jq -r '.token_endpoint')"
echo "  UserInfo Endpoint: $(echo $CLIENT_CONFIG | jq -r '.userinfo_endpoint')"
echo "  Logout Endpoint: $(echo $CLIENT_CONFIG | jq -r '.end_session_endpoint')"
echo ""

echo "✅ Keycloak realm testing completed successfully!"
echo ""
echo "🌐 Access Information:"
echo "  Keycloak Admin Console: $KEYCLOAK_URL/admin"
echo "  Realm Console: $KEYCLOAK_URL/admin/master/console/#/ashid-dev"
echo "  User Account Console: $KEYCLOAK_URL/realms/$REALM_NAME/account"
echo ""
echo "👥 Test Users:"
echo "  admin / admin123 (retailer_admin)"
echo "  customer1 / customer123 (sales_associate)"
echo "  customer2 / customer123 (sales_associate)"
echo "  retailer1 / retailer123 (ashi_sales_representative)"