#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="3.47.0"

if [ ! -d "_flutter" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_VERSION" _flutter
fi

export PATH="$PATH:$(pwd)/_flutter/bin"

flutter config --no-analytics
flutter pub get

# The deployed build reads its backend config from these --dart-define values,
# sourced from the Vercel build environment. Set them in Settings > Environment
# Variables; anything unset falls back to a default that fails closed rather
# than to something that quietly half-works.
#
#   EXPEDION_API_BASE_URL       e.g. https://app.expeditoo.fr  (optional override
#                               — release builds already default to the deployed
#                               expeditoo-ship instance, ExpedionConfig._vercelDeployment,
#                               so an unset value here is fine; a WRONG value here
#                               silently overrides that default)
#   AIRTABLE_PAT                Airtable Personal Access Token (quotes base)
#   PAYMENT_SERVER_URL          deployed tools/local_payment_server.js origin;
#                               unset means payment is refused with a message
#                               rather than sent to a loopback address
#   APP_PUBLIC_URL              origin Stripe must redirect back to; leave
#                               unset to use whatever origin serves the build
#
# EXPEDION_API_KEY is deliberately NOT passed. It is the legacy shared key whose
# holder can name any UID in x-expedion-uid, so compiling it into a public web
# bundle hands every visitor the ability to impersonate any user. Web callers
# authenticate with a Better Auth session or a Firebase ID token, both of which
# the server verifies (see lib/backend/expedion_api/expedion_api.dart, and
# expeditoo-ship/src/lib/expedion-auth.ts). ExpedionApi ignores the key on web
# regardless, so re-adding the line here would not even work.
#
# ALLOW_UNVERIFIED_MARKPAID is gone rather than defaulted off. The /success page
# no longer has a client-side fallback to gate: it PATCHed Airtable with what has
# been a Postgres id since the migration, so it could only 404, and while it was
# on, /success?recordId=<any id> settled that quote unverified.
flutter build web --release \
  --dart-define=EXPEDION_API_BASE_URL="${EXPEDION_API_BASE_URL:-}" \
  --dart-define=AIRTABLE_PAT="${AIRTABLE_PAT:-}" \
  --dart-define=PAYMENT_SERVER_URL="${PAYMENT_SERVER_URL:-}" \
  --dart-define=APP_PUBLIC_URL="${APP_PUBLIC_URL:-}"
