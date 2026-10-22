#!/usr/bin/env bash
# Generates a CTFd import ZIP with every Juice Shop challenge, its flag and hints.
# Juice Shop must be running (docker compose up -d) because challenges are read from its API.
set -euo pipefail

cd "$(dirname "$0")/.."

CTF_KEY="${CTF_KEY:-}"
if [[ -z "$CTF_KEY" && -f .env ]]; then
  CTF_KEY="$(grep -E '^CTF_KEY=' .env | cut -d= -f2- || true)"
fi
CTF_KEY="${CTF_KEY:-change-me-juice-shop-ctf-key}"
JUICE_SHOP_URL="${JUICE_SHOP_URL:-http://localhost:3000}"

echo "Waiting for Juice Shop at $JUICE_SHOP_URL ..."
for _ in $(seq 1 60); do
  curl -fs "$JUICE_SHOP_URL/api/Challenges" >/dev/null && break
  sleep 2
done
curl -fs "$JUICE_SHOP_URL/api/Challenges" >/dev/null || { echo "Juice Shop is not reachable"; exit 1; }

mkdir -p ctf/output
sed -e "s|__JUICE_SHOP_URL__|$JUICE_SHOP_URL|" -e "s|__CTF_KEY__|$CTF_KEY|" \
  ctf/ctf.config.yml > ctf/output/config.yml

docker run --rm --network host --user "$(id -u):$(id -g)" -v "$PWD/ctf/output:/data" \
  bkimminich/juice-shop-ctf:v12.0.0 \
  --config config.yml --output ctfd-challenges.csv

rm -f ctf/output/config.yml
[[ -s ctf/output/ctfd-challenges.csv ]] || { echo "Generation failed"; exit 1; }
echo "Done: ctf/output/ctfd-challenges.csv -> import it in CTFd under Admin Panel > Config > Backup > Import CSV (type: Challenges)"
