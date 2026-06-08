# HitKeep Railway Template

One-click Railway template for [HitKeep](https://hitkeep.com), an open-source privacy-first web analytics app with a single Go binary, embedded DuckDB, and embedded NSQ.

## Deploy

Deploy the published template:

<!-- DEPLOY_BUTTON_START -->
[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/hitkeep-railway-template)
<!-- DEPLOY_BUTTON_END -->

The template provisions one Railway service from the official Docker image and attaches one persistent volume for HitKeep data.

## What It Creates

| Resource | Value |
| --- | --- |
| Service | `hitkeep` |
| Docker image | `pascalebeier/hitkeep:2.7.0` |
| Public port | `8080` |
| Health endpoint | `/healthz` |
| Volume mount | `/var/lib/hitkeep/data` |
| Data store | DuckDB files under the mounted volume |

## Important Variables

| Variable | Template value | Why |
| --- | --- | --- |
| `PORT` | `8080` | Tells Railway which internal HTTP port to route to. |
| `HITKEEP_HTTP_ADDR` | `:8080` | Keeps HitKeep listening on its public HTTP port. |
| `HITKEEP_PUBLIC_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | Makes generated links and tracker URLs match the Railway domain. |
| `HITKEEP_JWT_SECRET` | `${{secret(64, "abcdef0123456789")}}` | Generates a unique 32-byte hex secret per deployment. |
| `RAILWAY_RUN_UID` | `0` | Railway volumes are mounted as root; the official image is non-root by default. |
| `HITKEEP_DB_PATH` | `/var/lib/hitkeep/data/hitkeep.db` | Stores the control/default database on the persistent volume. |
| `HITKEEP_DATA_PATH` | `/var/lib/hitkeep/data` | Stores tenant-local DuckDB files on the persistent volume. |
| `HITKEEP_ARCHIVE_PATH` | `/var/lib/hitkeep/data/archive` | Keeps retention archives on the persistent volume. |
| `HITKEEP_BACKUP_PATH` | `/var/lib/hitkeep/data/backups` | Enables local HitKeep backup snapshots. |

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
- Enable Railway volume backups or configure external S3/R2 backups. Local HitKeep backups on the same volume are useful for recovery workflows but are not off-platform disaster recovery.
- SMTP features such as invites, password reset, and email reports require outbound SMTP. Railway currently only enables raw SMTP on Pro and above; Free/Trial/Hobby should treat email features as unavailable unless HitKeep adds an HTTPS mail driver.
- If you use a custom domain, update `HITKEEP_PUBLIC_URL` to the final HTTPS origin.

## Recreate The Template Source Project

This repository includes a helper script that applies the same Railway service shape used for the published template:

```bash
./scripts/create-template-source-project.sh
```

The published template itself is generated from the Railway project with:

```bash
railway templates create --project <project-id> --environment production --json
railway templates publish <template-id> \
  --category Analytics \
  --description "Self-hosted HitKeep analytics with DuckDB storage." \
  --readme-file TEMPLATE_README.md \
  --json
```

## License

This template repository is MIT licensed. HitKeep itself is MIT licensed by its upstream project.
