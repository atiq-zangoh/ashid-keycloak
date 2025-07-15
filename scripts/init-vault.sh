#!/bin/bash

# Initialize Vault for the auth service
set -e

VAULT_ADDR="${VAULT_ADDR:-http://localhost:8200}"
VAULT_TOKEN="${VAULT_TOKEN:-myroot}"

echo "Waiting for Vault to be ready..."
until curl -s -f -o /dev/null "$VAULT_ADDR/v1/sys/health"; do
    sleep 2
done

echo "Initializing Vault..."

# Login to Vault
export VAULT_ADDR
export VAULT_TOKEN

# Enable KV v2 secrets engine
vault secrets enable -path=secret kv-v2 || echo "KV v2 already enabled"

# Create auth service policy
vault policy write auth-service-policy /vault/policies/auth-service-policy.hcl

# Create a token for the auth service with the policy
AUTH_SERVICE_TOKEN=$(vault token create -policy=auth-service-policy -format=json | jq -r '.auth.client_token')

echo "=================================="
echo "Vault initialization complete!"
echo "=================================="
echo "Auth Service Token: $AUTH_SERVICE_TOKEN"
echo ""
echo "Update your .env file with:"
echo "VAULT_TOKEN=$AUTH_SERVICE_TOKEN"
echo "=================================="
