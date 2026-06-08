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

  rg --fixed-strings --quiet -- "$line" "$file" || fail "missing expected line in $file: $line"
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
require_line .env.example 'HITKEEP_S3_ENDPOINT=t3.storageapi.dev'
require_line .env.example 'HITKEEP_S3_URL_STYLE=vhost'
require_line .env.example 'HITKEEP_S3_USE_SSL=true'

require_line scripts/create-template-source-project.sh 'BUCKET_NAME="${BUCKET_NAME:-hitkeep-backups}"'
require_line scripts/create-template-source-project.sh 'BUCKET_REGION="${BUCKET_REGION:-}"'
require_line scripts/create-template-source-project.sh 'HITKEEP_S3_ENDPOINT="${HITKEEP_S3_ENDPOINT:-t3.storageapi.dev}"'
require_line scripts/create-template-source-project.sh '--variables "HITKEEP_S3_ENDPOINT=$HITKEEP_S3_ENDPOINT" \'
require_line scripts/create-template-source-project.sh 'volume_json="$(railway_cmd volume --project "$project_id" --environment "$environment_id" --service "$service_id" add --mount-path /var/lib/hitkeep/data --json)"'
require_line scripts/create-template-source-project.sh 'bucket_create_args=(bucket create "$BUCKET_NAME" --environment "$environment_id" --json)'
require_line scripts/create-template-source-project.sh 'bucket_create_args+=(--region "$BUCKET_REGION")'
require_line scripts/create-template-source-project.sh 'bucket_json="$(railway_cmd "${bucket_create_args[@]}")"'
rg --quiet 'BUCKET_REGION="\$\{BUCKET_REGION:-[a-z]' scripts/create-template-source-project.sh \
  && fail "template source project script must not hard-code a bucket region by default"
rg --quiet 'railway_cmd bucket create' scripts/create-template-source-project.sh \
  && fail "template source project script must build bucket create args so region remains optional"
rg --quiet 'bucket create "\$BUCKET_NAME" --environment "\$environment_id" --json' scripts/create-template-source-project.sh \
  || fail "template source project script must create the Railway bucket with an explicit environment"

for template_variable in \
  PORT \
  HITKEEP_HTTP_ADDR \
  HITKEEP_DB_PATH \
  HITKEEP_DATA_PATH \
  RAILWAY_RUN_UID \
  HITKEEP_S3_ENDPOINT \
  HITKEEP_S3_URL_STYLE \
  HITKEEP_S3_USE_SSL \
  HITKEEP_BACKUP_INTERVAL \
  HITKEEP_BACKUP_RETENTION \
  HITKEEP_SPAM_FILTER_PATH \
  HITKEEP_SPAM_FILTER_AUTO_UPDATE; do
  require_line TEMPLATE_VARIABLES.md "| \`$template_variable\` |"
done
require_line TEMPLATE_VARIABLES.md '| `HITKEEP_S3_ENDPOINT` | `t3.storageapi.dev` |'
require_line README.md 'If Railway blocks publishing with "Missing variable details", fill the generated template variables with the defaults and descriptions in [TEMPLATE_VARIABLES.md](TEMPLATE_VARIABLES.md).'

if rg --quiet 'HITKEEP_(BACKUP|ARCHIVE)_PATH=/var/lib/hitkeep/data/(backups|archive)' \
  .env.example scripts/create-template-source-project.sh; then
  fail "backup/archive paths must use the Railway bucket, not the local volume"
fi

rg --quiet 'HITKEEP_BACKUP_RETENTION.*local|local.*HITKEEP_BACKUP_RETENTION' README.md TEMPLATE_README.md \
  || fail "docs must explain that HITKEEP_BACKUP_RETENTION only prunes local backups"

echo "verify-template: ok"
