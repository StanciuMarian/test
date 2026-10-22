#!/usr/bin/env bash
# Starts the whole training stack in one go: used by the Codespaces config, also works locally.
# On first run it creates .env with random secrets and a random CTFd admin password.
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Waiting for Docker ..."
for _ in $(seq 1 60); do
  docker info >/dev/null 2>&1 && break
  sleep 2
done
docker info >/dev/null 2>&1 || { echo "Docker is not running"; exit 1; }

if [[ ! -f .env ]]; then
  echo "Creating .env with random secrets ..."
  cat > .env <<ENV
CTF_KEY=$(openssl rand -hex 24)
CTFD_SECRET_KEY=$(openssl rand -hex 24)
CTFD_ADMIN_PASSWORD=$(openssl rand -hex 12)
JUICE_SHOP_PROFILE=training
ENV
fi

CTFD_ADMIN_PASSWORD="$(grep -E '^CTFD_ADMIN_PASSWORD=' .env | cut -d= -f2- || true)"
export CTFD_ADMIN_PASSWORD

docker compose up -d

if [[ ! -s ctf/output/ctfd-challenges.csv ]]; then
  ./scripts/generate-ctfd-import.sh
fi
./scripts/setup-ctfd.sh

cat <<MSG

==========================================================
 Juice Shop CTF is running
   Juice Shop : port 3000
   CTFd       : port 8000  (admin login: admin / $CTFD_ADMIN_PASSWORD)
 In Codespaces, open both from the "Ports" tab.
 The admin password is stored in .env.
==========================================================
MSG
