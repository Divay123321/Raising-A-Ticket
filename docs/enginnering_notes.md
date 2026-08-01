> Written as a personal engineering log while building this project — decisions, bugs, and lessons, kept honest rather than polished.

# Engineering Notes — Filoi Enterprise Operations Portal

Internal reference doc, not part of the public README. Written to prep for questions about this project — decisions made, bugs hit and fixed, and concepts learned. Organized so each entry can stand alone as an interview answer.

---

## Architecture Decisions (the "why," not just the "what")

### Why Riverpod over Provider/Bloc
Chosen deliberately to learn it, since it directly transfers to another project (CodeSaathi). Riverpod's provider-depending-on-provider model (e.g. `currentUserProvider` watching `authStateProvider`) gives a reactive dependency graph without manual "refresh" calls — a change at the bottom (Firebase Auth state) automatically cascades to every screen watching derived state above it.

### Why Firestore-only role enforcement, not Cloud Functions / custom claims
Cloud Functions require a separate deploy pipeline, the Blaze billing plan, and a second codebase (Node/TS) to maintain. For a 10-day scope, storing `role` as a Firestore field and checking it in Security Rules (via `get()` calls inside rules) was the pragmatic choice. Trade-off: custom claims are marginally more tamper-resistant since they live on the auth token itself, not a readable document — a real, known trade-off, not an oversight.

### Why denormalized fields (e.g. `managerName` on Project, `projectName`/`assignedEngineerName` on Ticket)
Firestore has no JOINs. Displaying a table of tickets with project names would otherwise require an N+1 read pattern (one read per row to resolve the project name). Copying the display name at write-time avoids that, at the cost of staleness if the source name changes later — acceptable for an internal tool where name changes are rare.

### Why Comments and Activity are subcollections, not arrays on the Ticket doc
Firestore documents cap at 1MB; an array of comments would eventually threaten that ceiling and can't be paginated independently. Subcollections (`tickets/{id}/comments/`, `tickets/{id}/activity/`) scale cleanly and support independent queries/pagination.

### Why Projects are never deleted
Every Ticket stores a `projectId` reference. Deleting a Project would orphan every Ticket that referenced it (broken links, dropdowns that can no longer resolve the name for new tickets). Finished projects move to `ProjectStatus.completed` instead — preserves referential integrity and historical record.

### Why field-level permission checks in Security Rules (`diff().affectedKeys()`)
Some actions share the same underlying Firestore operation (`update()`) but need different permission levels depending on *which fields* changed — e.g. an assigned Engineer may change a ticket's `status` but not its `title`. Rules can't see which app method was called, only what data changed, so the rule inspects `request.resource.data.diff(resource.data).affectedKeys()` and only allows the write if the changed fields match what that role is permitted to touch.

### Why "Employees" has no separate collection/model
Employee data (name, email, role, skills) is identical to what's already stored in `users/{uid}` for auth purposes. A second collection would mean syncing two sources of truth for the same person. `EmployeeService` reads/writes `users` directly, reusing the existing `AppUser` model — a deliberate "not everything needs new schema" decision.

### Why no explicit "team members" field on Project
Considered adding `teamMemberUids` to the Project schema, then intentionally avoided it — a project's active team is fully derivable from "which engineers currently hold tickets under this project," so a stored field would just be a second, syncable source of truth for something already computable.

---

## Real Bugs Encountered (with root cause, not just the fix)

### 1. Firestore writes silently failing — non-default database ID
**Symptom:** Signup appeared to hang; no `users` collection ever appeared in Firestore Console.
**Root cause:** The Firestore database had been created with a custom ID (`filoi`) instead of the standard `(default)`. `FirebaseFirestore.instance` always targets `(default)` — it had nothing to connect to.
**Fix:** Centralized `FirebaseFirestore.instanceFor(databaseId: 'filoi')` behind a single `firestoreProvider`, used everywhere instead of `.instance`.
**Lesson:** Always check the Firestore Console's database dropdown immediately after project creation, before writing any code.

### 2. Firebase Web auth-token propagation race
**Symptom:** Right after login, Firestore reads intermittently failed with permission-denied, even though the Security Rules would correctly allow them a moment later. Manual page refresh always "fixed" it.
**Root cause:** A brief timing gap between Firebase Auth confirming login and the new ID token fully propagating to Firestore's connection — a known, documented Firebase Web SDK quirk, not a rules bug.
**Fix:** A shared `withRetry()` helper (`core/utils/firestore_retry.dart`) wraps every live Firestore stream with up to 3 silent retries (400/800ms backoff) before surfacing a real error with a manual Retry action.
**Lesson:** Distinguish "genuinely broken" from "transient infrastructure timing" — the fix is retry-with-backoff, not error-and-stop, but also not infinite-silent-retry (which would mask a real bug).

### 3. Signup → login flash-redirect race condition
**Symptom:** After signup, briefly flashed to the Dashboard before redirecting to Login.
**Root cause:** `createUserWithEmailAndPassword` immediately fires "logged in" on the auth stream (which the router listens to via `refreshListenable`) — before the very next line (`signOut()`, since new accounts start inactive) had a chance to run. Router reacted to the transient logged-in state before it was undone.
**Fix:** A `authTransitionInProgressProvider` boolean flag, set before the signup/signOut sequence and checked at the top of the router's `redirect` function to suppress redirects during the transition window.

### 4. Sidebar navigation index mismatch by role
**Symptom:** Clicking "Tickets" in the sidebar did nothing for non-Admin users.
**Root cause:** `NavigationDrawer` assigns indices based on which destinations are actually *rendered* — since "Employees" is conditionally hidden for non-Admins, every item after it shifts down one index for those users. The navigation handler had hardcoded `case` numbers assuming Admin's fixed index layout.
**Fix:** Built the routes list with the identical conditional (`if (isAdmin)`) used for the destinations themselves, so indices always stay in sync regardless of role.
**Lesson:** Any UI that conditionally renders a variable number of items before a navigation handler needs index-based logic to derive indices dynamically, not hardcode them.

### 5. `initState()` timing vs. async provider data
**Symptom (design problem, not a runtime crash):** Needed to seed local editable form state (Employee role/skills before Save) from Firestore data — but `initState()` runs before the async fetch resolves, so there's nothing to copy yet.
**Fix:** An `_initialized` boolean flag checked inside `build()`'s `data:` branch — seeds local state from the first successful data emission only, guarding against a live stream re-emitting and silently overwriting in-progress user edits.

### 6. Dashboard stats going stale mid-session
**Symptom:** Employee count on Dashboard didn't update after a new signup, even though the Employees list (a live stream) showed the new count correctly.
**Root cause:** Dashboard stats used a one-time `FutureProvider` aggregate count (deliberate, to avoid a "stats doc out of sync" bug class) — but nothing ever told it to refetch after the first load.
**Fix:** `ref.invalidate(dashboardStatsProvider)` inside `initState()` (via `Future.microtask` to avoid a "setState during build" error) forces a fresh fetch every time the Dashboard screen is actually visited.

### 7. Duplicate/malformed YAML and Firestore Rules files
**Symptom:** `pubspec.yaml` had two `dev_dependencies:` blocks (second silently overriding/conflicting with the first); Firestore Rules file was accidentally pasted twice, nested inside itself.
**Lesson:** Both are the same underlying mistake — copy-pasting a full block into a file that already had that block, without checking for duplication first. Worth a visual scan of top-level keys/braces before publishing config files.

---

## Riverpod Concepts — glossary for interview recall

- **`Provider`** — static/non-changing value, used for dependency injection (e.g. handing out one shared `AuthService` instance).
- **`StreamProvider`** — wraps a live `Stream`, exposes `AsyncValue<T>`, re-emits automatically on new data. Used for anything that should update live (auth state, ticket lists, comments).
- **`FutureProvider`** — wraps a one-off async call, exposes `AsyncValue<T>`. Used for data that doesn't need live updates (e.g. the manager dropdown's user list).
- **`StateProvider`** — simple mutable value, mutated via `.notifier.state = x`. Used for local UI state shared across sibling widgets (search text, active filters).
- **`.family`** — turns a provider into a function taking a parameter, returning an independently-cached provider per argument. Used for "one of many things, selected by ID" (`projectByIdProvider(id)`, `ticketByIdProvider(id)`).
- **`ref.watch` vs `ref.read`** — `watch` subscribes and triggers a rebuild on change (used in `build()`); `read` gets the current value once without subscribing (used in event handlers like `onPressed`).
- **`ref.listen`** — subscribes and runs a side-effect callback on change, without itself causing a rebuild. Used to bridge a Riverpod stream into a non-Riverpod API (`GoRouter`'s `refreshListenable`, a plain `ChangeNotifier`).
- **`AsyncValue.when()` / `.whenData()`** — unpacks loading/data/error states without manually tracking boolean flags; `.whenData()` transforms just the data payload while preserving the surrounding loading/error state.
- **Derived providers** — a plain `Provider` built from `ref.watch`-ing one or more other providers (e.g. `filteredTicketListProvider` combining the raw ticket stream with search/filter state). Recomputes automatically whenever any dependency changes — no manual "reapply filter" step anywhere.
- **Combining multiple `AsyncValue`s manually** — when a derived provider depends on more than one async source at once (e.g. filtering tickets by which projects a PM manages), `.whenData()` alone isn't enough; requires manually checking each `AsyncValue`'s loading/error/data state and combining them.

---

## Testing Approach

Service-layer unit tests using `fake_cloud_firestore` (in-memory fake, no real network calls) — covers `TicketService.createTicket()` (correct field write + automatic activity-log side effect) and `changeStatus()` (status update + correctly-attributed activity entry). Deliberately scoped to service-layer logic rather than widget/integration tests, given the time budget — this is the layer with the most business logic worth protecting against regressions.

Manual QA was structured as a role-by-role checklist (Admin / PM / Engineer) walking every permission boundary designed into the Security Rules — this is where most of the real bugs above were actually caught, since it exercises rules + providers + UI together in a way unit tests alone can't.