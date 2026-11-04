#!/bin/sh
set -eu

# Install the committed dependency versions before starting the dev server.
# Other commands (including composer update) run directly.
if [ "${1:-}" = hhvm ] && [ "${2:-}" = -m ] && [ "${3:-}" = server ]; then
    composer install --prefer-dist --no-progress
fi

exec "$@"
