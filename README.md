# HitKeep Railway Template

One-click Railway template for [HitKeep](https://hitkeep.com), an open-source privacy-first web analytics app with a single Go binary, embedded DuckDB, and embedded NSQ.

## Deploy

Deploy the published template:

<!-- DEPLOY_BUTTON_START -->
[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/hitkeep-bucket-template)
<!-- DEPLOY_BUTTON_END -->

The template provisions one Railway service from the official Docker image, one persistent volume for active DuckDB data, and one Railway Bucket for backup/archive snapshots.

## What It Creates

| Resource | Value |
| --- | --- |
| Service | `hitkeep` |
| Docker image | `pascalebeier/hitkeep:2.7.0` |
| Public port | `8080` |
| Health endpoint | `/healthz` |
| Volume mount | `/var/lib/hitkeep/data` |
| Bucket | `hitkeep-backups` |
| Data store | Active DuckDB files under the mounted volume |
| Backup/archive store | Parquet snapshots under the Railway Bucket |

## Pre-Configured Variables

The published `hitkeep` service currently has 19 pre-configured variables in the Railway template editor:

| Variable | Template value | Why |
| --- | --- | --- |
| `PORT` | `8080` | Tells Railway which internal HTTP port to route to. |
| `HITKEEP_HTTP_ADDR` | `:8080` | Keeps HitKeep listening on its public HTTP port. |
| `HITKEEP_PUBLIC_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | Makes generated links and tracker URLs match the Railway domain. |
| `HITKEEP_JWT_SECRET` | `${{secret(64, "abcdef0123456789")}}` | Generates a unique 32-byte hex secret per deployment. |
| `RAILWAY_RUN_UID` | `0` | Railway volumes are mounted as root; the official image is non-root by default. |
| `HITKEEP_DB_PATH` | `/var/lib/hitkeep/data/hitkeep.db` | Stores the control/default database on the persistent volume. |
| `HITKEEP_DATA_PATH` | `/var/lib/hitkeep/data` | Stores tenant-local DuckDB files on the persistent volume. |
| `HITKEEP_ARCHIVE_PATH` | `s3://${{hitkeep-backups.BUCKET}}/hitkeep/archive` | Stores retention archives in Railway Bucket object storage. |
| `HITKEEP_BACKUP_PATH` | `s3://${{hitkeep-backups.BUCKET}}/hitkeep/backups` | Stores automatic HitKeep backup snapshots in Railway Bucket object storage. |
| `HITKEEP_BACKUP_INTERVAL` | `60` | Runs the HitKeep backup worker every 60 minutes. |
| `HITKEEP_BACKUP_RETENTION` | `24` | Prunes local backups only; S3/bucket backups need an external cleanup policy or job. |
| `HITKEEP_S3_ACCESS_KEY_ID` | `${{hitkeep-backups.ACCESS_KEY_ID}}` | Lets DuckDB write backup/archive Parquet files to the Railway Bucket. |
| `HITKEEP_S3_SECRET_ACCESS_KEY` | `${{hitkeep-backups.SECRET_ACCESS_KEY}}` | Secret key for the Railway Bucket S3 API. |
| `HITKEEP_S3_REGION` | `${{hitkeep-backups.REGION}}` | Region used when signing S3 requests. |
| `HITKEEP_S3_ENDPOINT` | `t3.storageapi.dev` | Host-only form of the Railway Bucket endpoint for DuckDB. Match the host from the bucket `ENDPOINT` credential if Railway shows a different endpoint. |
| `HITKEEP_S3_URL_STYLE` | `vhost` | Matches current Railway Bucket virtual-hosted-style URLs. |
| `HITKEEP_S3_USE_SSL` | `true` | Uses HTTPS for bucket writes. |
| `HITKEEP_SPAM_FILTER_PATH` | `/var/lib/hitkeep/data/spam-filter.json` | Keeps the spam-filter cache on the persistent volume. |
| `HITKEEP_SPAM_FILTER_AUTO_UPDATE` | `true` | Lets HitKeep refresh the OSS spam-filter feed automatically. |

## After Deploying

1. Open the Railway-generated domain.
2. Create the initial admin account.
3. Create your first site.
4. Add the tracker snippet to your site:

```html
<script async src="https://your-hitkeep-domain/hk.js"></script>
```

## Production Notes

- Keep the service at one replica unless you have validated HitKeep clustering and shared storage for your use case.
- HitKeep keeps active DuckDB files on the volume. Automatic HitKeep backups and retention archives go to the Railway Bucket as Parquet snapshots, so they survive volume-level data loss better than same-volume local backups.
- Railway Bucket `ENDPOINT` is an endpoint URL from the bucket credentials, such as `https://storage.railway.app` or `https://t3.storageapi.dev`, while DuckDB's S3 `ENDPOINT` setting expects the host without `https://`. Keep `HITKEEP_S3_ENDPOINT` synced to that host-only endpoint value.
- `HITKEEP_BACKUP_RETENTION` only prunes local filesystem backups in HitKeep 2.7.0. Railway Buckets currently do not provide bucket lifecycle configuration, so production deployments should add a separate cleanup job if backup growth matters.
- SMTP features such as invites, password reset, and email reports require outbound SMTP. Railway currently only enables raw SMTP on Pro and above; Free/Trial/Hobby should treat email features as unavailable unless HitKeep adds an HTTPS mail driver.
- If you use a custom domain, update `HITKEEP_PUBLIC_URL` to the final HTTPS origin.

## Validation

Run the repository-level template validation before publishing template changes:

```bash
./scripts/verify-template.sh
```

This checks JSON syntax, shell syntax, required bucket-backed environment variables, source-project bucket creation, and documentation for the S3 retention caveat.
If Railway blocks publishing with "Missing variable details", fill the generated template variables with the defaults and descriptions in [TEMPLATE_VARIABLES.md](TEMPLATE_VARIABLES.md).

## Recreate The Template Source Project

This repository includes a helper script that applies the same Railway service shape used for the published template:

```bash
./scripts/create-template-source-project.sh
```

The script does not set a bucket region by default. Railway will use the current account or workspace default region for the bucket. To force a one-off bucket region while recreating the source project, run for example `BUCKET_REGION=sin ./scripts/create-template-source-project.sh`.

The script mirrors the 19 pre-configured variables from the published template. It uses Railway reference variables for the public domain, bucket name, bucket credentials, and bucket region. `HITKEEP_S3_ENDPOINT` remains a host-only value because the Railway Bucket `ENDPOINT` credential includes `https://`, while DuckDB expects the endpoint host separately from `HITKEEP_S3_USE_SSL`.

The published template itself is generated from the Railway project with:

```bash
railway templates create --project <project-id> --environment production --json
railway templates publish <template-id> \
  --category Analytics \
  --description "Self-hosted HitKeep analytics with Railway Bucket backups." \
  --readme-file TEMPLATE_README.md \
  --json
```

When updating the already-published Docker-image template, `railway templates create` generates a new unpublished draft from the source project. Review that draft in the Railway template editor before publishing so the public deploy code remains the intended `hitkeep-bucket-template` URL. The CLI `templates publish/update` command updates marketplace metadata and README content, but does not expose a flag to rewrite an existing template's deploy code or replace its resource snapshot in place.

## License

This template repository is MIT licensed. HitKeep itself is MIT licensed by its upstream project.
