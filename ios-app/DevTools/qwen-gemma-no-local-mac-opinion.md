# Qwen / Gemma Opinion: No-Local-Mac iOS Release Path

Date: 2026-05-06

Prompt summary:

> We have a native SwiftUI iOS app Tend Pets on Windows. User refuses buying/borrowing Mac/Mac mini. Goal: App Store-ready build/upload path. Options: Xcode Cloud, GitHub Actions macOS, Codemagic, Bitrise. Need best practical route from current Windows workspace, with iPhone 15 simulator/build validation and App Store Connect upload.

## Qwen Verdict

- Best primary path: Codemagic.
- Reason: It can handle macOS/Xcode builds, iOS signing, and App Store Connect upload with less custom signing work than a hand-built GitHub Actions release pipeline.
- Good secondary path: GitHub Actions macOS runner for build validation and simulator checks.
- Xcode Cloud is viable but less practical from a Windows-only starting point because initial workflow setup is more Apple/Xcode-centric.
- Main risk: signing credentials and provisioning profile mismatch.

## Gemma Verdict

- Best practical route: Codemagic for signed TestFlight/App Store builds.
- GitHub Actions is useful as a compile/test gate, but production signing and upload are more brittle.
- Xcode Cloud is attractive for Apple-native CI, but it is not the fastest route from this current workspace.
- Bitrise is capable, but heavier than needed for this project stage.
- Main risk: treating CI upload as "done" before App Store metadata, screenshots, privacy answers, and subscription setup are complete.

## Synthesized Decision

Use a two-lane pipeline:

1. GitHub Actions macOS: quick iPhone simulator compile check.
2. Codemagic: signed `.ipa`, TestFlight upload, and later App Store release.

This keeps the Windows environment useful for product/UI/code work while moving only the Apple-required build and signing steps into cloud macOS.
