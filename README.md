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

## Features

- **Authentication** — signup/login, Admin-gated account activation, password strength validation, Enter-to-submit forms.
- **Dashboard** — company-wide stats (Projects, Employees, Open/Closed Tickets), a role-aware 5th "My Tickets" card for Engineers, a ticket status chart, and a role-scoped Recent Tickets feed.
- **Projects** — searchable/filterable list, Admin-only creation, edit restricted to Admin or the assigned Manager, no deletion (projects are marked `Completed` instead — see Design Decisions).
- **Employees** — Admin-only directory built directly on the `users` collection (no separate schema); role assignment, account activation, and a skills tag editor.
- **Tickets** — the core feature: searchable/filterable list (role-scoped visibility), full create/edit, dedicated Assign Engineer and Change Status actions, a comment thread, and a visual Activity Timeline logging every mutation automatically.
- **Security** — every permission is enforced server-side via Firestore Security Rules, including field-level restrictions (e.g. an Engineer can change a ticket's status but not its title), not just hidden UI buttons.
- **Resilience** — Firebase Web's auth-token propagation timing gap is handled with automatic silent retries on live data streams, and manual Retry actions surface if a genuine issue persists.
- **Automated tests** — service-layer unit tests using `fake_cloud_firestore`, covering ticket creation, status changes, and activity-log side effects.

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
│   ├── providers/        # firestoreProvider (shared Firebase DI, points at the "filoi" database)
│   ├── router/            # go_router config + auth-aware redirect guard
│   ├── theme/              # Material 3 theme
│   ├── utils/               # withRetry — shared Firestore stream retry helper
│   └── widgets/            # AppShell (role-aware sidebar + persistent layout)
├── shared/
│   └── enums/               # UserRole, ProjectStatus, TicketStatus, TicketPriority
└── features/
    ├── auth/                  # AppUser model, AuthService, providers, Login/Signup screens
    ├── dashboard/          # stats providers, screens, widgets
    ├── projects/             # CRUD, list/detail/form screens, providers, widgets
    ├── employees/           # directory + activation, backed by the users collection
    └── tickets/                # CRUD, comments + activity subcollections, providers, widgets

test/
└── features/tickets/       # TicketService unit tests (fake_cloud_firestore)
```

---

## Roles & Permissions

Three internal roles: **Admin**, **Project Manager**, **Engineer**. There is no external/client-facing account — clients report issues to their Project Manager (or whichever employee fields the call/email), who logs tickets on their behalf via the optional `reportedBy` field.

Role enforcement is **Firestore-only** (no Cloud Functions): a `role` field lives on each user's `users/{uid}` document, and Firestore Security Rules independently verify it server-side before allowing writes — a client can never self-promote its own role. Several rules also enforce **field-level** restrictions (e.g. an assigned Engineer can change a ticket's `status` but not its `title`/`description`) using Firestore's `diff().affectedKeys()` mechanism.

New signups default to `role: engineer`, `isActive: false`. An Admin must activate the account (and assign the real role) via the Employees screen before the user can access the app.

| Action | Who |
|---|---|
| Create a project | Admin only |
| Edit a project | Admin, or the project's assigned Manager |
| Delete a project | **Nobody** — projects are never deleted (see Design Decisions) |
| Reassign a project's Manager | Admin only |
| Create a ticket | Any active authenticated user, for any project |
| Edit ticket title/description/priority | Ticket creator, Admin, Project Manager |
| Assign an engineer to a ticket | Admin, Project Manager |
| Change a ticket's status | Admin, Project Manager, or the ticket's assigned Engineer |
| Delete a ticket | Admin only |
| Comment on a ticket | Any active authenticated user |
| Manage employees, activate accounts, assign roles | Admin only |

### Ticket & Project Visibility Scoping

Beyond write permissions, *what each role sees* in the Tickets list (and Dashboard's Recent Tickets) is also scoped:

- **Admin** — sees all tickets and projects, unrestricted.
- **Project Manager** — sees only tickets belonging to project(s) they manage.
- **Engineer** — sees only tickets assigned to them.

This keeps each role's view focused on their actual scope of responsibility, while Admin retains full oversight.

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

   > Note: this project's Firestore database is named `filoi`, not the standard `(default)`. `lib/core/providers/firebase_providers.dart` points at that database ID explicitly — update it if your own database uses a different ID.

5. Run the app:
   ```bash
   flutter run -d chrome
   ```

6. **Bootstrap your first Admin account**: sign up normally through the app, then manually edit your user document in the Firestore Console — set `role` to `"admin"` and `isActive` to `true`. Every subsequent user can be activated properly through the app's Employees screen.

### Running tests

```bash
flutter test
```

---

## Project Status

| Module | Status |
|---|---|
| Authentication (signup, login, role-based routing, password validation) | ✅ Complete |
| Dashboard (stats, chart, recent tickets, role-scoped "My Tickets") | ✅ Complete |
| Projects (list/detail/edit, Admin-gated create, no delete) | ✅ Complete |
| Employees (directory, activation, role/skills management) | ✅ Complete |
| Tickets (CRUD, assignment, status, comments, activity timeline) | ✅ Complete |
| Automated tests | ✅ Core service coverage complete |
| Manual QA pass (all three roles) | ✅ Complete |
| Deployment |  ✅ Complete |

---

## Notes on Design Decisions

- **Denormalized display fields** (e.g. `managerName` on a project, `projectName`/`assignedEngineerName` on a ticket) — Firestore has no joins, so names needed for table/list display are stored alongside the reference ID to avoid N+1 reads. Traded off against staleness if a user's name changes, which is rare enough in an internal tool to be an acceptable tradeoff.
- **Comments and activity log as subcollections** of `tickets/{id}`, not arrays on the ticket document — avoids the 1MB document cap and allows independent pagination.
- **Dashboard counts** use Firestore's aggregate `.count()` queries rather than a maintained stats document, avoiding a class of "aggregate doc out of sync" bugs at the cost of slightly more read operations — an acceptable tradeoff at this app's scale.
- **Projects are never deleted.** Every ticket references a project by ID; deleting a project would orphan its tickets' historical references. A project that's finished simply moves to `Completed` status instead, preserving a permanent record.
- **Firebase Web auth-token propagation gap.** Right after login (or a background token refresh), Firestore reads can briefly fail even though the security rules would correctly allow them a moment later. A shared `withRetry()` helper wraps every live Firestore stream with a short, silent retry (up to ~3 attempts) before surfacing a real error with a manual Retry action — avoiding both a confusing false error on login and an infinite silent retry that would mask a genuine problem.

## Possible Future Improvements

Deliberately out of scope for this build, but natural next steps for a production version:
- **OAuth (Google Sign-In)** — would remove password management entirely; held off given the setup/testing risk this late in the build.
- **A "viewed/edited by" audit trail on Projects and Employees**, mirroring the Ticket Activity Timeline.
- **Cloud Functions-backed custom claims** for role enforcement, instead of Firestore-only rules — more tamper-resistant, at the cost of added infrastructure.