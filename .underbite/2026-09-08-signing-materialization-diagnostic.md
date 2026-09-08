# Syll signing-materialization diagnostic — no-interruption evidence pass

Date: 2026-09-08  
Status: **blocked; diagnostic only; no app, permission, certificate, profile, or keychain mutation**

## Final closeout truth — authoritative for resumption

This section supersedes any earlier transient or contradictory conclusion in the 8 September handoffs.

- `/Applications/Syll.app`, build 215, remains the protected working app. It was not changed today. It still exposes the old read-only Vocabulary popup.
- The Personal Dictionary is implemented in the repository candidate, not installed and not human-accepted. Its focused automated evidence is 12 executed / 12 passed. The AssemblyAI recognition-context path and deterministic alias correction are implemented; FluidAudio remains off. Personal Dictionary visual QA is **NOT TESTED**.
- The former Apple Development candidate startup crash was diagnosed as a missing `LOCAL_BUILD` compilation condition. The repaired isolated candidate launches. The visible menu branding repair changes `Quit VoiceInk` to `Quit Syll`.
- David's ordinary logged-in Terminal reports three matching and three valid code-signing identities. The earlier agent-side zero-valid result was an execution-context/timing discrepancy, not evidence that certificates or private keys were absent.
- The QA packager still hard-codes historical certificate SHA-1 `69C2BB0FE6E75589F044A08105D99DBEFC6DCFC5` and historical `TeamIdentifier=A635S52367`. `687D42QJZ6` is not to be treated as a TeamIdentifier. The currently applicable certificate Subject OU / actual Team ID has not been established, and no signing-key-use probe has been performed.
- No TCC or Accessibility state changed today.

Tomorrow's exact bounded action is: **read-only inspect the two current Apple Development certificates' subject/OU, issuer, and expiry; reconcile the actual Team ID with the QA packager; then decide whether the stale fingerprint/team assumptions must be repaired before producing another signed candidate.** Do not perform that action in this session.

## Scope and operational constraint

This record was prepared after a keychain private-key query caused login-keychain consent prompts. No further `security` command, Keychain UI, Xcode account UI, build, signing operation, application launch, installation, TCC operation, or Accessibility operation was performed after that event. `/Applications/Syll.app` was inspected read-only only and was not relaunched or modified.

The protected working application remains `/Applications/Syll.app`. The outer working tree remains on `feature/syll-dictation-quality-control` at `848c617138b13b8ee146b5b0b95ea5f6f702fa99`; the pre-existing generated `app/` submodule dirtiness (` m app`) was preserved.

## Bottom line

At the time of this pass, the only non-interactive signing discovery result is:

```text
$ security find-identity -v -p codesigning "$HOME/Library/Keychains/login.keychain-db"
0 valid identities found
```

The user keychain search list and default keychain are both the login keychain:

```text
"/Users/david/Library/Keychains/login.keychain-db"
```

Accordingly, there is **no currently demonstrable, usable Apple Development signing identity**. The attempted matching private-key query returned no item, but it also caused the unwanted credential prompt, so it must not be treated as a complete proof of why the pair is unavailable.

The most precise classification supported without another credential prompt is **G — the Xcode-visible certificate record has not been established as a usable local certificate-plus-private-key signing identity**. `find-identity` proves that `codesign` cannot currently discover a valid identity. It does *not* by itself distinguish among: (B) a local certificate absent, (C) a local certificate without its private key, (D) a locked/access-controlled pair, or (E) a pair invalidated by trust/revocation/expiry. Resolving that distinction requires a deliberate, user-controlled keychain/Xcode inspection, which was out of scope for this no-interruption pass.

## What the record does and does not explain

An Xcode “Manage Certificates” row is not itself proof that the login keychain contains an exportable/useable signing identity. A valid local signing identity requires both the certificate and its corresponding private key to be visible to the keychain services used by `codesign`. The zero-identity result demonstrates that this requirement is not met from the command-line signing context at this time.

The prior record that reported the certificate identity `69C2BB0FE6E75589F044A08105D99DBEFC6DCFC5` was historical evidence from an earlier instant. It must not be carried forward as current fact. This pass did not retrieve the certificate again because doing so would risk another credential prompt. The discrepancy therefore is temporal and unresolved: either the identity was transiently visible/valid earlier and is now not, or the prior assertion did not represent the current login-keychain state. No evidence supports claiming that the just-created Xcode record is currently usable.

## Repository and build requirements

Observed Xcode environment:

```text
Xcode 26.6
Build version 17F113
/Applications/Xcode.app/Contents/Developer
```

The actual app target is `VoiceInk`. Its checked-in Debug and Release settings are:

| Setting | Value |
| --- | --- |
| Bundle identifier | `com.prakashjoshipax.VoiceInk` |
| Target/product | `VoiceInk` / `$(TARGET_NAME)` |
| Development team | `V6J6A3VWY2` |
| Signing style | `Automatic` |
| Requested identity | `Apple Development` |
| Entitlements | `VoiceInk/VoiceInk.entitlements` |
| Hardened runtime | `YES` |
| App sandbox | entitlement value `false` |
| Debug conditions | `DEBUG ENABLE_NATIVE_SPEECH_ANALYZER $(inherited)` |
| Release conditions | `ENABLE_NATIVE_SPEECH_ANALYZER $(inherited)` |

The normal entitlement file includes development APS, the `iCloud.com.prakashjoshipax.VoiceInk` CloudKit container, CloudKit service, microphone, screen capture, Apple Events, networking, a temporary mach-lookup exception and a keychain access group. The local QA entitlement file deliberately omits APS, CloudKit and the keychain access group, retaining only sandbox=false, Apple Events, microphone, selected-file access, networking and screen capture.

The canonical local QA packager `scripts/build-apple-development-pilot.sh` deliberately builds with `CODE_SIGNING_ALLOWED=NO` and `LOCAL_BUILD`, then manually signs its output. It is therefore not an ordinary Xcode automatic-signing build. It currently pins the historical certificate fingerprint `69C2BB0FE6E75589F044A08105D99DBEFC6DCFC5` and expects a resulting `TeamIdentifier` of `A635S52367`.

### Material team-ID discrepancy

Three different IDs occur in the record and must not be conflated:

1. `V6J6A3VWY2`: checked-in Xcode project `DEVELOPMENT_TEAM`.
2. `687D42QJZ6`: suffix displayed in the requested Apple Development certificate common name/account context.
3. `A635S52367`: TeamIdentifier required by the existing manual QA packager and recorded in previous signed candidate metadata.

This is a real signing-resolution risk independent of the missing identity: even if an Apple Development certificate becomes visible, the project’s automatic signing team and the manual packager’s expected signing team are not currently the same. No team or bundle setting was changed in this diagnostic pass.

## Provisioning-profile evidence

`~/Library/MobileDevice/Provisioning Profiles/` is absent; no provisioning-profile files were found by filesystem inspection. No modern Xcode certificate/profile metadata file materialized under `~/Library/Developer/Xcode` in the examined paths; only ordinary DerivedData and build/package logs exist.

Profile absence is downstream/not independently decisive for the manually signed `LOCAL_BUILD` QA path, because it uses reduced local entitlements and manual signing. It would become material for a normal CloudKit-enabled automatic-signing build, because the checked-in production entitlement shape includes CloudKit, APS and a keychain access group.

## Protected working-app provenance (read-only)

`/Applications/Syll.app` reports:

| Field | Observed value |
| --- | --- |
| Executable | `Contents/MacOS/VoiceInk` |
| Bundle identifier | `com.prakashjoshipax.VoiceInk` |
| Name/display name | `Syll` / `Syll` |
| Version/build | `2.11` / `215` |
| `LSUIElement` | `false` |
| TeamIdentifier | `not set` |
| CDHash | `4cf41f135c5c28aa16ce4951cce139dbdc221e8f` |
| Designated requirement | `identifier "com.prakashjoshipax.VoiceInk" and certificate leaf = H"4a0dc33bed93719549af3cc840454a3485997f34"` |

Current read-only `codesign -dvvv` reports `Authority=(unavailable)`, and fresh `codesign --verify --deep --strict --verbose=2` reports `CSSMERR_TP_NOT_TRUSTED`. This does not alter the working app; it means the previously recorded local signing chain is no longer presently trust-verifiable. The app bundle has Sparkle, CTranscribe, whisper and the VoiceInkRefineXPC components, but no action was taken against any of them.

This is an operational continuity constraint: the working app’s bundle identifier and designated requirement do **not** match the repository automatic-signing team or any presently usable Apple Development identity. Replacing it with a different signing team/requirement is not proven safe for Accessibility/TCC continuity and must not be attempted from this evidence.

## Temporal evidence

The local filesystem contains prior candidate artifacts and Xcode DerivedData, including historical `build/syll-qa/*` packages and the prior Crash Reports. It contains no locally discoverable provisioning profile and no non-secret Xcode account/certificate metadata proving that the recent Xcode certificate action committed a certificate/private-key pair into the login keychain.

No relevant Xcode/security/trust log evidence was returned by the non-interactive, bounded log search. This leaves the materialization failure unproven rather than licensing a guess.

## Consequences

- No Apple Development build or signing test was run.
- No candidate was launched, installed or copied.
- No restart, duplicate menu-bar app, Keychain prompt, TCC reset or Accessibility mutation is permitted as a follow-up to this record without explicit human authority.
- The Personal Dictionary source candidate remains unaccepted. Its prior automated evidence remains 12 focused tests passed, but it has no safely installed human-QA candidate.

## Exact next action for a supervisor

Perform a browser/Apple-documentation and Xcode-account-state review focused on one question: why an Xcode-visible Apple Development certificate entry does not yield a non-interactive `security find-identity -v -p codesigning` result in the login keychain, and how to reconcile the three IDs above (`V6J6A3VWY2`, `687D42QJZ6`, `A635S52367`) before any signing attempt.

The supervisor should request a single deliberate human verification only after proposing the exact expected Keychain Access/Xcode result. Until then, the precise blocker is: **no usable local code-signing identity is presently discoverable, and the project/packager team identities are inconsistent.**

## Corrected-model addendum — repository-only classification

The initial wording in this record is corrected as follows: `security find-identity -v` lists **valid** identities. `0 valid identities found` is not evidence that a certificate or private key is absent. It establishes only that no identity met the command's validity criteria in that execution context.

### Effective QA path, confirmed from repository files

`scripts/build-apple-development-pilot.sh` is not an Xcode automatic-signing path:

1. It invokes `xcodebuild` with `CODE_SIGNING_ALLOWED=NO` and `SWIFT_ACTIVE_COMPILATION_CONDITIONS=$(inherited) DEBUG LOCAL_BUILD`.
2. It copies the resulting unsigned `VoiceInk.app`, changes the visible bundle/executable labels to Syll while retaining the compatibility bundle identifier `com.prakashjoshipax.VoiceInk`, and uses the reduced `VoiceInk.local.entitlements` file.
3. It manually signs Mach-O files, nested frameworks/XPC/bundles, then the app root with the hard-coded historical SHA-1 `69C2BB0FE6E75589F044A08105D99DBEFC6DCFC5`.
4. It requires resulting `TeamIdentifier=A635S52367` for root and nested code.

The `LOCAL_BUILD` guard is present and enforced by `scripts/verify_overlay.py`; it keeps the dictionary SwiftData store out of CloudKit. The reduced QA entitlement file contains sandbox=false, Apple Events, microphone, selected-file read access, network client/server, and screen capture only. It omits APS, CloudKit, the iCloud container, and keychain-access groups.

Consequently, the upstream project setting `DEVELOPMENT_TEAM=V6J6A3VWY2` is inherited project metadata and is not used by this manual QA signing invocation. The certificate-label suffix `687D42QJZ6` is a Team Member ID, not established evidence of the currently applicable signing TeamIdentifier. `A635S52367` is historical packager/candidate metadata only until the current certificate Subject OU is deliberately inspected.

### Current classification and required human evidence

Current classification is **unresolved between B/C/D/E**: the earlier agent result shows only zero *valid* identities. It cannot establish certificate absence or private-key absence. No local automated keychain query will be retried under the no-interruption boundary.

The exact one-time human-controlled diagnostic is:

```text
/usr/bin/security find-identity -p codesigning "$HOME/Library/Keychains/login.keychain-db"
```

Run it once in an ordinary logged-in macOS Terminal session, without `sudo`, and return the complete output including both `Matching identities` and `Valid identities only` sections. It lists identity metadata; it does not sign Syll or export a private key. If an unexpected keychain-consent dialog appears, cancel it and stop. No password should be supplied to the agent and no retry should be made.

Result handling is precommitted:

- **Matching and valid:** identity discovery is healthy in David's Terminal context only. Investigate the earlier agent-context discrepancy and update the packager's stale hard-coded fingerprint/OU only after evidence; do not claim that signing-key use has been tested.
- **Matching but not valid:** classify identity present with a validity/trust failure. Next evidence is targeted certificate issuer/status/expiry inspection, not a new certificate or “Always Trust.”
- **Neither:** identity is still not discoverable. Do not infer certificate/private-key absence; next action is one targeted check of the Xcode-managed certificate record's local-keychain materialization.
- **Consent/inaccessible:** record that exact context limitation and stop; it is not certificate-absence evidence.

Personal Dictionary visual inspection remains **NOT TESTED**. Source-side tests are historical evidence only (12 focused tests passed); no readiness or Feature acceptance is implied.

## Human-controlled identity discovery result — classification A

David ran the prescribed command once in an ordinary logged-in Terminal session, without `sudo`, and reported no consent dialog:

```text
/usr/bin/security find-identity -p codesigning "$HOME/Library/Keychains/login.keychain-db"

Policy: Code Signing
  Matching identities
  1) 4A0DC33BED93719549AF3CC840454A3485997F34 "VoiceInk Local Dev"
  2) 69C2BB0FE6E75589F044A08105D99DBEFC6DCFC5 "Apple Development: realjewlion@gmail.com (687D42QJZ6)"
  3) 96A2580E1E7DFD460580B26097717464407AAB1B "Apple Development: realjewlion@gmail.com (687D42QJZ6)"
  3 identities found

  Valid identities only
  1) 4A0DC33BED93719549AF3CC840454A3485997F34 "VoiceInk Local Dev"
  2) 69C2BB0FE6E75589F044A08105D99DBEFC6DCFC5 "Apple Development: realjewlion@gmail.com (687D42QJZ6)"
  3) 96A2580E1E7DFD460580B26097717464407AAB1B "Apple Development: realjewlion@gmail.com (687D42QJZ6)"
  3 valid identities found
```

### Classification

**A — matching and valid in David's logged-in Terminal session.** Identity discovery is healthy in that session. This proves that both Apple Development certificate/private-key pairs are currently discoverable and valid to that session's code-signing policy. It does **not** test use of either private key for an actual signing operation.

The earlier agent-side `0 valid identities found` is therefore an execution-context discrepancy, not evidence that the identities were absent. Candidate explanations still require evidence: the agent process may have queried before the certificate materialized, used a different session/keychain access context, or encountered a transient keychain availability state. No certificate/trust conclusion should be drawn from it.

### Consequence for the QA packager

The hard-coded `69C2…CFC5` pin is no longer the only valid Apple Development identity; `96A2…AB1B` is also valid. The current Subject OU of either identity has not been re-inspected, so `A635S52367` remains historical rather than established present authority. The `687D42QJZ6` common-name suffix remains a Team Member ID, not a substitute for Subject OU/TeamIdentifier evidence.

### One proposed next action

Before any build or signing probe, perform one targeted **read-only certificate Subject/issuer/expiry inspection in David's ordinary Terminal session** for fingerprints `69C2…CFC5` and `96A2…AB1B`, and use its actual Subject OU to determine whether the QA packager's `A635S52367` check is current or stale. Do not alter the packager, sign, build, install, or launch anything until that result is reviewed.
