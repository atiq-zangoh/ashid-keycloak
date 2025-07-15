# This policy allows the auth service to manage tokens
path "secret/data/auth-tokens/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "secret/metadata/auth-tokens/*" {
  capabilities = ["list", "read", "delete"]
}

# Allow token self-renewal
path "auth/token/renew-self" {
  capabilities = ["update"]
}

# Allow token lookup
path "auth/token/lookup-self" {
  capabilities = ["read"]
}
