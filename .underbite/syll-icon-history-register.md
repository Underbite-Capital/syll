# Syll icon history register

Status: selection locked and installed as build 233. Any deviation from the approved identity below is a release-blocking regression.

## Application-icon candidates

The numbered order is the visual board presented to David on 2026-09-09: left-to-right, then top-to-bottom.

| ID | Recovered source | Visual identity | SHA-256 of recovered PNG |
| --- | --- | --- | --- |
| APP-1 | VoiceInk commit `76a1547` (2025-02-22) | blue microphone with feather | `2aa84b80b14a64c512d69ab8377e37f3cac94ee3b7c2999cf2d49240bdd80359` |
| APP-2 | VoiceInk commit `fcc7ecf` (2025-05-15) | blue microphone with pen nib, rounded black square | `160acde65accd73813190d061a60e31e0ce98f1b2de1be8992bf8b7bd90f7af7` |
| APP-3 | VoiceInk commit `fda3169` (2026-08-19) | blue microphone with pen nib, black field | `c8f715520af2975b0b844201eda2f22a3723a68f7b0c10cba4d500811538623c` |
| APP-4 | VoiceInk commit `fe27d8a` (2026-09-02) | resized blue microphone with pen nib, rounded black square | `bf2800c48cde2ca6554f544977fe7cfd818c9e6441c2677123e43a1fd5d52b9e` |
| APP-5 | archived Syll builds 221–228 | orange rising bars and vertical stroke on navy square | `590b1986b8b1c5e4d07c926acd50cb8bdf50f0e94737253e6c47005f28a0de23` |
| APP-6 | archived rejected Syll build 229 | blue microphone with pen nib | `2946e30c03e6a11db4e36f8964106fc404cc8fec437941b2b5d1be7f5633fbfa` |
| APP-7 | archived Syll builds 230–232 (currently installed) | black microphone with pen nib on white field | `66e6a18963d514a0517bd041eeeee2e2e48965b2ed5d6c4139df2637708b9321` |

## Menu-bar candidates

| ID | Recovered source | Visual identity | Status |
| --- | --- | --- | --- |
| MENU-1 | VoiceInk asset before commit `d7c23f9` (2025-06-07) | black microphone with feather | historical asset; unapproved |
| MENU-2 | VoiceInk asset from commit `d7c23f9` onward | black microphone with pen nib | historical asset; unapproved |
| MENU-3 | local recovery builds 222–231 | four rising rounded bars | recovery-only generated mark; rejected |
| MENU-4 | local build 232 | SF Symbol `text.cursor` plus `Syll` label | recovery-only generated mark; rejected |
| MENU-5 | Syll build 233 | three rising bars plus vertical stroke, monochrome template | approved and installed |

The standalone microphone seen in `build/syll-qa/repaired-218-menu.png` is visual evidence of an earlier menu-bar presentation. It is not sufficient to map it to a distinct asset without David’s selection.

## Selection lock

## Approved identity — 2026-09-09

David selected **APP-5**: orange rising bars and vertical stroke on a navy rounded square. This is the only approved Syll application icon. APP-1 through APP-4, APP-6, and APP-7 are forbidden.

Authoritative recovery source: `build/recovery-archives/Syll-build221.app.zip`, bundle `Syll.app/Contents/Resources/AppIcon.icns`, macOS-rendered PNG SHA-256 `590b1986b8b1c5e4d07c926acd50cb8bdf50f0e94737253e6c47005f28a0de23`.

The menu-bar mark is the same rising-bars-and-vertical-stroke identity rendered as a monochrome macOS template. It must never use a microphone, pen nib, four bars, `text.cursor`, or a text label.

Future builds must reproduce these inputs; a different visible icon is a release-blocking regression.
