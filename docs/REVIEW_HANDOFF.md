# Daló implementation handoff — 2026-10-15

Read `AGENTS.md`, `ANTIGRAVITY_PROMPT.md`, and all Markdown files in `docs/` before the next implementation task.

## Current project decisions

- The user requires a strict zero-budget Firebase Spark setup. Do not enable billing or deploy Cloud Functions.
- The app uses Firebase Authentication and Cloud Firestore. Registration/capacity and attendance use client Firestore transactions guarded by `firestore.rules`.
- Event owners and facilitator-role accounts see event management instead of event registration. Other verified institution accounts may register for open events.
- Allowed student email domains are `udd.edu.ph` and `cdd.edu.ph`, configured in the Flutter auth service, signup screen, and Firestore rules.
- Registration email containing the QR code is pending. The ticket remains available in-app for saving/sharing; Firebase Auth email verification is separate.
- `functions/` is legacy source only and is not configured in `firebase.json` or used by the Spark app.
- Security baseline (2026-10-16): event/registration reads and writes require verified `@udd.edu.ph` or `@cdd.edu.ph` accounts; profiles remain owner-private; role self-assignment is denied. Run `npm run test:rules` before deploying any rules change. Firebase Console settings still need to keep email enumeration protection enabled and enforce the documented password policy.

## Completed in the latest implementation session

- Security hardening (2026-10-16): enforced verified institution email for event and registration reads, tightened event/user field validation, kept roles owner/admin-controlled, reduced account-existence hints, recovered missing student profiles after interrupted sign-up, and disabled Android app backup/cleartext traffic. Six Firestore Emulator security tests pass. `flutter analyze` passes and the current debug APK is `output/apk/Dalo.apk`. These rules are local until redeployed; Firebase Authentication console settings and physical-device tests are still outstanding. App Check is not enforced pending validation of a provider for sideloaded APKs.

- Latest UI update: delete confirmation scrolls with the keyboard; event owners and facilitator-role accounts see event-management details/actions rather than a registration action; splash wordmark is higher resolution. Redeploy `firestore.rules` for the registration restriction to apply to live data.
- Follow-up from screenshots: refit the entire wordmark inside the Android splash mask and fixed delete-dialog controller lifetime to prevent the framework assertion on Cancel/back. `flutter analyze` and APK build passed; no device was connected for manual UI verification.

- Added owner-only event deletion with exact-title confirmation and cleanup of registrations/check-ins; set a hard 500-attendee maximum in the create form and Firestore rules. Latest `firestore.rules` must be redeployed for live enforcement.

- Replaced Cloud Functions calls in `RegistrationService` with Firestore transactions for capacity-safe registration and one-time check-in.
- Generated opaque 256-bit QR tokens on-device; registration IDs are deterministic per event/student to prevent duplicate signup.
- Added Firestore rule checks for verified institution accounts, role-limited access, atomic registration/counter updates, capacity, and one-way facilitator check-in.
- Removed `cloud_functions` from Flutter dependencies and removed the Functions deploy target from `firebase.json`.
- Raised Android `minSdkVersion` to 23 for Firebase Auth compatibility and Kotlin Gradle plugin to 2.1.0 for Firebase's Kotlin metadata.
- Updated the README, AGENTS instructions, Antigravity prompt, and this handoff for the Spark-only plan and documented registration-email limitation.

## Firebase setup state

- Firebase project: `dalo-app-59a23`; `.firebaserc` has this as the default.
- The user completed FlutterFire configuration and registered the Android app. `google-services.json` exists locally; generated Firebase options are ignored by Git.
- Cloud Functions deployment was rejected because Spark does not allow it. No Functions target is used now; do not retry that deployment.
- Firestore rules were deployed by the user before the event ownership update. The current updated rules must be deployed again with `firebase deploy --only firestore` from the repository root before verifying event creation/owner check-in in the app. This is a Firestore-only Spark operation.

## Verification and remaining work

- `flutter pub get` completed successfully after removing `cloud_functions`.
- `dart analyze` in `dalo/`: **No issues found**.
- The Firestore emulator started and loaded `firestore.rules` without a syntax error. Transaction/security behavior was not exercised by automated tests.
- `flutter build apk --debug` succeeded. APK: `dalo/build/app/outputs/flutter-apk/app-debug.apk`.
- The APK has not been installed or smoke-tested on a physical device/emulator. Registration QR email remains pending because it needs a trusted backend/mail provider outside this Spark-only implementation.

## Local tool state

- Flutter SDK is at `C:\src\flutter`; the user added `C:\src\flutter\bin` to PATH.
- Android Studio and Android SDK API 34 are installed. The APK build completed with the installed Java/Gradle setup.

## 2026-10-15 event ownership update

- Any verified institution account may browse/join and create events; shared home now includes New event and My events, and owners can open attendee management with QR/manual check-in. Owner permissions are scoped to their own events in Firestore rules. Facilitator accounts retain a shortcut to cross-event tools.
- Files: `dalo/lib/core/auth/auth_gate.dart`, `dalo/lib/screens/student/student_home.dart`, `dalo/lib/screens/organizer/event_attendees_screen.dart`, `dalo/lib/services/event_service.dart`, `dalo/lib/services/registration_service.dart`, `firestore.rules`, `AGENTS.md`, `ANTIGRAVITY_PROMPT.md`, `README.md`, `docs/REVIEW_HANDOFF.md`, `docs/CHANGELOG.md`.
- Verification: `dart analyze` passed with no issues, and `flutter build apk --debug` succeeded. Firestore rule behavior/deployment and physical device smoke test are not checked; the user must redeploy updated rules before runtime verification.

- Any verified institution account can browse/join events and create events; each creator manages only their own event. Optional facilitator role is admin-assigned for cross-event check-in.


## 2026-10-15 registration verification follow-up

- Fixed the Firestore read rule for a user's deterministic registration document before it exists. The owner-scoped rules and registration/capacity transaction passed a local Firestore emulator check for a second verified institutional account.
- The live Firebase project still needs the latest `firestore.rules` deployed before this exact version is available to the APK. The physical two-account flow remains to be exercised on the device.
- The owner event-management summary now streams the event document so its count/status can update live; `dart analyze` and debug APK build passed. Physical-device rendering/live refresh not checked.

## 2026-10-16 profile and event photo feature

- Create Event accepts an optional cover image. A private profile screen edits display name/nickname, department, year level, optional self-described gender, organization/position details, and profile image; it lists events hosted and joined with check-in status.
- Cloud Storage for Firebase requires Blaze. To remain Spark-only, the app compresses image-picker photos and stores them as Base64 on the related Firestore event/user document, with a 280,000-character client and rules cap. This is for low-volume college-project use only and increases Firestore read/write usage.
- `flutter analyze` passed, the APK built against Android SDK 35, and the Firestore Emulator loaded the updated rules without a compile error. Updated rules have not been deployed to Firebase and physical-device profile/image behavior is not verified. Run `firebase deploy --only firestore` from the repo root when ready to publish the rule changes; this is Firestore only and does not enable billing.
