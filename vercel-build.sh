#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="3.44.0"

if [ ! -d "_flutter" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_VERSION" _flutter
fi

export PATH="$PATH:$(pwd)/_flutter/bin"

flutter config --no-analytics
flutter pub get

# TODO(EXPEDITOO-TESTING): the deployed build reads its backend config from
# these --dart-define values, sourced from the Vercel build environment.
# The owner MUST set these env vars in the Vercel project settings
# (Settings > Environment Variables), otherwise the deployed app ships with
# the defaults below (no Airtable, no Expedion bridge, localhost payment
# server):
#   EXPEDION_API_BASE_URL       e.g. https://app.expeditoo.fr
#   EXPEDION_API_KEY            the app key for /api/expedion
#   AIRTABLE_PAT                Airtable Personal Access Token (quotes base)
#   AIRTABLE_PAT_TRANSPORTEURS  Airtable PAT for the transporteurs base
#   PAYMENT_SERVER_URL          deployed tools/local_payment_server.js origin
#   APP_PUBLIC_URL              origin Stripe must redirect back to; leave
#                               unset to use whatever origin serves the build
#   ALLOW_UNVERIFIED_MARKPAID   see the security TODO below
#
# TODO(EXPEDITOO-TESTING): *** SECURITY *** ALLOW_UNVERIFIED_MARKPAID defaults
# to true so the app stays testable without a deployed payment server. It MUST
# be set to false in the Vercel environment before any real payment flows —
# while it is true, the /success page falls back to an UNVERIFIED Airtable
# PATCH (see paiement_success_widget.dart). Owner: set
# ALLOW_UNVERIFIED_MARKPAID=false together with PAYMENT_SERVER_URL, then delete
# the fallback branch and this define.
flutter build web --release \
  --dart-define=EXPEDION_API_BASE_URL="${EXPEDION_API_BASE_URL:-}" \
  --dart-define=EXPEDION_API_KEY="${EXPEDION_API_KEY:-}" \
  --dart-define=AIRTABLE_PAT="${AIRTABLE_PAT:-}" \
  --dart-define=AIRTABLE_PAT_TRANSPORTEURS="${AIRTABLE_PAT_TRANSPORTEURS:-}" \
  --dart-define=PAYMENT_SERVER_URL="${PAYMENT_SERVER_URL:-http://localhost:4242}" \
  --dart-define=APP_PUBLIC_URL="${APP_PUBLIC_URL:-}" \
  --dart-define=ALLOW_UNVERIFIED_MARKPAID="${ALLOW_UNVERIFIED_MARKPAID:-true}"
