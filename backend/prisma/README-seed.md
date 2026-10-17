# Dev seed

`npm run seed` (from `backend/`; needs `docker compose -f infra/docker-compose.yml up -d` and a migrated DB) fills the
dev database and MinIO. It is idempotent — re-running updates the same rows (deterministic ids) instead of duplicating them.
Existing users keep their current password hash on re-run.

**Development only. Never run against production; these passwords are public.**

| Account | Email | Password | Notes |
|---|---|---|---|
| Admin | `admin@sketchsquare.local` | `Admin@12345` | role ADMIN |
| Architect (Bengaluru) | `anita.rao@sketchsquare.local` | `Architect@123` | APPROVED |
| Architect (Delhi) | `vikram.malhotra@sketchsquare.local` | `Architect@123` | APPROVED |
| Architect (Jaipur) | `meera.shekhawat@sketchsquare.local` | `Architect@123` | APPROVED |
| Architect (Kolkata) | `rohan.pending@sketchsquare.local` | `Architect@123` | PENDING, has an open verification request |

Data: 6 categories, 15 PUBLISHED drawings (plots 20x30 … 100x200 ft, ₹0 – ₹59,999; four are free and carry reviews so ratings are
populated), 1–4 sheets each. Sheet originals go to the `originals` bucket (`drawings/<drawingId>/<sheetId>.png`), watermarked
placeholder previews for `isPreview` sheets to the `previews` bucket (`drawings/<drawingId>/preview-<sheetId>.png`, with a
dHash in `pHash`), and fake CoA documents to `kyc`.

Reset everything: `npx prisma migrate reset --force` (drops, re-migrates and runs the seed automatically).
