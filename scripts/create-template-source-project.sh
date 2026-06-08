#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME="${PROJECT_NAME:-hitkeep-railway-template}"
SERVICE_NAME="${SERVICE_NAME:-hitkeep}"
IMAGE="${IMAGE:-pascalebeier/hitkeep:2.7.0}"
WORKSPACE="${RAILWAY_WORKSPACE:-}"

caller_env=(
  "RAILWAY_CALLER=${RAILWAY_CALLER:-hitkeep-railway-template-script}"
  "RAILWAY_AGENT_SESSION=${RAILWAY_AGENT_SESSION:-hitkeep-template-script-$$}"
)

railway_cmd() {
  env "${caller_env[@]}" railway "$@"
}

if ! command -v railway >/dev/null 2>&1; then
  echo "railway CLI is required" >&2
  exit 1
fi

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

service_json="$(railway_cmd add --image "$IMAGE" --service "$SERVICE_NAME" --json \
  --variables "PORT=8080" \
  --variables "HITKEEP_HTTP_ADDR=:8080" \
  --variables 'HITKEEP_PUBLIC_URL=https://${{RAILWAY_PUBLIC_DOMAIN}}' \
  --variables 'HITKEEP_JWT_SECRET=${{secret(64, "abcdef0123456789")}}' \
  --variables "HITKEEP_DB_PATH=/var/lib/hitkeep/data/hitkeep.db" \
  --variables "HITKEEP_DATA_PATH=/var/lib/hitkeep/data" \
  --variables "HITKEEP_ARCHIVE_PATH=/var/lib/hitkeep/data/archive" \
  --variables "HITKEEP_BACKUP_PATH=/var/lib/hitkeep/data/backups" \
  --variables "HITKEEP_BACKUP_INTERVAL=60" \
  --variables "HITKEEP_BACKUP_RETENTION=24" \
  --variables "HITKEEP_SPAM_FILTER_AUTO_UPDATE=true" \
  --variables "HITKEEP_SPAM_FILTER_PATH=/var/lib/hitkeep/data/spam-filter.json" \
  --variables "RAILWAY_RUN_UID=0")"

service_id="$(printf '%s' "$service_json" | jq -r '.serviceId // .id // empty')"
if [[ -z "$service_id" ]]; then
  echo "Could not parse service id from railway add output:" >&2
  printf '%s\n' "$service_json" >&2
  exit 1
fi

railway_cmd volume --service "$service_id" add --mount-path /var/lib/hitkeep/data --json >/dev/null
railway_cmd domain --service "$service_id" --port 8080 --json >/dev/null

cat <<EOF
Created Railway template source project.

Project ID: $project_id
Service ID: $service_id

Next:
  railway templates create --project $project_id --environment production --json
EOF
