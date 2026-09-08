# Syll Apple Development signing pilot — evidence

Date: 2026-09-08
Status: **v1 installed but stopped; visible VoiceInk/Syll collision must be corrected before relaunch**
Platform-pilot result: **IN PROGRESS / no PASS or FAIL on Accessibility continuity yet**

## Protected state

- `/Applications/Syll.app` remains untouched and its original process remains running.
- No TCC or Accessibility state was reset or changed.
- No ad-hoc fallback was used.

## Intended isolated pilot

- Intended bundle identifier: `capital.underbite.SyllSigningPilot`.
- Intended install path: `/Users/david/Applications/Syll Signing Pilot.app`.
- Intended signing identity label: `Apple Development: realjewlion@gmail.com (687D42QJZ6)`.
- Intended v1/v2 shape: same bundle identifier, install path, Apple Development certificate, nested signing order, entitlements, and application-identifier shape; build number only would differ.

## Current working Syll identity (read-only)

- Path: `/Applications/Syll.app`.
- Name/display name: `Syll` / `Syll`.
- Bundle identifier: `com.prakashjoshipax.VoiceInk`.
- Version/build: `2.11` / `215`.
- Authority: `VoiceInk Local Dev`; `TeamIdentifier=not set`.
- Designated requirement: `identifier "com.prakashjoshipax.VoiceInk" and certificate leaf = H"4a0dc33bed93719549af3cc840454a3485997f34"`.
- CDHash: `4cf41f135c5c28aa16ce4951cce139dbdc221e8f`.

## Available identity used

`security find-identity -v -p codesigning` reported:

1. `4A0DC33BED93719549AF3CC840454A3485997F34` — `VoiceInk Local Dev`.
2. `69C2BB0FE6E75589F044A08105D99DBEFC6DCFC5` — `Apple Development: realjewlion@gmail.com (687D42QJZ6)`.

Public certificate inspection for identity 2 reported:

- Subject common name: `Apple Development: realjewlion@gmail.com (687D42QJZ6)`.
- Subject organisational unit (the Apple signing Team Identifier used in code requirements): `A635S52367`.
- Subject UID: `W2Q525JJ95`.
- Validity: 13 August 2026 through 13 August 2027.

David explicitly approved using the certificate's actual Team Identifier `A635S52367`. The parenthesised `687D42QJZ6` remains only part of the certificate's display label and is not represented as the signing Team Identifier.

## Pilot v1 identity

- Source commit: `47f0b645cf977f1003388d2a26452b724cca2f54`, plus the recorded uncommitted Personal Dictionary candidate and pilot packager.
- Bundle identifier: `capital.underbite.SyllSigningPilot`.
- Name/display name: `Syll Signing Pilot` / `Syll Signing Pilot`.
- Version/build: `0.1` / `1`.
- Executable: `Contents/MacOS/VoiceInk`.
- Install path: `/Users/david/Applications/Syll Signing Pilot.app`.
- Signing identity SHA-1: `69C2BB0FE6E75589F044A08105D99DBEFC6DCFC5`.
- TeamIdentifier: `A635S52367`.
- Designated requirement: `identifier "capital.underbite.SyllSigningPilot" and anchor apple generic and certificate leaf[subject.CN] = "Apple Development: realjewlion@gmail.com (687D42QJZ6)" and certificate 1[field.1.2.840.113635.100.6.2.1] /* exists */`.
- Entitlements: app sandbox false; Apple Events automation, microphone, user-selected read-only files, network client/server, and screen capture true. No embedded provisioning profile was found and no application-identifier entitlement is present.
- The working Syll icon was copied read-only into the pilot; the working app itself was not changed.

## Rejected v1 attempt and packager correction

The first installed pilot terminated before UI launch. David supplied crash incident `4026733A-804B-47AD-A948-FD20FC58DE3E`: dyld rejected `Contents/MacOS/VoiceInk.debug.dylib` because the main executable used Team `A635S52367` while that loose dylib retained the prior local signing identity. The failed installed copy is preserved at `build/signing-pilot/v1-invalid-installed-copy.app`; the earlier artifact is preserved at `build/signing-pilot/v1/Syll Signing Pilot.app`.

`scripts/build-apple-development-pilot.sh` now signs every loose Mach-O file first, then nested bundles inside-out, then the main app. It performs deep/strict verification and rejects any executable or dylib whose TeamIdentifier is not `A635S52367`. This additionally caught and corrected Sparkle's loose `Autoupdate` helper before installation.

Corrected v1 artifact: `build/signing-pilot/v1-fixed2/Syll Signing Pilot.app`. It passed real-keychain deep/strict verification, satisfies its designated requirement, was installed separately, and remained running as `/Users/david/Applications/Syll Signing Pilot.app/Contents/MacOS/VoiceInk`.

David then observed both Syll and VoiceInk as open. The pilot inherited the `VoiceInk` executable/process and hard-coded upstream UI naming even though its bundle name is `Syll Signing Pilot`. This makes the isolated pilot visibly ambiguous and is not acceptable for a consent test. The executor terminated only the pilot process. The real `/Applications/Syll.app/Contents/MacOS/VoiceInk` process remained running. The installed pilot bundle is retained but must not be relaunched until its visible identity is unambiguous.

## v1/v2 evidence

v1 normal Accessibility consent and real dictation are pending. v2 has deliberately not been built or installed until v1 passes those gates.

## Implication for real Syll

There is not yet evidence that Apple Development signing preserves Accessibility across an update. Nothing from this in-progress pilot authorises migration or replacement of the real Syll app. Distribution readiness remains out of scope and still requires Developer ID Application signing and notarization.

## Exact next action

First make the pilot's executable/process and user-visible product naming unambiguously `Syll Signing Pilot` without changing its bundle ID, Team ID, entitlements, or the real Syll. Rebuild and inspect v1 before relaunch. Only then ask David to grant Accessibility once and perform one simple real dictation. After that result, build v2 with build number `2`, compare its identity with v1, replace only the pilot in place, and test whether Accessibility and dictation persist without reauthorization.
