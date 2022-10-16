#!/bin/bash
# Docker entrypoint script.

# Wait until Postgres is ready.
while ! pg_isready -h postgres -p $PGPORT -U $PGUSER; do
  echo "$(date) - Waiting for postgres to start..."
  sleep 1
done

mix ecto.create
mix ecto.migrate

exec mix phx.server