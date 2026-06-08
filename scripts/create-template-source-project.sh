#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME="${PROJECT_NAME:-hitkeep-bucket-template}"
SERVICE_NAME="${SERVICE_NAME:-hitkeep}"
BUCKET_NAME="${BUCKET_NAME:-hitkeep-backups}"
BUCKET_REGION="${BUCKET_REGION:-}"
IMAGE="${IMAGE:-pascalebeier/hitkeep:2.7.0}"
WORKSPACE="${RAILWAY_WORKSPACE:-}"
HITKEEP_S3_ENDPOINT="${HITKEEP_S3_ENDPOINT:-t3.storageapi.dev}"

caller_env=(
  "RAILWAY_CALLER=${RAILWAY_CALLER:-hitkeep-bucket-template-script}"
  "RAILWAY_AGENT_SESSION=${RAILWAY_AGENT_SESSION:-hitkeep-template-script-$$}"
)

railway_cmd() {
  env "${caller_env[@]}" railway "$@"
}

if ! command -v railway >/dev/null 2>&1; then
  echo "railway CLI is required" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

bucket_ref() {
  printf '${{%s.%s}}' "$BUCKET_NAME" "$1"
}

init_args=(init --name "$PROJECT_NAME" --json)
if [[ -n "$WORKSPACE" ]]; then
  init_args+=(--workspace "$WORKSPACE")
fi

project_json="$(railway_cmd "${init_args[@]}")"
project_id="$(printf '%s' "$project_json" | jq -r '.projectId // .id // empty')"
if [[ -z "$project_id" ]]; then
  echo "Could not parse project id from railway init output:" >&2
  printf '%s\n' "$project_json" >&2
  exit 1
fi

project_status_json="$(railway_cmd status --json)"
environment_id="$(printf '%s' "$project_status_json" | jq -r '[.environments.edges[]?.node | select(.name == "production") | .id][0] // [.environments.edges[]?.node.id][0] // empty')"
if [[ -z "$environment_id" ]]; then
  echo "Could not parse environment id from railway status output:" >&2
  printf '%s\n' "$project_status_json" >&2
  exit 1
fi

bucket_create_args=(bucket create "$BUCKET_NAME" --environment "$environment_id" --json)
if [[ -n "$BUCKET_REGION" ]]; then
  bucket_create_args+=(--region "$BUCKET_REGION")
fi

bucket_json="$(railway_cmd "${bucket_create_args[@]}")"
bucket_id="$(printf '%s' "$bucket_json" | jq -r '.id // .bucketId // .bucket.id // empty')"
if [[ -z "$bucket_id" ]]; then
  echo "Could not parse bucket id from railway bucket create output:" >&2
  printf '%s\n' "$bucket_json" >&2
  exit 1
fi

service_json="$(railway_cmd add --image "$IMAGE" --service "$SERVICE_NAME" --json \
  --variables "PORT=8080" \
  --variables "HITKEEP_HTTP_ADDR=:8080" \
  --variables 'HITKEEP_PUBLIC_URL=https://${{RAILWAY_PUBLIC_DOMAIN}}' \
  --variables 'HITKEEP_JWT_SECRET=${{secret(64, "abcdef0123456789")}}' \
  --variables "HITKEEP_DB_PATH=/var/lib/hitkeep/data/hitkeep.db" \
  --variables "HITKEEP_DATA_PATH=/var/lib/hitkeep/data" \
  --variables "HITKEEP_ARCHIVE_PATH=s3://$(bucket_ref BUCKET)/hitkeep/archive" \
  --variables "HITKEEP_BACKUP_PATH=s3://$(bucket_ref BUCKET)/hitkeep/backups" \
  --variables "HITKEEP_BACKUP_INTERVAL=60" \
  --variables "HITKEEP_BACKUP_RETENTION=24" \
  --variables "HITKEEP_S3_ACCESS_KEY_ID=$(bucket_ref ACCESS_KEY_ID)" \
  --variables "HITKEEP_S3_SECRET_ACCESS_KEY=$(bucket_ref SECRET_ACCESS_KEY)" \
  --variables "HITKEEP_S3_REGION=$(bucket_ref REGION)" \
  --variables "HITKEEP_S3_ENDPOINT=$HITKEEP_S3_ENDPOINT" \
  --variables "HITKEEP_S3_URL_STYLE=vhost" \
  --variables "HITKEEP_S3_USE_SSL=true" \
  --variables "HITKEEP_SPAM_FILTER_AUTO_UPDATE=true" \
  --variables "HITKEEP_SPAM_FILTER_PATH=/var/lib/hitkeep/data/spam-filter.json" \
  --variables "RAILWAY_RUN_UID=0")"

service_id="$(printf '%s' "$service_json" | jq -r '.serviceId // .id // empty')"
if [[ -z "$service_id" ]]; then
  echo "Could not parse service id from railway add output:" >&2
  printf '%s\n' "$service_json" >&2
  exit 1
fi

volume_json="$(railway_cmd volume --project "$project_id" --environment "$environment_id" --service "$service_id" add --mount-path /var/lib/hitkeep/data --json)"
volume_id="$(printf '%s' "$volume_json" | jq -r '.id // .volumeId // .volume.id // empty')"
if [[ -z "$volume_id" ]]; then
  echo "Could not parse volume id from railway volume add output:" >&2
  printf '%s\n' "$volume_json" >&2
  exit 1
fi

railway_cmd domain --project "$project_id" --environment "$environment_id" --service "$service_id" --port 8080 --json >/dev/null

cat <<EOF
Created Railway template source project.

Project ID: $project_id
Environment ID: $environment_id
Service ID: $service_id
Bucket ID: $bucket_id
Volume ID: $volume_id

Next:
  railway templates create --project $project_id --environment production --json
EOF
