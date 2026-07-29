# Filoi Enterprise Operations Portal

An internal enterprise operations portal for managing projects, employees, and support tickets — built as a realistic internal tool that a company like Filoi (DHIS2 / Health Information Systems / IT services) could plausibly run internally.

This is a portfolio/internship project, **not** an attempt to recreate any real Filoi system.

---

## Tech Stack

- **Flutter Web** — UI framework
- **Firebase Authentication** — email/password auth
- **Cloud Firestore** — database
- **Riverpod** — state management
- **go_router** — declarative, URL-based routing
- **fl_chart** — dashboard charts

---

## Architecture

Four-layer separation, feature-first folder structure:

```
UI (Widgets/Screens)
   ↓ watches/reads
Riverpod Providers (state + orchestration)
   ↓ calls
Services (the only layer that imports Firebase SDKs)
   ↓ reads/writes
Models (pure Dart, no Firebase dependency)
```

Nothing outside `services/` imports `cloud_firestore` or `firebase_auth` directly. This keeps the UI layer testable and Firebase-agnostic, and keeps business logic out of widgets.

### Folder structure

```
lib/
├── main.dart
├── core/
│   ├── providers/        # firestoreProvider (shared Firebase DI)
│   ├── router/            # go_router config + auth-aware redirect guard
│   ├── theme/              # Material 3 theme
│   └── widgets/            # AppShell (sidebar + persistent layout)
├── shared/
│   └── enums/               # UserRole, ProjectStatus, TicketStatus, TicketPriority
└── features/
    ├── auth/                  # models, services, providers, screens
    ├── dashboard/          # stats providers, screens, widgets
    ├── projects/             # CRUD: models, services, providers, screens, widgets
    ├── employees/           # (in progress)
    └── tickets/                # (in progress)
```

---

## Roles & Permissions

Three internal roles: **Admin**, **Project Manager**, **Engineer**. There is no external/client-facing account — clients report issues to their Project Manager, who logs tickets on their behalf.

Role enforcement is **Firestore-only** (no Cloud Functions): a `role` field lives on each user's `users/{uid}` document, and Firestore Security Rules independently verify it server-side before allowing writes — a client can never self-promote its own role.

New signups default to `role: engineer`, `isActive: false`. An Admin must activate the account (and optionally change the role) before the user can access the app.

| Action | Who |
|---|---|
| View projects/tickets | Any active authenticated user |
| Create/edit/delete projects | Admin, Project Manager |
| Create tickets | Any active authenticated user |
| Assign engineer / delete ticket | Admin, Project Manager (delete: Admin only) |
| Manage employees, activate accounts | Admin only |

---

## Getting Started

### Prerequisites
- Flutter SDK (3.8+)
- A Firebase project with **Authentication (Email/Password)** and **Cloud Firestore** enabled
- The [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/): `dart pub global activate flutterfire_cli`

### Setup

1. Clone the repo and install dependencies:
   ```bash
   flutter pub get
   ```

2. Connect the app to your own Firebase project (this generates `lib/firebase_options.dart`, which is intentionally gitignored — it's config, not something meant to ship checked into a shared repo):
   ```bash
   flutterfire configure
   ```
   Select **Web** as a platform.

3. In the Firebase Console, enable:
   - **Authentication → Email/Password** provider
   - **Firestore Database** (start in production mode)

4. Publish the security rules from `firestore.rules` (in this repo) via the Firestore Console's **Rules** tab.

   > Note: if your Firestore database was created with a non-default database ID (Firebase now supports multiple named databases per project), update `lib/core/providers/firebase_providers.dart` to point at the correct `databaseId`.

5. Run the app:
   ```bash
   flutter run -d chrome
   ```

6. **Bootstrap your first Admin account**: sign up normally through the app, then manually edit your user document in the Firestore Console — set `role` to `"admin"` and `isActive` to `true`. Every subsequent user can be activated properly through the app's Employee Management screen.

---

## Project Status

| Module | Status |
|---|---|
| Authentication (signup, login, role-based routing) | ✅ Complete |
| Dashboard (stats, chart, recent tickets) | ✅ Complete |
| Projects (CRUD, search, filter) | ✅ Complete |
| Project detail / edit | 🚧 In progress |
| Employees | ⬜ Planned |
| Tickets (core feature: CRUD, comments, activity timeline) | ⬜ Planned |
| Testing | ⬜ Planned |

---

## Notes on Design Decisions

- **Denormalized display fields** (e.g. `managerName` on a project, `projectName`/`assignedEngineerName` on a ticket) — Firestore has no joins, so names needed for table/list display are stored alongside the reference ID to avoid N+1 reads. Traded off against staleness if a user's name changes, which is rare enough in an internal tool to be an acceptable tradeoff.
- **Comments and activity log as subcollections** of `tickets/{id}`, not arrays on the ticket document — avoids the 1MB document cap and allows independent pagination.
- **Dashboard counts** use Firestore's aggregate `.count()` queries rather than a maintained stats document, avoiding a class of "aggregate doc out of sync" bugs at the cost of slightly more read operations — an acceptable tradeoff at this app's scale.
