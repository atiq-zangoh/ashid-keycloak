#!/bin/bash

# Script to update Keycloak roles for Ashid project
# This removes old roles and creates new ones

set -e

KEYCLOAK_URL="http://localhost:8080"
ADMIN_USER="admin"
ADMIN_PASS="admin"
REALM_NAME="ashid-dev"

echo "🔄 Updating Keycloak roles for realm: $REALM_NAME"

# Wait for Keycloak to be ready
echo "⏳ Waiting for Keycloak to be ready..."
while ! curl -s "$KEYCLOAK_URL/realms/$REALM_NAME" > /dev/null; do
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

# Function to get all users with a specific role
get_users_with_role() {
    local role_name=$1
    curl -s -X GET "$KEYCLOAK_URL/admin/realms/$REALM_NAME/roles/$role_name/users" \
        -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.[].username' || echo ""
}

# Function to remove role from user
remove_role_from_user() {
    local username=$1
    local role_name=$2
    
    # Get user ID
    local user_id=$(curl -s -G "$KEYCLOAK_URL/admin/realms/$REALM_NAME/users" \
        -H "Authorization: Bearer $ADMIN_TOKEN" \
        -d "username=$username" | jq -r '.[0].id')
    
    if [ "$user_id" != "null" ] && [ -n "$user_id" ]; then
        # Get role object
        local role=$(curl -s "$KEYCLOAK_URL/admin/realms/$REALM_NAME/roles/$role_name" \
            -H "Authorization: Bearer $ADMIN_TOKEN")
        
        # Remove role mapping
        curl -s -X DELETE "$KEYCLOAK_URL/admin/realms/$REALM_NAME/users/$user_id/role-mappings/realm" \
            -H "Authorization: Bearer $ADMIN_TOKEN" \
            -H "Content-Type: application/json" \
            -d "[$role]"
    fi
}

# Old roles to delete
OLD_ROLES=("ashi_admin" "customer" "retailer")

echo "🗑️  Removing old roles..."

for role in "${OLD_ROLES[@]}"; do
    echo "Processing role: $role"
    
    # Get users with this role
    users=$(get_users_with_role "$role")
    
    # Remove role from users
    if [ -n "$users" ]; then
        echo "  Removing role from users..."
        while IFS= read -r user; do
            if [ -n "$user" ]; then
                remove_role_from_user "$user" "$role"
                echo "  Removed $role from $user"
            fi
        done <<< "$users"
    fi
    
    # Delete the role
    curl -s -X DELETE "$KEYCLOAK_URL/admin/realms/$REALM_NAME/roles/$role" \
        -H "Authorization: Bearer $ADMIN_TOKEN"
    
    echo "  ✅ Deleted role: $role"
done

echo "✅ Old roles removed"

# New roles to create - using arrays instead of associative array for compatibility
ROLE_NAMES=(
    "retailer_admin"
    "ashi_sales_representative"
    "sales_associate"
    "purchasing_manager"
    "accounting_manager"
    "marketing_manager"
)

ROLE_DESCRIPTIONS=(
    "Retailer Administrator with store management permissions"
    "ASHI Sales Representative managing sales operations"
    "Sales Associate handling day-to-day sales"
    "Purchasing Manager overseeing procurement"
    "Accounting Manager handling financial operations"
    "Marketing Manager managing promotional activities"
)

echo "🔨 Creating new roles..."

for i in "${!ROLE_NAMES[@]}"; do
    role_name="${ROLE_NAMES[$i]}"
    role_desc="${ROLE_DESCRIPTIONS[$i]}"
    
    curl -s -X POST "$KEYCLOAK_URL/admin/realms/$REALM_NAME/roles" \
        -H "Authorization: Bearer $ADMIN_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"name\": \"$role_name\",
            \"description\": \"$role_desc\",
            \"composite\": false,
            \"clientRole\": false,
            \"containerId\": \"$REALM_NAME\"
        }" || echo "Role $role_name might already exist"
    
    echo "✅ Created role: $role_name"
done

# Function to assign role to user
assign_role_to_user() {
    local username=$1
    local role_name=$2
    
    # Get user ID
    local user_id=$(curl -s -G "$KEYCLOAK_URL/admin/realms/$REALM_NAME/users" \
        -H "Authorization: Bearer $ADMIN_TOKEN" \
        -d "username=$username" | jq -r '.[0].id')
    
    if [ "$user_id" != "null" ] && [ -n "$user_id" ]; then
        # Get role object
        local role=$(curl -s "$KEYCLOAK_URL/admin/realms/$REALM_NAME/roles/$role_name" \
            -H "Authorization: Bearer $ADMIN_TOKEN")
        
        # Assign role
        curl -s -X POST "$KEYCLOAK_URL/admin/realms/$REALM_NAME/users/$user_id/role-mappings/realm" \
            -H "Authorization: Bearer $ADMIN_TOKEN" \
            -H "Content-Type: application/json" \
            -d "[$role]"
        
        echo "✅ Assigned $role_name to $username"
    else
        echo "⚠️  User $username not found"
    fi
}

echo ""
echo "🎭 Assigning new roles to existing users..."

# Assign roles to existing users
assign_role_to_user "admin" "retailer_admin"
assign_role_to_user "customer1" "sales_associate"
assign_role_to_user "customer2" "sales_associate"
assign_role_to_user "retailer1" "ashi_sales_representative"

echo ""
echo "🎉 Role update completed successfully!"
echo ""
echo "📋 New Roles Created:"
echo "  - retailer_admin: Retailer Administrator"
echo "  - ashi_sales_representative: ASHI Sales Representative"
echo "  - sales_associate: Sales Associate"
echo "  - purchasing_manager: Purchasing Manager"
echo "  - accounting_manager: Accounting Manager"
echo "  - marketing_manager: Marketing Manager"
echo ""
echo "👥 User Role Assignments:"
echo "  admin → retailer_admin"
echo "  customer1 → sales_associate"
echo "  customer2 → sales_associate"
echo "  retailer1 → ashi_sales_representative"
echo ""
echo "Note: You may want to create additional users for the other roles (purchasing_manager, accounting_manager, marketing_manager)"