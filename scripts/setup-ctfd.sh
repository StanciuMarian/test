#!/usr/bin/env bash
# One-time CTFd setup: creates the admin account and imports the Juice Shop challenges CSV.
# Usage: CTFD_ADMIN_PASSWORD=... ./scripts/setup-ctfd.sh
set -euo pipefail

cd "$(dirname "$0")/.."

CTFD_URL="${CTFD_URL:-http://localhost:8000}"
CTF_NAME="${CTF_NAME:-Juice Shop CTF Training}"
ADMIN_NAME="${CTFD_ADMIN_NAME:-admin}"
ADMIN_EMAIL="${CTFD_ADMIN_EMAIL:-admin@juice-sh.op}"
ADMIN_PASSWORD="${CTFD_ADMIN_PASSWORD:-}"
CSV="ctf/output/ctfd-challenges.csv"

if [[ -z "$ADMIN_PASSWORD" ]]; then
  read -rsp "Choose a CTFd admin password: " ADMIN_PASSWORD; echo
fi
[[ -s "$CSV" ]] || { echo "$CSV not found - run ./scripts/generate-ctfd-import.sh first"; exit 1; }

COOKIES="$(mktemp)"
trap 'rm -f "$COOKIES"' EXIT
nonce() { curl -fsL -c "$COOKIES" -b "$COOKIES" "$1" | grep -oE "csrfNonce': \"[0-9a-f]+\"" | cut -d'"' -f2; }

echo "Waiting for CTFd at $CTFD_URL ..."
for _ in $(seq 1 60); do
  curl -fs -o /dev/null "$CTFD_URL/login" && break
  sleep 2
done

if curl -fsL -o /dev/null -w "%{url_effective}" "$CTFD_URL/setup" | grep -q "/setup"; then
  echo "Running first-time setup ..."
  curl -fs -o /dev/null -c "$COOKIES" -b "$COOKIES" "$CTFD_URL/setup" \
    --data-urlencode "nonce=$(nonce "$CTFD_URL/setup")" \
    --data-urlencode "ctf_name=$CTF_NAME" \
    --data-urlencode "ctf_description=Hack the OWASP Juice Shop at http://localhost:3000 and submit the flags here." \
    --data-urlencode "user_mode=users" \
    --data-urlencode "challenge_visibility=private" \
    --data-urlencode "account_visibility=public" \
    --data-urlencode "score_visibility=public" \
    --data-urlencode "registration_visibility=public" \
    --data-urlencode "verify_emails=false" \
    --data-urlencode "team_size=" \
    --data-urlencode "name=$ADMIN_NAME" \
    --data-urlencode "email=$ADMIN_EMAIL" \
    --data-urlencode "password=$ADMIN_PASSWORD" \
    --data-urlencode "ctf_theme=core" \
    --data-urlencode "theme_color=" \
    --data-urlencode "start=" --data-urlencode "end=" \
    --data-urlencode "_submit=Finish"
else
  echo "CTFd is already set up, logging in as $ADMIN_NAME ..."
  curl -fs -o /dev/null -c "$COOKIES" -b "$COOKIES" "$CTFD_URL/login" \
    --data-urlencode "nonce=$(nonce "$CTFD_URL/login")" \
    --data-urlencode "name=$ADMIN_NAME" \
    --data-urlencode "password=$ADMIN_PASSWORD"
fi

# Count via the admin page: /api/v1/challenges is cached and lags behind a CSV import
count_challenges() {
  curl -fs -b "$COOKIES" "$CTFD_URL/admin/challenges" | { grep -oE 'href="/admin/challenges/[0-9]+"' || true; } | sort -u | wc -l
}

EXISTING="$(count_challenges)"
if [[ "$EXISTING" -gt 0 ]]; then
  echo "CTFd already has $EXISTING challenges, skipping import."
  exit 0
fi

echo "Importing challenges from $CSV ..."
curl -fs -o /dev/null -c "$COOKIES" -b "$COOKIES" "$CTFD_URL/admin/import/csv" \
  -F "nonce=$(nonce "$CTFD_URL/admin/config")" \
  -F "csv_type=challenges" \
  -F "csv_file=@$CSV"

COUNT="$(count_challenges)"
echo "Done: $COUNT challenges in CTFd. Log in at $CTFD_URL as $ADMIN_NAME."
