#!/bin/bash

# Run database migrations
set -e

echo "Waiting for database to be ready..."
until pg_isready -h localhost -p 5432 -U authuser; do
    sleep 2
done

echo "Running migrations..."
alembic upgrade head

echo "Migrations complete!"
