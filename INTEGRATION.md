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

### Phase C — UI realignment *(shape/spacing complete and verified; colour + font did not converge — see §5)*

| Item | Where |
|---|---|
| Shape / spacing / motion tokens | `FFRadius`, `FFSpacing`, `FFMotion` — 8/6/12px radius, 16px card padding floor |
| UI font, body | `Geist` (bundled OFL asset, not `google_fonts` — see §5) |
| Mono font (numerals/codes) | `Geist Mono`, `assets/fonts/GeistMono-*.ttf` |
| Colour tokens, light + dark | `XpdPalette` (`lib/design_system/ds_palette.dart`) — see §5 |
| Material chrome derived from tokens | `FlutterFlowThemeData.toThemeData` |
| Component parity library | `lib/design_system/` |
| Quote card rebuilt on the parity card | `lib/active_p_a_g_e_s/mes_devis/` |
| Lifecycle stepper re-tokenised | `lib/flutter_flow/devis_status_badge.dart` |
| Legacy FlutterFlow palette purged | `#4B39EF` / `#39D2C0` — zero occurrences |

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

The escalation sweep is already scheduled — not via `vercel.json` (Hobby caps
crons at 2/project, once a day), but via `expeditoo-ship/.github/workflows/scheduled-jobs.yml`,
which hits `/api/cron/expedion-escalate` every 10 minutes:

```yaml
- cron: "*/10 * * * *" # expedion-escalate
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

## 5. Four places the roadmap and the shipped code disagree

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

**UI font.** §7 pins Plus Jakarta Sans via `google_fonts`. The shipped app uses
`Geist` instead — a bundled OFL asset, not a `google_fonts` call —
`flutter_flow_theme.dart`'s own comment gives the reason: Geist isn't in
`google_fonts` 6.3.3, so bundling avoids a runtime font fetch. Unlike the two
entries above, this one wasn't a documented trade-off at the time — it just
never got reconciled with §7, and the acceptance test ("same font... if a
stranger can tell which app is which from the chrome alone, it is not done")
currently fails on this axis. Pick one: bundle Plus Jakarta Sans as a static
asset (same avoid-runtime-fetch property Geist has) to actually hit parity, or
update §7 to adopt Geist as Expedion's font and drop the parity requirement for
this token specifically.

**Colour tokens.** §7 specifies primary `#076BE3`, background `#FCFCFC`/`#010408`
(Expeditoo's oklch tokens in hex). The shipped `XpdPalette`
(`lib/design_system/ds_palette.dart`) uses primary `#0052FF`, background
`#F4F5F8`/`#08090B` instead — its own pre-existing brand colours, correctly
mirrored by `web/index.html`'s `theme-color` meta tags (so at least the web
shell and the app agree with *each other*, just not with §7). Same open call as
the font: migrate `XpdPalette` to the Expeditoo hex values, or update §7 to
formally adopt the Xpd palette.

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

---

## 9. Airtable removed from the quote path *(added)*

### What moved

| Screen | Was | Is |
|---|---|---|
| Mes devis — list, search, counters | 4 Airtable requests | `QuoteRepository.list()`, one request |
| Mes paiements — total, count, rows | hardcoded strings | derived from the client's paid quotes |
| Nouveau bordereau — submit | `CreateAirtableQuoteFromDoc` | `POST /api/expedion/quotes` |
| Nouveau bordereau — render gate | `GetPrice` on Airtable | removed; the server auto-prices |

New client files: `lib/backend/expedion_api/expedion_quote.dart` (typed row +
`formatCents`) and `quote_repository.dart` (the one place screens read quotes).

### Two real bugs this fixed

**"New slip" did nothing.** Two causes, both now gone. The button's `InkWell`
wrapped only the 28px `+` glyph, so pressing the tile around it did nothing at
all. And the destination form sat behind a `FutureBuilder` on Airtable's
`GetPrice` table whose response was *never read* — it only gated rendering, so
with no `AIRTABLE_PAT` configured the future never completed and the page stayed
on a spinner forever.

**Submit failures were invisible.** The old handler called Airtable and
navigated away without inspecting the result, so a rejected quote looked exactly
like a filed one. The new handler reports the failure, keeps the form intact,
and routes to sign-in when that is the cause.

### Auth: sessions, not shared keys

`requireExpedionCaller` now resolves a Better Auth session first and only falls
back to `EXPEDION_API_KEY` + `x-expedion-uid` for clients that have none. Two
consequences:

- **Admin is a role, not a secret.** It is read from the same `admin` role the
  web app uses, rather than inferred from which key was presented.
- **The web build should carry no key.** Sessions are safe in a browser bundle;
  a compiled-in key that lets any holder claim any UID is not. Leave
  `EXPEDION_API_KEY` unset for web.

`ExpedionCaller.firebaseUid` is renamed `userId`, and the service's caller
parameter is `ExpedionCallerIdentity`. The `expedion_quotes.firebase_uid`
column keeps its name — it now means "owner", and renaming it is a migration.

### Escalation — already wired, unchanged

`markPaid` stamps `escalateAfter` (`EXPEDION_ESCALATE_AFTER_HOURS`, default 48).
`findDueForEscalation` selects quotes past that stamp **with
`assigned_carrier_id IS NULL`**, and `/api/cron/expedion-escalate` runs every 10
minutes per `expeditoo-ship/.github/workflows/scheduled-jobs.yml` (GitHub
Actions, not Vercel Cron), turning each into an Expeditoo listing. So a paid
quote with no driver becomes a job automatically. None of this needed changing;
none of it has been observed running.

### Still unverified

Everything above compiles (`flutter analyze`: 0 errors; `tsc --noEmit`: 0
errors) and the web target builds, but **no request has been made against a
running Expeditoo instance**. Specifically: no quote has been created, no list
has been fetched, no session token has been exchanged, and the escalation cron
has never fired. The first end-to-end run needs
`--dart-define=EXPEDION_API_BASE_URL=…` pointed at a deployment whose
`EXPEDION_APP_ORIGINS` includes the Expedion origin.

### Screens still on Airtable

`formulaire_demande_de_devis_retrait_aux_encheres`, `form_devis_paiement_directe`,
`s_inscrire` (guarded — skips when there is no Firebase session), and everything
under `pages_areviser/`. These were not touched.

---

## 10. Environment checklist — what Expedion still needs, and what it does not

Audited by reading every `String.fromEnvironment` in `lib/` and tracing which
API call classes are still reached from a screen. "Dead" below means no widget
references the call any more, so the credential is unused at runtime.

### Expedion (Flutter `--dart-define`)

| Variable | Status | Notes |
|---|---|---|
| `EXPEDION_API_BASE_URL` | **optional** | Override only. Debug builds default to `http://localhost:3000`; release builds (`kReleaseMode`) default to the deployed `expeditoo-ship` instance (`ExpedionConfig._vercelDeployment`) — fixed in `6a0a43a`. Leave unset unless pointing at something other than that deployment. |
| `EXPEDION_API_KEY` | **do not set on web** | Legacy app-level key for Firebase-era clients. Any holder can claim any UID, so it must never reach a browser bundle. Sessions replace it. |
| `PAYMENT_SERVER_URL` | **optional** | Override only. A release web build calls its own origin — the Stripe endpoints ship with this repo as Vercel functions (`api/create-checkout-session`, `send-payment-email`, `confirm-payment`, shared core in `api/_payment_core.js`; `tools/local_payment_server.js` runs the same handlers on :4242 for dev, which stays the non-release default). The functions read `STRIPE_SECRET_KEY`, `EXPEDION_API_BASE_URL`, `EXPEDION_ADMIN_API_KEY`, and optionally `RESEND_API_KEY`/`RESEND_FROM` from the **expedion-encheres** Vercel project's runtime env. |
| `APP_PUBLIC_URL` | **optional** | Stripe Checkout return URL. Web falls back to the page's own origin. |
| `AIRTABLE_PAT` | **still required** | Six screens below still read Airtable. Drop it once they are repointed. |
| `AIRTABLE_PAT_TRANSPORTEURS` | **dead — remove** | Its only consumer is `NewTransporteurCall`, which no screen calls. |

### Screens still on Airtable (the only reason `AIRTABLE_PAT` survives)

| Screen | Call |
|---|---|
| `s_inscrire` | `NewclientSignUpDMCall`, `GetAirtableUserIDCall` |
| `espace_personnel` | `GetUserCall` |
| `page_modif_info_perso` | `UpdateProfilinfoCall` |
| `contact`, `page_contact_devis` | `PostMessageCall` |
| `page_validation_devis` | `UpdateDevisValiderCall`, `CreatePaymentAitableCall` |
| `paiement`, `paiement_resultat` | `CreatePaymentAirtableCall`, `MarkQuotePaidCall` |
| `form_devis_paiement_directe`, `pages_areviser/*` | `GetPriceCall`, `AirtableQuotePayDirectCall` |

Already dead, safe to delete with their call classes: `GetClientQuotesCall`,
`GetClientPaymentsCall`, `CreateAirtableQuoteFromDocCall`, `PostDDallFieldsCall`,
`NewTransporteurCall`, `UpdatePropositionTansporteurCall`.

### Expeditoo (`expeditoo-ship/.env.local`, and Vercel)

| Variable | Why |
|---|---|
| `POSTGRES_URL` | The shared database. Also what the migration scripts read. |
| `NEXT_PUBLIC_APP_URL` | Better Auth `baseURL`, and the first allowed CORS origin. |
| `EXPEDION_APP_ORIGINS` | **added** — comma-separated origins Expedion is served from. Feeds both Better Auth `trustedOrigins` and the CORS allowlist in `proxy.ts`. Not needed for local dev: any `http://localhost:<port>` is allowed outside production. |
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | Google sign-in, shared by both apps. |
| `EXPEDION_API_KEY` | Only for legacy Firebase clients. Server-side only. |
| `EXPEDION_ADMIN_API_KEY` | Repricing, driver assignment, forced escalation, write-back. |
| `EXPEDION_SYSTEM_USER_ID` / `EXPEDION_CATEGORY_ID` | Owner and category for escalated listings. |
| `EXPEDION_ESCALATE_AFTER_HOURS` | Auto-escalation window (default 48). |
| `CRON_SECRET` | Guards `/api/cron/expedion-escalate`. |
| `OPENAI_API_KEY` (+ `GEMINI_API_KEY`) | Bordereau extraction. |
| `TWILIO_*` | Quote/driver/delivery SMS. |
| `AIRTABLE_PAT` | **one-off only** — the import script. Not needed at runtime; do not add it to Vercel. |

### Database state

The schema was out of sync with the code: it had been built by `db:push`
against an older generation. Nine tables were missing (`carriers`,
`carrier_documents`, `carrier_drivers`, `vehicles`, `offers`, `payouts`,
`photos`, plus the two Expedion ones) and seven exist that the schema no longer
declares (`transporter_profiles`, `bids`, `orders`, `earnings`,
`listing_images`, `driver_applications`, `shipment_proposals`).

All nine missing tables now exist, applied additively — created only if absent,
with constraints and indexes applied only to tables created in the same run, so
no foreign key was ever added to a populated table. **The seven orphaned tables
were left untouched**; dropping them is a data decision, not a schema one.
`pnpm db:migrate` still cannot run, because drizzle's journal has no record of
the baseline.
