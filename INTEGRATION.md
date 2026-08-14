# Expedion ↔ Expeditoo integration — implementation notes

Companion to `ROADMAP.md`. What was built, how to switch it on, and what is
still unverified.

Work spans two repositories:

| Repo | Role |
|---|---|
| `expedion_encheres` (this one) | Flutter client. Design system, new screens, API client. |
| `expeditoo-ship` | Next.js + PostgreSQL. Schema, quotes API, extraction, escalation. |

---

## 1. What shipped

### Phase C — UI realignment *(complete and verified)*

| Item | Where |
|---|---|
| Colour tokens, light + dark | `lib/flutter_flow/flutter_flow_theme.dart` |
| Plus Jakarta Sans + Geist Mono | same, plus `assets/fonts/GeistMono-*.ttf` |
| Shape / spacing / motion tokens | `FFRadius`, `FFSpacing`, `FFMotion` |
| Material chrome derived from tokens | `FlutterFlowThemeData.toThemeData` |
| Component parity library | `lib/design_system/` |
| Quote card rebuilt on the parity card | `lib/active_p_a_g_e_s/mes_devis/` |
| Lifecycle stepper re-tokenised | `lib/flutter_flow/devis_status_badge.dart` |
| Legacy palette purged | `#4B39EF` / `#39D2C0` — zero occurrences |

`flutter analyze`: **0 errors** (2944 style infos, down from 3012 at baseline).
`flutter build web --release`: **passes**, both font weights ship.

### Phase A — Data foundation *(written, not run)*

In `expeditoo-ship`:

- `src/db/schema/expedion.ts` — `expedion_quotes` (65 columns) and
  `expedion_quote_events`, plus three enums.
- `src/db/migrations/0001_expedion_quotes.sql` — generated, purely additive:
  no existing table is altered.
- `src/server/{dto,dal,services}/expedion.*` — the standard
  Service → DAL → DB layering.
- `src/app/api/expedion/quotes/**` — list, create, read, patch, accept, events,
  admin.
- `src/scripts/import-airtable-quotes.ts` — the one-time import.

### Phase B — AI and pricing *(written, not run)*

- `expedion-extraction.service.ts` — GPT-4.1 Vision, strict JSON schema, PDF and
  JPEG through the same path, Gemini 2.5 Pro fallback over REST.
- `expedion-sms.service.ts` — Twilio over REST; quote ready, driver assigned,
  delivery update, gardiennage warning.
- Auto-pricing — `expedionService.autoPrice`, reusing Expeditoo's own
  `pricingService` so the two products never quote differently for one journey.
- **Confirmer les détails** — `lib/active_p_a_g_e_s/confirmer_les_details/`.

### Phase D — Escalation and tracking *(written, not run)*

- `expedion-escalation.service.ts` — escalate, auto-escalate sweep, write-back.
- `GET /api/cron/expedion-escalate` — the timer, `CRON_SECRET`-guarded.
- `POST /api/expedion/write-back` — carrier selection and delivery status
  returning to Expedion.
- **Suivi de livraison** — `lib/active_p_a_g_e_s/suivi_de_livraison/`.
- **Compte à rebours de gardiennage** — `lib/design_system/ds_storage_countdown.dart`.

---

## 2. Configuration

### `expeditoo-ship` (`.env`)

```bash
# Bridge auth. The client key authenticates the Expedion *app*; the admin key
# gates repricing, driver assignment, forced escalation and write-back.
EXPEDION_API_KEY=
EXPEDION_ADMIN_API_KEY=

# Account that owns escalated listings, and the category they post under.
EXPEDION_SYSTEM_USER_ID=
EXPEDION_CATEGORY_ID=          # optional; falls back to the "encheres" slug

# Auto-escalation window. Open decision #1 — defaults to 48.
EXPEDION_ESCALATE_AFTER_HOURS=48

OPENAI_API_KEY=                # GPT-4.1 Vision extraction
GEMINI_API_KEY=                # fallback, optional

TWILIO_ACCOUNT_SID=
TWILIO_AUTH_TOKEN=
TWILIO_FROM_NUMBER=

CRON_SECRET=                   # already used by the other cron routes

# One-time import
AIRTABLE_PAT=
AIRTABLE_BASE_ID=appu3jamyzCJRuOjr
AIRTABLE_TABLE=CONTACTS
```

### `expedion_encheres` (build time)

```bash
flutter build web --release \
  --dart-define=EXPEDION_API_BASE_URL=https://app.expeditoo.fr \
  --dart-define=EXPEDION_API_KEY=...
```

`ExpedionApi.isConfigured` is false until both are present, so the app keeps
using the Airtable path during the migration rather than failing at runtime.

---

## 3. Running the migration

```bash
cd ~/Code/expeditoo-ship

pnpm drizzle-kit migrate                              # or db:push in dev
pnpm tsx src/scripts/import-airtable-quotes.ts        # dry run — writes nothing
pnpm tsx src/scripts/import-airtable-quotes.ts --commit
```

The script is idempotent (`airtable_record_id` is unique and every row is
upserted on it), non-lossy (unmapped columns are kept verbatim in
`airtable_fields`), and exits non-zero if the counts do not reconcile — so a
partial import cannot be mistaken for a finished one. Only set Airtable
read-only after it exits 0.

Then schedule the escalation sweep, e.g. in `vercel.json`:

```json
{ "crons": [{ "path": "/api/cron/expedion-escalate", "schedule": "0 * * * *" }] }
```

---

## 4. Decisions taken, and where to change them

| Decision | Value | Where |
|---|---|---|
| Auto-escalation window | 48h | `EXPEDION_ESCALATE_AFTER_HOURS` |
| Ad valorem rate | 1.2%, €5 floor | `AD_VALOREM_RATE` in `expedion.service.ts` |
| Card radius | 16px, not the roadmap's 12px | `DSShape.card` — see §5 |
| Button height | 44px, not Expeditoo's 36px | `DSSize.controlHeight` |
| Status chip radius | 8px, not a pill | matches `badge.tsx` |
| Auction house location type | `other` | `AUCTION_LOCATION_TYPE` |
| Storage warning threshold | 4 days | `DSStorageCountdown.warningThresholdDays` |

Open decisions #2 (Firebase Auth) and #4 (commission on escalated jobs) are
untouched — neither was needed to build any of the above.

---

## 5. Two places the roadmap and the shipped code disagree

**Card radius.** §7 lists "corner radius, cards: 12px". The component the
acceptance test compares against — `ui/card.tsx`, and `home/ui/ListingCard.tsx`
which consumes it — renders Tailwind `rounded-xl`, i.e. 16px. The exit criterion
is the side-by-side test, so `DSShape.card` is 16.0. Flip that one constant to
12.0 if you would rather move Expeditoo instead; do one or the other, because
today the two disagree.

**Button height.** §7 pins 44px for Expedion. Expeditoo's `button.tsx` defaults
to `h-9` (36px). 44px is below neither platform's touch-target minimum and the
roadmap is explicit, so Expedion uses 44 and exposes `DSButtonSize.sm` (36) for
parity where a dense row needs it.

---

## 6. What is **not** verified

Everything in Phases A, B and D is written but has never executed. Specifically
unverified:

- **No migration has been run.** The SQL is generated and reviewed, not applied.
- **No import has been run.** The Airtable mapping is inferred from the field
  names the Flutter app reads; it has not been checked against real records.
  Run the dry run first and read the sample it prints.
- **No API route has been called.** TypeScript compiles clean, but no request
  has hit any of them.
- **No extraction has been performed.** The GPT-4.1 prompt and JSON schema are
  untested against a real bordereau. The dimension-unit heuristic
  (`normaliseDimensions`) in particular is a guess about a failure mode, not an
  observed one.
- **No SMS has been sent**, and the E.164 normaliser has not seen real Airtable
  phone data.
- **No escalation has run**, so the generated listing has never been validated
  against `createListingSchema` at runtime — that is the most likely first
  failure, since it is the strictest contract in the chain.
- **The Flutter screens have not been run against a live API.** They compile and
  the app builds; they have not rendered real data.

`expeditoo-ship` carries 243 pre-existing TypeScript errors in 62 files. None
are in the files added here, and none were introduced. That does mean
`tsc --noEmit` was already failing before this work, so it cannot be used as a
green/red gate for it.

---

## 7. Security note on the bridge key

`EXPEDION_API_KEY` authenticates the *application*, not the end user; the server
pairs it with an `x-expedion-uid` header to decide whose quotes to return. A
`--dart-define` is compiled into the bundle, so **on Flutter web that key is
readable by anyone who opens devtools**, and any holder can read any user's
quotes.

That is acceptable on iOS/Android/macOS — the same trade-off the Airtable PAT
already makes today — but before shipping the web target, either proxy the calls
through a server that holds the key, or complete the Firebase → Better Auth
migration so the route can verify a real user token. Admin operations take a
separate key, so a leaked client key cannot reprice or reassign a job.

---

## 8. Auth migration — Expeditoo Better Auth as primary *(added)*

Open decision #2 is now taken: **Expeditoo's Better Auth is the primary account
system, with Firebase Auth kept as a fallback** so accounts created before the
migration keep working. Nothing outside `lib/auth` changed — identity is still
read through `BaseAuthUser` (`currentUserUid`, `currentUserEmail`, `loggedIn`),
so all 45k lines of page code were untouched by the switch.

### What was added

| Piece | Where |
|---|---|
| Better Auth HTTP client (email, Google, session, sign-out) | `lib/auth/expeditoo/expeditoo_auth_client.dart` |
| `BaseAuthUser` + `AuthManager` over Better Auth, Firebase fallback | `lib/auth/expeditoo/expedion_auth.dart` |
| `authManager` repointed | `lib/auth/firebase_auth/auth_util.dart` |
| Session restore before first frame, merged identity stream | `lib/main.dart` |
| `bearer` plugin + `EXPEDION_APP_ORIGINS` | `expeditoo-ship/src/lib/auth.ts` |

### Why the server needed changing

Better Auth is cookie-first. Flutter has no cookie jar on native targets, so
`bearer()` was added: the server now returns the session token in a
`set-auth-token` header on sign-in and accepts `Authorization: Bearer <token>`
afterwards. This is additive — the browser cookie flow Expeditoo's own Next.js
app uses is untouched, and a request with no bearer header behaves as before.

Expedion's web origin also had to join `trustedOrigins`, or Better Auth rejects
its sign-in POSTs as cross-origin. It is read from an env var rather than
hard-coded because the web build moves between preview, production and
localhost.

### Configuration

`expeditoo-ship` (`.env`):

```bash
# Comma-separated. Every origin the Expedion web build is served from.
EXPEDION_APP_ORIGINS=https://expedion-encheres.vercel.app,http://localhost:8080

# Already required for the Google provider Better Auth exposes.
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
```

`expedion_encheres` (build time) — one define now covers both the quotes API
and auth, since the same Next.js app serves them:

```bash
flutter build web --release \
  --dart-define=EXPEDION_API_BASE_URL=https://app.expeditoo.fr
```

`ExpeditooAuthClient.isConfigured` is false without it, and every sign-in falls
through to Firebase, so an unconfigured build still runs.

### Fallback rules

The fallback is deliberately narrow. Firebase is tried only when Expeditoo says
it does not know these credentials (`USER_NOT_FOUND`,
`INVALID_EMAIL_OR_PASSWORD`) or the build has no Expeditoo config
(`NOT_CONFIGURED`). It is **not** tried when Expeditoo answered but refused —
an unverified address surfaces as itself rather than being retried and
reported as a wrong password.

### Google

Native targets use `google_sign_in` to get a Google ID token on-device and
exchange it at `POST /api/auth/sign-in/social` with `{provider, idToken}`, so
the visitor never leaves the app and lands on the same account row a web
visitor would. Web has no ID token from that plugin, so it uses Firebase's
popup. A dismissed Google sheet returns null without falling through, so
cancelling does not open a second dialog.

### Still unverified

- **No request has been made against a live Better Auth instance.** The client
  compiles and the app builds; the endpoint shapes are read from
  `better-auth@1.4.6`'s own schemas, not observed.
- **The `bearer` plugin has not been exercised.** In particular the
  `set-auth-token` header name is Better Auth's documented one but has not been
  seen on a real response.
- **No Google exchange has run**, so the ID-token path is untested end to end.
- **Firestore under Better Auth.** `currentUserDocument` is a Firestore
  `UsersRecord` and is null when the session comes from Expeditoo, so the 19
  files that read it degrade to empty values. Sign-up's Airtable and Firestore
  side effects are guarded on `currentUserReference` and simply skip. Repointing
  those reads at Postgres is the remaining work.
