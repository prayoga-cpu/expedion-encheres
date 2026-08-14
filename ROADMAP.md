# EXPEDION ENCHÈRES — Roadmap

**Auction-house pickup and shipping, quote-first**
Version 2.0 · 04/08/2026 · PRIONATION.io for Atout Global Services

---

## 1. What this product is

A buyer wins a lot at a French auction house. They upload the *bordereau*, request a *devis*, and Expedion arranges collection and delivery. An admin assigns a driver from the pool. If nobody can take it, the job escalates to Expeditoo where carriers bid.

Expedion is not a competitor to Expeditoo. It is the **auction-specific front door** to the same driver network.

| | |
|---|---|
| Market | France, auction houses (hôtels des ventes) |
| Model | Concierge, curated, quote-first |
| Selection | **Admin selects** the driver |
| Fallback | Escalates to Expeditoo when no driver is available |
| Wedge | Auction houses refuse to ship and charge daily storage after 10 days |

The storage clock is the conversion lever. Accord Enchères charges €1 to €20 per day after day ten and states plainly that they do not ship. Surface that countdown in the app and quotes convert on urgency.

---

## 2. Roles

| Role | Can do |
|---|---|
| **Client** | Register, upload bordereau, request devis, review extracted details, accept quote, pay, track, review |
| **Admin** | Review requests, assign a driver, adjust price, escalate to Expeditoo, manage statuses |
| **Driver** | Shared pool with Expeditoo. Receives assignment, updates status, delivers, gets paid |

---

## 3. Core flow

```
Client uploads bordereau (PDF or photo)
   ↓  AI extracts fields
Confirm details screen
   ↓  client verifies and corrects
Quote generated
   ↓  auto-priced from dimensions, weight, distance
Admin reviews
   ↓
   ├── Driver available  → admin assigns → delivery
   └── No driver         → escalate to Expeditoo → carriers bid → client picks → delivery
   ↓
Status synced to both apps through delivery
```

### AI extraction targets

Proven against real bordereaux from Yssoire Enchères and Accord Enchères:

| Field | Source on the slip |
|---|---|
| Bordereau number | Header |
| Buyer name, address, phone, email | Client block |
| Pickup address | Auction house footer |
| Lot description | Description column |
| **Dimensions** | Inside the description text |
| Declared value | Total TTC |
| Sale date | Vente du |

Dimensions drive the price. Extract, compute volume, run the pricing engine, return a devis with zero typing.

**Model:** GPT-4.1 Vision, single call, JSON schema output. Handles PDF and JPEG identically. Gemini 2.5 Pro as fallback. A confirm-details screen turns model-level accuracy into user-verified accuracy.

---

## 4. Screens

Current French page names in brackets.

| Group | Screens |
|---|---|
| **Public** | Accueil, contact, FAQ |
| **Auth** | Se connecter, s'inscrire, mot de passe oublié |
| **Quote** | Formulaire de devis par bordereau, demande de retrait aux enchères, **confirmer les détails** *(new)*, choix devis, validation devis |
| **Account** | Mes devis, détails devis, mes paiements, espace personnel, modifier infos perso, adresse client, paramètres |
| **Payment** | Paiement, paiement success, paiement cancel |
| **New** | Suivi de livraison *(tracking)*, compte à rebours de gardiennage *(storage countdown)* |

---

## 5. Migration: away from Airtable

| Today | Target |
|---|---|
| Airtable (quotes, carriers) | PostgreSQL, shared with Expeditoo |
| Firestore (users, payments) | PostgreSQL |
| Firebase Auth | Keep for now, migrate later |
| Firebase Storage | Cloudflare R2 |
| Firebase Cloud Functions | Next.js API routes |
| Manual quote entry | AI extraction + confirm screen |
| Manual escalation | Automatic after configured window |

Airtable's paid tier caps records and API rate, and the cost recurs monthly and rises with volume. Postgres costs once. More importantly, escalation across two databases is a distributed transaction, on one database it is a status change.

**The Flutter UI stays.** Only the data layer is repointed. FlutterFlow API calls are configuration, not rewrites.

---

## 6. Tech stack

| Layer | Current | Target |
|---|---|---|
| Frontend | Flutter 3.44 (FlutterFlow) | Unchanged |
| Routing | go_router | Unchanged |
| State | provider | Unchanged |
| Auth | Firebase Auth + Google + Apple | Unchanged this phase |
| Data | Airtable + Firestore | **PostgreSQL via Next.js API** |
| Storage | Firebase Storage | **Cloudflare R2** |
| Server logic | Firebase Cloud Functions | **Next.js API routes** |
| Payments | Stripe (flutter_stripe) | Unchanged |
| AI | none | **GPT-4.1 Vision** |
| SMS | none | **Twilio** |
| Platforms | iOS, Android, macOS, Web | Unchanged |
| Languages | FR + EN | Unchanged |

---

## 7. Design system — align to Expeditoo

Expedion currently ships the stock FlutterFlow palette: `#4B39EF` purple primary, `#39D2C0` teal secondary. That is a template default, not a brand. Replace it wholesale with the Expeditoo system.

### Colour tokens

Set these in `FlutterFlowTheme`. Values are the hex equivalents of Expeditoo's `oklch` tokens, so both apps render the same colour.

| Token | Light | Dark | Replaces |
|---|---|---|---|
| `primary` | `#076BE3` | `#076BE3` | `#4B39EF` |
| `primaryText` on primary | `#FFFFFF` | `#FFFFFF` | — |
| `primaryBackground` | `#FCFCFC` | `#010408` | `#F1F4F8` |
| `primaryText` | `#050C13` | `#E5F0FC` | `#14181B` |
| `secondaryBackground` (card) | `#FFFFFF` | `#0B121A` | `#FFFFFF` |
| `alternate` (border) | `#EAEFF5` | `#212A33` | `#E0E3E7` |
| `secondaryText` | `#606A74` | `#86909B` | `#57636C` |
| `accent1` / input fill | `#F4F9FF` | `#141B24` | — |
| `success` | `#3FB171` | `#3FB171` | `#249689` |
| `warning` | `#D18500` | `#D18500` | `#F9CF58` |
| `tertiary` / accent | `#F6722B` | `#F6722B` | `#EE8B60` |
| `error` | `#ED3151` | `#ED3151` | `#FF5963` |

Remove `#4B39EF` and `#39D2C0` from the codebase entirely. Grep for both before sign-off.

### Typography

| Use | Font | Weight |
|---|---|---|
| UI and body | **Plus Jakarta Sans** | 400 / 500 / 600 |
| Numerals and codes | **Geist Mono** | 400 |

Add both via `google_fonts`. Map to the FlutterFlow text theme:

| FlutterFlow style | Size | Weight |
|---|---|---|
| `displayLarge` | 32 | 600 |
| `headlineMedium` | 24 | 600 |
| `titleMedium` | 18 | 500 |
| `bodyMedium` | 14 | 400 |
| `labelSmall` | 12 | 500 |

### Shape and spacing

| Token | Value |
|---|---|
| Corner radius, default | **8px** |
| Corner radius, small controls | 6px |
| Corner radius, cards | 12px |
| Card padding | 16–20px |
| Section gap | 24px |
| Border width | 1px, `alternate` |
| Transition | 200ms ease-in-out |

FlutterFlow defaults to 8px and 12px rounding in places and 25px pill buttons elsewhere. Standardise: **buttons and inputs 8px, cards 12px, no pills** except status chips.

### Component parity checklist

Rebuild these Expedion widgets to match their Expeditoo counterparts one to one:

| Expedion widget | Match to Expeditoo |
|---|---|
| Quote card in `mes_devis` | `card.tsx` + status `badge.tsx` |
| Status chip | `badge.tsx` tints, success / warning / destructive |
| Primary button | `button.tsx`, filled `#076BE3`, 8px, 44px tall |
| Secondary button | `button.tsx` outline, 1px `alternate` |
| Text field | `input.tsx`, `#F4F9FF` fill, 8px, 1px border, focus ring `primary` |
| Bottom sheet | `sheet.tsx` proportions, 16px top radius |
| Empty state | `centered-empty-state.tsx` layout |
| Loading | `page-loader.tsx` equivalent, no spinner-in-place |
| Stepper (quote form) | Same step indicator as the Expeditoo create flow |
| Dark mode | Mandatory, both themes shipped |

**Acceptance test:** put an Expedion quote card and an Expeditoo listing card side by side. Same blue, same radius, same font, same padding, same status-chip treatment. If a stranger can tell which app is which from the chrome alone, it is not done.

---

## 8. Delivery phases

### Phase A — Data foundation

| Item | Notes |
|---|---|
| Postgres schema for quotes | Mirrors existing Airtable fields |
| One-time Airtable import | Script, run once, verify counts |
| API endpoints | Quotes CRUD, served from Next.js |
| Shared carrier pool | Same `carriers` table as Expeditoo |

**Exit criteria:** every existing quote is readable from Postgres and Airtable is read-only.

### Phase B — AI and pricing

| Item | Notes |
|---|---|
| Extraction service | PDF + JPEG → JSON, GPT-4.1 Vision |
| Confirm-details screen | Client verifies before submission |
| Auto-pricing | Volume from extracted dimensions, existing pricing engine |
| Twilio SMS | Quote ready, driver assigned, delivery updates |

**Exit criteria:** upload a bordereau, get a priced devis without typing a field.

### Phase C — UI realignment

| Item | Notes |
|---|---|
| Theme swap | All tokens in section 7 |
| Fonts | Plus Jakarta Sans + Geist Mono |
| Component parity | Checklist above, all ten rows |
| Dark mode | Both themes shipped |
| Purge legacy palette | No `#4B39EF`, no `#39D2C0` |

**Exit criteria:** the side-by-side card test passes.

### Phase D — Escalation and tracking

| Item | Notes |
|---|---|
| Escalation trigger | Push quote to Expeditoo when no driver accepts |
| Auto-escalate timer | Configurable window, admin can force early |
| Status write-back | Selected carrier and delivery state show in Expedion |
| Delivery tracking screen | New, shared status feed |
| Storage countdown | Days remaining before gardiennage fees |

**Exit criteria:** a quote with no driver reaches Expeditoo automatically and the client sees the selected carrier in Expedion.

---

## 9. Out of scope

Rebuilding Expedion in Next.js · Firebase Auth migration · carrier tracking APIs · new auction-house integrations · goods auctions.

---

## 10. Open decisions

1. Auto-escalation window duration
2. Whether Firebase Auth migrates in a later phase or stays permanently
3. Storage-countdown data source, manual entry or extracted from slip terms
4. Commission treatment on escalated jobs
