# CLAUDE.md

This repo has no agent-guidance file yet beyond this one note — see `README.md`,
`ROADMAP.md`, and `INTEGRATION.md` for the actual project context.

**Knowledge graph:** `graphify-out/graph.json` is a merged cross-repo graph
covering both this repo and the sibling `expeditoo-ship` Next.js app — node IDs
carry a `repo` attribute so you can tell which side of the bridge a result came
from. Query it (`graphify query "<question>"`) before grepping for
architecture, cross-file, or cross-repo questions, especially anything about the
Expedion escalation bridge (`markPaid`, `escalateAfter`, `expedion_quotes`)
documented in `INTEGRATION.md`. (`external_ref` is the equivalent idempotency
key on the `expeditoo-ship` side, not a term used in this repo's own docs.) Regenerate with
`graphify <path> --update` after either repo's docs or structure change
meaningfully — it goes stale otherwise.
