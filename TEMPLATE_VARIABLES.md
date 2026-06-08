# HitKeep Template Variables

Railway requires template variables to have descriptions or default values before publishing. Use these values in the template editor for the generated `hitkeep` service.

| Variable | Default value | Description |
| --- | --- | --- |
| `PORT` | `8080` | Railway routes public traffic to this internal service port. |
| `HITKEEP_HTTP_ADDR` | `:8080` | HitKeep HTTP listener address inside the container. |
| `HITKEEP_DB_PATH` | `/var/lib/hitkeep/data/hitkeep.db` | Primary HitKeep DuckDB database path on the mounted volume. |
| `HITKEEP_DATA_PATH` | `/var/lib/hitkeep/data` | Base data directory for tenant-local DuckDB files and runtime data. |
| `RAILWAY_RUN_UID` | `0` | Runs the container as root so the Railway volume is writable. |
| `HITKEEP_S3_ENDPOINT` | `t3.storageapi.dev` | Host-only Railway Bucket S3 endpoint for DuckDB. Do not include `https://`. |
| `HITKEEP_S3_URL_STYLE` | `vhost` | Uses virtual-hosted-style S3 URLs for Railway Buckets. |
| `HITKEEP_S3_USE_SSL` | `true` | Enables HTTPS for S3 backup and archive writes. |
| `HITKEEP_BACKUP_INTERVAL` | `60` | Runs automatic HitKeep backups every 60 minutes. |
| `HITKEEP_BACKUP_RETENTION` | `24` | Local backup retention count. S3 bucket backups require external cleanup. |
| `HITKEEP_SPAM_FILTER_PATH` | `/var/lib/hitkeep/data/spam-filter.json` | Cache file for HitKeep's spam filter data. |
| `HITKEEP_SPAM_FILTER_AUTO_UPDATE` | `true` | Allows HitKeep to refresh the OSS spam filter feed automatically. |
