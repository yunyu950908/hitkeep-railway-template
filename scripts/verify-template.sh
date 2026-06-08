#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root_dir"

fail() {
  echo "verify-template: $*" >&2
  exit 1
}

require_line() {
  local file="$1"
  local line="$2"

  rg --fixed-strings --quiet "$line" "$file" || fail "missing expected line in $file: $line"
}

command -v jq >/dev/null 2>&1 || fail "jq is required"
command -v rg >/dev/null 2>&1 || fail "ripgrep is required"

jq empty railway-template.json
bash -n scripts/create-template-source-project.sh
bash -n scripts/verify-template.sh

require_line .env.example 'HITKEEP_ARCHIVE_PATH=s3://${{hitkeep-backups.BUCKET}}/hitkeep/archive'
require_line .env.example 'HITKEEP_BACKUP_PATH=s3://${{hitkeep-backups.BUCKET}}/hitkeep/backups'
require_line .env.example 'HITKEEP_S3_ACCESS_KEY_ID=${{hitkeep-backups.ACCESS_KEY_ID}}'
require_line .env.example 'HITKEEP_S3_SECRET_ACCESS_KEY=${{hitkeep-backups.SECRET_ACCESS_KEY}}'
require_line .env.example 'HITKEEP_S3_REGION=${{hitkeep-backups.REGION}}'
require_line .env.example 'HITKEEP_S3_ENDPOINT=storage.railway.app'
require_line .env.example 'HITKEEP_S3_URL_STYLE=vhost'
require_line .env.example 'HITKEEP_S3_USE_SSL=true'

require_line scripts/create-template-source-project.sh 'BUCKET_NAME="${BUCKET_NAME:-hitkeep-backups}"'
require_line scripts/create-template-source-project.sh 'BUCKET_REGION="${BUCKET_REGION:-iad}"'
rg --quiet 'railway_cmd bucket create "\$BUCKET_NAME" --region "\$BUCKET_REGION" --json' scripts/create-template-source-project.sh \
  || fail "template source project script must create a Railway bucket"

if rg --quiet 'HITKEEP_(BACKUP|ARCHIVE)_PATH=/var/lib/hitkeep/data/(backups|archive)' \
  .env.example scripts/create-template-source-project.sh; then
  fail "backup/archive paths must use the Railway bucket, not the local volume"
fi

rg --quiet 'HITKEEP_BACKUP_RETENTION.*local|local.*HITKEEP_BACKUP_RETENTION' README.md TEMPLATE_README.md \
  || fail "docs must explain that HITKEEP_BACKUP_RETENTION only prunes local backups"

echo "verify-template: ok"
