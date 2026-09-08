# Apple Development Syll candidate startup diagnosis

Date: 2026-09-08  
Status: **diagnosed; no repair implemented**

## Scope and protection

This was a diagnosis-only investigation. `/Applications/Syll.app` (historical build 215) was not modified, re-signed, replaced, reset, or used as a diagnostic target. It remained running as `/Applications/Syll.app/Contents/MacOS/VoiceInk` after the investigation. No TCC or Accessibility state changed.

The retained failed candidate is `/Applications/.Syll-crashing-apple-development-216.app`; it was not deleted or modified.

## Reproduction result

The Apple Development candidate build 216 had already been launched three times from its isolated/then-installed location. Each run terminated during startup with `EXC_BREAKPOINT` / `SIGTRAP`; the corresponding reports are:

- `/Users/david/Library/Logs/DiagnosticReports/Syll-2026-09-08-122117.ips`
- `/Users/david/Library/Logs/DiagnosticReports/Syll-2026-09-08-122304.ips`
- `/Users/david/Library/Logs/DiagnosticReports/Syll-2026-09-08-122332.ips`

In all three, `threadTriggered.queue` is `com.apple.coredata.cloudkit.queue`. The terminating thread has Core Data CloudKit frames beginning with `PFCloudKitContainerProvider`, `PFCloudKitSetupAssistant`, and `NSCloudKitMirroringDelegate`. `LanguageDictionary.forCodes` / `SonioxProvider.models`, Sparkle `SPUUpdaterSettings`, and audio-device initialization occur on the main thread in separate reports/runs. They are concurrent launch work, not the thread that triggered termination.

## Package and signing comparison

Both the crash candidate and the controlled diagnostic app had:

- bundle identifier `com.prakashjoshipax.VoiceInk`;
- the same Apple Development identity, `Apple Development: realjewlion@gmail.com (687D42QJZ6)`;
- TeamIdentifier `A635S52367`;
- the same Apple Development designated-requirement shape;
- the same local entitlement file (no CloudKit entitlement, no embedded provisioning profile, no application-identifier entitlement);
- a renamed main executable and matching `CFBundleExecutable`;
- every nested Mach-O component signed by the same Apple Development team;
- `codesign --verify --deep --strict` success.

The crash candidate differs from the historical working build in multiple non-causal packaging/source dimensions (new source lineage, a MediaRemoteAdapter framework/resource, removed Phase1Vocabulary resource, renamed executable, Apple Development signing/hardened runtime, and non-empty Sparkle feed configuration). Those differences were not changed in the controlled test below.

## Actual crash mechanism

`VoiceInkApp.createPersistentContainer` configures the dictionary SwiftData store as follows:

```swift
#if LOCAL_BUILD
let dictionaryCloudKit: ModelConfiguration.CloudKitDatabase = .none
#else
let dictionaryCloudKit: ModelConfiguration.CloudKitDatabase = .private(
    "iCloud.com.prakashjoshipax.VoiceInk")
#endif
```

The ordinary repository local build command, `scripts/build-local-app.sh`, explicitly passes:

```text
SWIFT_ACTIVE_COMPILATION_CONDITIONS=$(inherited) DEBUG LOCAL_BUILD
```

The signed QA build was produced without `LOCAL_BUILD`. Therefore it selected private CloudKit for the dictionary store while its signed entitlements/profile did not carry the required CloudKit capability. Each crash report's triggered Core Data CloudKit queue matches that configuration exactly.

## Controlled isolation

An isolated diagnostic app was built at `/private/tmp/SyllCloudKitDiagnostic.app` from the same prepared source tree and then packaged to retain all material QA-candidate dimensions:

- Apple Development signing identity and team unchanged;
- same bundle identifier and local entitlements unchanged;
- `CFBundleExecutable` renamed from `VoiceInk` to `SyllCloudKitDiagnostic`;
- same nested-code signing process and successful deep/strict verification;
- no installation in `/Applications`.

The only intended functional difference was compiling with `LOCAL_BUILD`, which selects `cloudKitDatabase: .none` for the dictionary store.

It was launched once from `/private/tmp`, remained alive after eight seconds as PID `89044`, and produced no immediate crash report. It was then terminated. The historical working Syll process remained alive.

## Diagnosis and confidence

**Root cause (high confidence):** the signed QA build omitted the repository's `LOCAL_BUILD` compilation condition, enabling the dictionary store's private CloudKit mirroring without CloudKit signing capability/provisioning. Core Data's CloudKit setup then traps on its CloudKit queue during startup.

**Not the root cause:**

- Apple Development signing itself: the controlled app used the same certificate/team/signing process and launched.
- renamed executable: the controlled app also used a renamed executable and launched.
- nested-code signature inconsistency: both candidate and controlled app passed deep/strict verification, and the controlled app used the same inside-out signing approach.
- Personal Dictionary UI/correction behaviour: no code in that feature was changed between the crashing and controlled variant; the causal variation was only the compile-time CloudKit branch.
- Sparkle, LanguageDictionary, Soniox, and audio setup: their frames appeared as concurrent main-thread startup activity, not as the crash-triggering queue.

## Smallest proposed repair (not implemented)

For a local Apple Development QA candidate, make the signed candidate build invocation include the same `LOCAL_BUILD` compilation condition as `scripts/build-local-app.sh`, before the existing packaging/signing script runs. This is a build configuration/package-path repair only; it does not change Personal Dictionary product behaviour.

Likely affected files/settings for review:

- `scripts/build-apple-development-pilot.sh` (or the command that prepares its `build/syll-qa-derived-data/Build/Products/Debug/VoiceInk.app` input);
- the QA build invocation / derived-data step that currently calls `xcodebuild` without `SWIFT_ACTIVE_COMPILATION_CONDITIONS=$(inherited) DEBUG LOCAL_BUILD`.

Do not alter `VoiceInkApp` CloudKit product logic or enable CloudKit merely to make the build launch. The supervisor should review the intended QA-versus-release CloudKit policy before implementing the build-flag repair.

## Exact next action

Supervisor review of this diagnosis. If approved, implement only the QA build configuration change, rebuild an isolated candidate, and verify stable launch before any request to replace `/Applications/Syll.app`. The Personal Dictionary Feature remains unaccepted.
