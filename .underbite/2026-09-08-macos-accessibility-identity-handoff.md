# macOS Accessibility identity incident — handoff

Date: 2026-09-08
Status: working Syll restored; durable update/distribution solution pending independent review

## Release-identity checkpoint — 2026-09-08

### Observed current installed identity (read-only inspection)

- Installed app: `/Applications/Syll.app`, `CFBundleDisplayName=Syll`, `CFBundleName=Syll`, version `2.11`, build `215`, icon `AppIcon`.
- Current bundle identifier remains `com.prakashjoshipax.VoiceInk`; executable remains `VoiceInk`; `LSUIElement=false`.
- Current signature is local/ad-hoc-style: `Authority=VoiceInk Local Dev`, `TeamIdentifier=not set`, designated requirement is tied to certificate leaf `4a0dc33b…`, and CDHash is `4cf41f135c5c28aa16ce4951cce139dbdc221e8f`.
- The installed app was not modified, launched, re-signed, copied, or otherwise disturbed by this checkpoint.

### Available local code-signing identities

`security find-identity -v -p codesigning` reports exactly two valid identities:

1. `4A0DC33BED93719549AF3CC840454A3485997F34` — `VoiceInk Local Dev`.
2. `69C2BB0FE6E75589F044A08105D99DBEFC6DCFC5` — `Apple Development: realjewlion@gmail.com (687D42QJZ6)`.

There is **no Developer ID Application** certificate available in the local Keychain. The repository build script deliberately uses `CODE_SIGNING_ALLOWED=NO` followed by `codesign --sign -`, so it is an ad-hoc development build and cannot be silently promoted into a release path.

### Release blocker and exact next action

Stable v1/v2 release testing is blocked by the human-controlled prerequisite of an active Apple Developer Program membership and an installed, usable `Developer ID Application` certificate for the permanent Syll release team. Notarization additionally requires the corresponding App Store Connect/notary credentials.

Do not substitute the Apple Development identity, fabricate a certificate, or fall back to ad-hoc signing. Once the Developer ID identity exists, first freeze a permanent Syll bundle identifier, product name/icon, and release configuration; then produce Developer-ID-signed v1 and v2 bundles with the same team/identifier, notarize when credentials are available, and test an in-place update in a dedicated test location/account before any change to David's working `/Applications/Syll.app`.

## Observed facts

- The previously working Syll build is `/Applications/Syll.app`, build `215`, with display and bundle names `Syll` and the expected Syll icon.
- Its bundle identifier remains `com.prakashjoshipax.VoiceInk` and its local signature is ad hoc.
- Replacing it with an upstream-derived, ad-hoc-signed VoiceInk build caused macOS Accessibility to show an enabled `Syll.app` row while the running process still reported `AXIsProcessTrusted() == false`.
- Resetting the Accessibility TCC record for that bundle ID and then requesting Accessibility from the restored Syll app caused the setup UI to change from `Accessibility: not allowed` to `Accessibility: allowed`; dictation then worked.
- The failure was not an audio-recognition failure. It was process trust / Accessibility identity instability after changing the installed app artifact.
- The working Syll app must not be overwritten by the current thin VoiceInk overlay: the latter has upstream VoiceInk identity/icon and a standalone onboarding window after an onboarding reset.

## User impact

David cannot be asked to repeatedly repair Accessibility after ordinary application updates. A distributable Syll must preserve a stable app identity through its supported update path, and must report permission state accurately when macOS requires intervention.

## Question for independent browser supervisor

Using official Apple documentation only, determine the durable release approach for a macOS app that requires Accessibility:

1. The role of a stable bundle identifier, Developer ID signing certificate/team, designated requirement, notarization, and a signed update path in preserving TCC trust across updates.
2. Whether a permission grant can be kept across legitimate signed updates, and the cases where macOS correctly requires re-authorization.
3. Whether an app can ever unilaterally grant or repair Accessibility (expected answer must distinguish opening/requesting settings from granting consent).
4. The minimal migration plan from the current locally ad-hoc-signed `com.prakashjoshipax.VoiceInk` Syll build to a distributable Syll identity without losing data or leaving duplicate Accessibility entries.
5. Acceptance tests covering fresh install, in-place signed update, app rename/location change, signature/team change, and clean rollback.

## Constraints

- Do not mutate the working `/Applications/Syll.app` during this investigation.
- Preserve David's existing data and current functioning permission state.
- Do not claim Feature acceptance; this is a platform/distribution reliability follow-up, not completion of dictation QA.
- Treat code signing credentials, notarization credentials, and any permission grant as human-controlled authority.
