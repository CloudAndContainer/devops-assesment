#!/bin/sh
set -e

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
until PGPASSWORD=$BANK_POSTGRES_PASSWORD psql -h "${BANK_POSTGRES_HOST%%:*}" -p "${BANK_POSTGRES_HOST##*:}" -U "$BANK_POSTGRES_USERNAME" -d "$BANK_POSTGRES_DATABASE" -c '\q'; do
  >&2 echo "PostgreSQL is unavailable - sleeping"
  sleep 2
done

>&2 echo "PostgreSQL is up - starting application"
exec ./transaction-api "$@"