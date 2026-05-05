# Qwen/Gemma Cross Opinion Synthesis

Updated: 2026-05-05

## Models Checked

- `qwen3:8b`
- `qwen3.6:35b-a3b`
- `gemma4:latest`

Outputs:

- `cross-opinion-qwen3.md`
- `cross-opinion-gemma4.md`
- `cross-opinion-postfix-qwen36.md`
- `cross-opinion-postfix-gemma4.md`

## Useful Findings

### Critical

No concrete App Store blocking issue was identified by the local model reviews after the notification action fixes.

### High

The first Qwen review correctly identified that notification actions were registered but not connected to app state.

Status: fixed.

- `CARE_DONE` now marks the active occurrence done.
- `CARE_SNOOZE` now snoozes the active occurrence and schedules a follow-up notification.
- Notification actions carry `planId` and `petId` in `userInfo`.
- Actions received before the app handler is configured are temporarily queued.

### Medium

The models also pointed out these quality items:

- Notification authorization result should not be ignored.
- Add Care should validate input before saving.
- Paywall/App Store copy must avoid medical advice, diagnosis, dosing, or treatment claims.
- StoreKit product IDs and final pricing still need App Store Connect confirmation.
- The project still needs a real macOS/Xcode archive test.

Status:

- Authorization result handling: fixed.
- Add Care validation: fixed.
- Medical safety copy: already documented, still needs final copy review.
- StoreKit/App Store Connect: pending external setup.
- Xcode archive: pending macOS device/build environment.

## Signal Quality

The post-fix Qwen3.6 and Gemma4 outputs were partly generic and did not fully follow the requested severity-only format. Their concrete actionable value was limited, so the implementation decisions should rely mainly on direct code review plus physical-device/Xcode verification.

## Current Verdict

The SwiftUI scaffold is materially stronger than before and closer to a real iPhone app:

- Native SwiftUI structure exists.
- Canonical design target is iPhone 15 portrait, `393 x 852 pt`.
- Core local reminder creation works at the source level.
- Notification Done/Snooze behavior is now wired to app state.
- Settings has notification enable/test actions.

Not yet App Store upload-ready until:

- XcodeGen project generation succeeds on macOS.
- Xcode build/archive succeeds.
- Notification actions are tested on a physical iPhone.
- StoreKit sandbox purchases are tested.
- Real Privacy Policy, Terms, and Support URLs are added.
- App Store Connect subscription products are configured.
