#!/bin/sh
# wait-for-postgres.sh

set -e

host="$1"
shift
cmd="$@"

until PGPASSWORD=$BANK_POSTGRES_PASSWORD psql -h "$host" -U "$BANK_POSTGRES_USERNAME" -d "$BANK_POSTGRES_DATABASE" -c '\q'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done

>&2 echo "Postgres is up - executing command"
exec $cmd