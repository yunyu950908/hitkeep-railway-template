# HitKeep Template Variables

Railway requires template variables to have descriptions or default values before publishing. Use these values in the template editor for the generated `hitkeep` service.

This list matches the 19 pre-configured variables currently shown in the published Railway template editor and the variables created by [scripts/create-template-source-project.sh](scripts/create-template-source-project.sh).

| Variable | Default value | Description |
| --- | --- | --- |
| `PORT` | `8080` | Railway routes public traffic to this internal service port. |
| `HITKEEP_HTTP_ADDR` | `:8080` | HitKeep HTTP listener address inside the container. |
| `HITKEEP_PUBLIC_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | Public Railway URL used for dashboard assets, tracker URLs, email links, CORS, and JWT issuer validation. |
| `HITKEEP_JWT_SECRET` | `${{secret(64, "abcdef0123456789")}}` | Per-deployment 32-byte hex secret for signing sessions. |
| `HITKEEP_DB_PATH` | `/var/lib/hitkeep/data/hitkeep.db` | Primary HitKeep DuckDB database path on the mounted volume. |
| `HITKEEP_DATA_PATH` | `/var/lib/hitkeep/data` | Base data directory for tenant-local DuckDB files and runtime data. |
| `HITKEEP_ARCHIVE_PATH` | `s3://${{hitkeep-backups.BUCKET}}/hitkeep/archive` | Railway Bucket destination for retention archives and archival artifacts. |
| `HITKEEP_BACKUP_PATH` | `s3://${{hitkeep-backups.BUCKET}}/hitkeep/backups` | Railway Bucket destination for automatic HitKeep backup snapshots. |
| `HITKEEP_BACKUP_INTERVAL` | `60` | Runs automatic HitKeep backups every 60 minutes. |
| `HITKEEP_BACKUP_RETENTION` | `24` | Local backup retention count. S3 bucket backups require external cleanup. |
| `HITKEEP_S3_ACCESS_KEY_ID` | `${{hitkeep-backups.ACCESS_KEY_ID}}` | Railway Bucket access key id for static S3-compatible authentication. |
| `HITKEEP_S3_SECRET_ACCESS_KEY` | `${{hitkeep-backups.SECRET_ACCESS_KEY}}` | Railway Bucket secret access key for static S3-compatible authentication. |
| `HITKEEP_S3_REGION` | `${{hitkeep-backups.REGION}}` | Railway Bucket region used when signing S3 requests. |
| `HITKEEP_S3_ENDPOINT` | `t3.storageapi.dev` | Host-only Railway Bucket S3 endpoint for DuckDB. Do not include `https://`; match the host from the bucket `ENDPOINT` credential if Railway shows a different endpoint. |
| `HITKEEP_S3_URL_STYLE` | `vhost` | Uses virtual-hosted-style S3 URLs for Railway Buckets. |
| `HITKEEP_S3_USE_SSL` | `true` | Enables HTTPS for S3 backup and archive writes. |
| `HITKEEP_SPAM_FILTER_PATH` | `/var/lib/hitkeep/data/spam-filter.json` | Cache file for HitKeep's spam-filter data. |
| `HITKEEP_SPAM_FILTER_AUTO_UPDATE` | `true` | Allows the HitKeep leader node to refresh the OSS spam-filter feed automatically. |
| `RAILWAY_RUN_UID` | `0` | Runs the container as root so the Railway volume is writable. |
