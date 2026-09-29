# Observation capture: chosen direction and next-slice handoff

Date: 2026-09-29. Status: direction chosen by David; not implemented, not
accepted. This supersedes "rapid double-tap has no special action" in the
2026-09-28 wind-down. This is a product direction record, not a receipt.

## Chosen direction

Double-tap Fn means: "Capture this observation so it comes back at closeout
and gets addressed." Observations may be feelings, frustrations, ideas, or
questions about his SDLC or anything else; they need not be polished tasks or
include a proposed solution.

The intended loop is: capture -> durable observation -> considered closeout
response -> appropriate decision or proposed adjustment -> follow-through.
A note being saved or summarised is not the whole outcome. Every observation
needs a response; not every observation needs a task or a process change.

## Handoff for the implementation slice (do not bundle with capture repair)

- Hold Fn continues ordinary dictation into the current application.
- Double-tap Fn starts observation capture; a later tap finishes; Esc
  cancels. Its state must be recognisable without changing the ordinary
  dictation experience or relying solely on colour.
- An observation preserves timestamped original text and supports correction
  without silently losing the original. It must not paste into the current
  app, overwrite the clipboard, execute a command, or automatically become a
  task.
- "Saved" means durable persistence succeeded. Transcription or saving
  failures must be visible and recoverable, not silently dropped.
- Observation storage must be separate from expiring diagnostic evidence.
  Clearing diagnostics must not delete intentionally saved observations.
- The intended closeout consumer retrieves new and unresolved observations
  without David manually remembering to copy them each evening. Manual
  retrieval/export remains a fallback, not the finished integration.
- Closeout may group related observations, but must preserve their identity
  and connect each to a response, decision, proposed change, or explicit
  unresolved question. Reading or summarising is not resolution.
- Changes to SDLC rules, agent instructions, or products should initially be
  reviewable proposals through the existing delivery loop. No autonomous
  production changes or silent edits to shared instructions.
- Inspect existing SDLC/Control Room interfaces only as needed to identify a
  credible next integration. Do not build a second planner, invent an
  accessible consumer, or block the capture repair on that architecture.
- Do not activate nightly scheduling in that slice.
