# SK Mobiles Stock Manager — Master Context

## What this project is
Full-stack stock management app for a mobile accessories shop (SK Mobiles).
Owner manages inventory, billing, barcode scanning, Excel exports, and WhatsApp
bill sharing from an Android phone. Built over multiple days with AI assistance.

## Tech Stack
- Frontend: Flutter (Dart) — Android app, tested on Samsung SM-S908E
- Backend: Python Flask REST API (app factory pattern, blueprints)
- Database: Supabase PostgreSQL (project: gbqbepopvpkjozyrivwz)
- Storage: Supabase Storage, public bucket `sk-mobiles-images`
- Auth: Flask JWT + X-API-Key middleware; Firebase Auth in app
  (username/password via backend, Google Sign-In, Phone OTP)
- Tunneling: ngrok (https://smudgy-imminent-hankie.ngrok-free.dev)
- State management: flutter_riverpod (StateNotifierProvider)
- Routing: go_router with auth redirect

## Project Location
c:\Users\shaik\OneDrive\Documents\GitHub\SK-Mobile-stock-Management-App\
├── backend/          → Flask API
│   ├── app/__init__.py       (app factory + API key middleware + ngrok headers)
│   ├── app/models/           (user, category, product, temper_glass, activity_log)
│   ├── app/routes/           (auth, products, categories, temper_glass, excel, logs, search)
│   ├── app/utils/            (auth_helpers, excel_generator, storage_helper, image_upload)
│   ├── config.py, run.py, seed.py, .env (NOT in git), .env.example
└── sk_mobiles/       → Flutter app
    └── lib/
        ├── main.dart
        ├── core/constants/app_constants.dart   (baseUrl, apiKey, storage keys)
        ├── core/network/api_client.dart        (Dio + JWT + API key + ngrok header)
        ├── core/providers/theme_provider.dart  (AppThemeMode enum lives HERE only)
        ├── core/router/app_router.dart
        ├── core/theme/app_theme.dart
        ├── core/utils/image_upload_helper.dart
        ├── core/utils/whatsapp_share.dart
        ├── features/auth|dashboard|products|temper_glass|search|excel|logs|barcode|billing|profile/
        └── models/ (user_model, product_model, category_model, temper_box_model)

## Key Config Values
- Local API: http://192.168.31.229:5000/api (check ipconfig if IP changed)
- API key header: X-API-Key: sk-mobiles-api-key-2024-hafreed
- ngrok header required: ngrok-skip-browser-warning: true
- App logins: admin/admin123 (admin), staff/staff123 (staff)
- Firebase project: sk-mobiles (sk-mobiles-c5608), package com.skmobiles.sk_mobiles
- google-services.json at sk_mobiles/android/app/
- Supabase DB password is in backend/.env — never commit .env

## Run Commands (3 terminals)
1. cd backend && venv\Scripts\python.exe run.py   (venv created 2026-07-05 on this machine; requirements.txt now includes `supabase`, no longer `cloudinary`)
2. ngrok http 5000
3. cd sk_mobiles && flutter run   (Flutter SDK is NOT installed on this machine as of 2026-07-05 — install it before running this)

## Features DONE
Login (glassmorphism UI, Remember Me, Google Sign-In, Phone OTP UI),
Dashboard (stats, quick actions, categories grid, low stock alerts),
Products CRUD with camera/gallery image upload, Temper Glass box manager,
Global search (debounced, filter chips), Excel export to Downloads folder
with Open button, Activity logs, Barcode scanner (mobile_scanner, torch),
Billing with GST 18% + bill preview, WhatsApp bill share (wa.me deep link),
Profile page (live stats, theme switcher, quick links), Dark/Light/System theme.

## KNOWN OPEN ISSUES
1. Firebase Phone OTP error 17006 (region block). Test number +918341554694
   code 123456 should be configured in Firebase console. Real SMS needs Blaze plan.
2. Kotlin Gradle Plugin deprecation warning from mobile_scanner (not blocking).
3. **URGENT (as of 2026-07-05): rotate the Supabase Postgres DB password.**
   It was hardcoded in plaintext in `backend/config.py` (tracked in git,
   commits ad2f14e and 3169f4a) in this PUBLIC repo since Day 2. Code is fixed
   to read DATABASE_URL / DB_* from `backend/.env` (gitignored) instead, but
   the actual password is still compromised until reset in the Supabase
   dashboard (Project Settings → Database → Reset database password). After
   rotating, update `backend/.env` locally with the new password.
4. RLS was enabled (2026-07-05) on all 8 public Supabase tables with no
   policies — deny-all for anon/authenticated roles via PostgREST. Backend
   connects as the `postgres` table-owner role so it bypasses RLS and is
   unaffected; verified backend still runs and `/api/auth/login` +
   `/api/products/` work end-to-end after the change.

(Product image thumbnail "No Image" issue — verified against the live DB:
`Product.to_dict()` correctly returns `image_url`, and older products have
valid Supabase Storage URLs. Current "No Image" products (27, 28) simply
never had a photo uploaded — no upload activity-log entry exists for them.
Treat as resolved; it's expected behavior, not a bug.)

## NEXT FEATURES (roadmap)
- Push notifications for low stock (flutter_local_notifications)
- Signed release APK (keystore + build config)
- Sales history / bill records saved in DB (new bills table + routes)
- Dashboard sales analytics (charts)
- Multi-user roles enforcement (admin vs staff permissions in UI)
- Backup/restore, PDF bill export

## MY WORKING RULES (follow strictly)
1. ALWAYS give complete full code files with exact file path — never snippets,
   never "replace this part". I paste whole files.
2. After EVERY working change, commit and push:
   cd "c:\Users\shaik\OneDrive\Documents\GitHub\SK-Mobile-stock-Management-App"
   git add .
   git commit -m "type: short description of change"
   git push origin main
   Repo: https://github.com/ShaikHafreed/SK-Mobile-stock-Management-App.git
   Branch: main. Use conventional commits (feat:, fix:, refactor:, docs:).
   NEVER commit backend/.env (already in .gitignore; history was scrubbed
   with git-filter-repo once — do not reintroduce secrets).
3. Riverpod provider declarations must be single-line
   (multi-line StateNotifierProvider declarations broke the parser before).
4. AppThemeMode enum exists ONLY in core/providers/theme_provider.dart.
5. ListTile inside colored Container needs Material wrapper.
6. Fixed-height containers with dynamic children cause overflow — prefer
   SingleChildScrollView or dynamic AnimatedContainer heights.
7. Android 11+ needs <queries> in AndroidManifest for url_launcher/open_file.
8. Image uploads need X-API-Key + Authorization + ngrok-skip-browser-warning
   headers (see image_upload_helper.dart).
9. At end of each session: give git commit commands + a LinkedIn post
   (under 3000 chars) summarizing the day's work, challenges, solutions, learnings.
10. Explain errors briefly, then fix. Prioritize working code over discussion.

## USE MCPs, SKILLS & AGENT TOOLS (work smart, not manual)

### MCP servers — set these up and USE them
1. Supabase MCP (top priority — our DB lives there):
   claude mcp add supabase -- npx -y @supabase/mcp-server-supabase@latest --project-ref=gbqbepopvpkjozyrivwz
   Use it to: inspect tables, run SQL, check why image_url is null,
   verify migrations, debug data issues — instead of asking me to
   open the Supabase dashboard and paste results.

2. GitHub MCP:
   claude mcp add github -- npx -y @modelcontextprotocol/server-github
   Use it to: create issues for bugs we find, manage the repo,
   check commit history. Repo: ShaikHafreed/SK-Mobile-stock-Management-App

3. Filesystem access: you already have it — read files yourself
   before editing. NEVER ask me to paste file contents; open them.

### Skills — create and reuse
- Create project skills in .claude/skills/ for repeated workflows:
  - flutter-fix: run `flutter analyze`, fix all errors, run
    `flutter build apk --debug`, repeat until clean.
  - api-test: hit backend endpoints with curl (include X-API-Key +
    Authorization headers) and verify JSON shape before touching Flutter code.
  - session-end: git add/commit/push + generate LinkedIn post (<3000 chars)
    + update CLAUDE.md "Features DONE" and "OPEN ISSUES" sections.
- Use subagents for parallel work: one agent fixes backend route while
  another fixes the Flutter model — then integrate.

### Agentic workflow rules
1. VERIFY BEFORE CODING: when a bug spans backend + frontend, first curl the
   API / query Supabase MCP to see the actual response — never guess which
   side is broken.
2. RUN, DON'T ASK: execute flutter analyze, flutter run, python run.py,
   pytest yourself. Read the errors yourself. Iterate until it works.
   Only ask when a physical-device screenshot or a decision is needed.
3. AUTO-COMMIT: after each verified fix → conventional commit → push.
4. PLAN MODE for big features (sales history, push notifications):
   present plan first, wait for OK, then implement end to end.
5. UPDATE THIS FILE: whenever a feature is done or an issue is fixed,
   edit CLAUDE.md so context never goes stale.
