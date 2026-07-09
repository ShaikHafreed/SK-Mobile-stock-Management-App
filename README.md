# SR Mobiles — Stock Management System

A full-stack inventory, billing, and operations app for a mobile accessories retail shop. Built to replace manual, paper-based stock tracking — used daily to run real business operations: inventory, point-of-sale billing, barcode scanning, and reporting.

**Live backend:** [`https://stock.hafreedshaik.online/api/health`](https://stock.hafreedshaik.online/api/health) (custom domain, proxied through Vercel — also reachable directly at [`backend-three-murex-79.vercel.app/api/health`](https://backend-three-murex-79.vercel.app/api/health))

> This is a private business application — the app itself is not published to the Play Store (Play Store release is prepped and ready, pending submission), and the database contains real shop inventory data. The health-check link above is public and safe to share; it doesn't expose any data, and every other route requires an API key.

## Installing the app (sideload)

The Android app isn't on the Play Store yet, so it's installed directly as a signed APK:

1. On the Android phone, get the `app-release.apk` file from whoever built it (shared via WhatsApp, Drive, USB, etc.) and open it from Downloads/Files.
2. If prompted, allow installs from that source: **Settings → Apps → Special access → Install unknown apps**, enable it for the app you used to open the file (Chrome, Files, WhatsApp).
3. Tap **Install**, then open the app and log in.
4. If a previous debug build of the app is already on the phone, uninstall it first — a release build is signed with a different key, and Android refuses to install over a mismatched signature (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`).

Built with `flutter build apk --release` from `sk_mobiles/`; output lands at `sk_mobiles/build/app/outputs/flutter-apk/app-release.apk`.

## Features

- **Inventory management** — CRUD across multiple product categories (mobile covers, chargers, cables, earphones, earbuds, temper glass, and custom categories), with camera/gallery photo uploads
- **Barcode scanning** for fast product lookup
- **Billing** — GST-calculated bills with a preview screen and one-tap WhatsApp bill sharing
- **Excel import/export** — per-category or full-inventory reports, downloadable to device
- **Global search** with debounced queries and filter chips
- **Activity logs** — full audit trail of who changed what
- **Auth** — username/password (JWT), Google Sign-In, and phone OTP, with admin/staff roles
- **Dashboard** — live stock stats, low-stock alerts, quick actions
- **Profile management** — editable name and avatar
- **Dark / Light / System theme**

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile app | Flutter (Android), Riverpod, go_router |
| Backend | Python Flask (app factory + blueprints), Gunicorn |
| Database | PostgreSQL via Supabase |
| Storage | Supabase Storage |
| Auth | Flask-JWT-Extended + Firebase Auth (Google Sign-In, Phone OTP) |
| Deployment | Vercel (serverless Python runtime) |

## Project Structure

```
├── backend/                  → Flask REST API
│   ├── api/index.py          → Vercel serverless entrypoint
│   ├── app/
│   │   ├── models/           → SQLAlchemy models
│   │   ├── routes/           → auth, products, categories, temper_glass, excel, logs, search
│   │   └── utils/            → auth helpers, Excel generation, Supabase storage helpers
│   ├── config.py
│   ├── run.py                → local dev entrypoint
│   └── vercel.json
└── sk_mobiles/                → Flutter app
    └── lib/
        ├── core/              → network client, router, theme, constants, shared widgets
        ├── features/          → auth, dashboard, products, billing, barcode, excel, search,
        │                        temper_glass, logs, profile
        └── models/
```

## Getting Started

### Backend

```bash
cd backend
python -m venv venv
venv\Scripts\activate        # Windows
pip install -r requirements.txt
cp .env.example .env         # fill in Supabase + secret key values
python run.py
```

The API runs on `http://localhost:5000/api`.

**Database connection note:** use Supabase's connection pooler (`aws-<cluster>-<region>.pooler.supabase.com`, user `postgres.<project-ref>`), not the direct `db.<project-ref>.supabase.co` host — the direct host resolves to an IPv6-only address, which fails on IPv4-only environments (including this app's Vercel deployment).

### Flutter app

```bash
cd sk_mobiles
flutter pub get
flutter run
```

Update `lib/core/constants/app_constants.dart` to point `baseUrl` at your backend (local IP, ngrok tunnel, or a deployed URL).

### Deploying the backend to Vercel

```bash
cd backend
vercel env add SECRET_KEY production
vercel env add JWT_SECRET_KEY production
vercel env add SUPABASE_URL production
vercel env add SUPABASE_SECRET_KEY production
vercel env add DB_USER production        # postgres.<project-ref>
vercel env add DB_HOST production        # aws-<cluster>-<region>.pooler.supabase.com
vercel env add DB_PORT production        # 5432
vercel env add DB_NAME production        # postgres
vercel env add DB_PASSWORD production
vercel deploy --prod
```

## Security

- Secrets live in `backend/.env` (gitignored) locally and in Vercel's encrypted environment variables in production — never committed.
- Row-Level Security is enabled on all database tables.
- All API routes (except `/api/health`) require an API key header, in addition to JWT auth on user-specific routes.

## License

Private/proprietary — all rights reserved.
