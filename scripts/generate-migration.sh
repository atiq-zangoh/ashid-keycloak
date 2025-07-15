#!/bin/bash

# Generate initial database migration
set -e

echo "Generating initial migration..."
alembic revision --autogenerate -m "Initial migration - users, tokens, and audit tables"

echo "Migration generated!"
echo "Review the generated migration file in migrations/versions/"
echo "Then run: ./scripts/run-migrations.sh"
