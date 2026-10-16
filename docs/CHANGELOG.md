# Daló project change log

Append a dated entry for each feature, fix, revision, or project-file change. Include a concise summary, affected files, and verification performed (or “not checked”). Preserve prior entries; add a correction as a new entry.

## 2026-10-16 — Security hardening and emulator rule tests

- Restricted event and registration reads to verified `@udd.edu.ph` / `@cdd.edu.ph` accounts; tightened profile/event data validation and owner-name integrity; made profile/event creation timestamps server-generated; preserved private profiles, student-only public role creation, capacity-safe registration, and one-time owner/facilitator check-in. Improved signup/password-reset error responses and interrupted-signup profile recovery; aligned event form and password limits with rules/console setup; disabled Android app backup and cleartext traffic. Added a repeatable six-case Firestore Emulator rules test command and setup instructions. Documented App Check as deferred until a provider is validated for sideloading. No production rules were deployed.
- Files: `.gitignore`, `firebase.json`, `firestore.rules`, `package.json`, `package-lock.json`, `security-tests/firestore.rules.test.mjs`, `security-tests/run_firestore_rules_tests.ps1`, `dalo/android/app/src/main/AndroidManifest.xml`, `dalo/lib/services/auth_service.dart`, `dalo/lib/services/event_service.dart`, `dalo/lib/services/profile_service.dart`, `dalo/lib/screens/auth/register_screen.dart`, `dalo/lib/screens/auth/forgot_password_screen.dart`, `dalo/lib/screens/organizer/create_event_screen.dart`, `AGENTS.md`, `ANTIGRAVITY_PROMPT.md`, `README.md`, `docs/REVIEW_HANDOFF.md`, `docs/CHANGELOG.md`, `output/apk/Dalo.apk`.
- Verification: `npm run test:rules` passed all 6 emulator tests; `flutter analyze` reported no issues; `scripts/build_apk.ps1` built `output/apk/Dalo.apk`. Live Firebase deployment, Authentication console settings, and physical-device security flows remain unchecked.

## 2026-10-16 — Splash wordmark clipping and delete-cancel crash

- Refit the complete Daló wordmark into Android's masked splash-icon safe area so the vertical accent and wordmark stay visible. Moved the deletion confirmation text controller into a dialog-owned state object and unfocus before closing; Cancel/back now lets the dialog dispose its field with the route instead of disposing it while mounted.
- Files: `dalo/android/app/src/main/res/drawable-nodpi/dalo_splash_icon.png`, `dalo/lib/screens/organizer/event_attendees_screen.dart`, `docs/CHANGELOG.md`, `docs/REVIEW_HANDOFF.md`.
- Verification: `flutter analyze` found no issues and `scripts/build_apk.ps1` built `output/apk/Dalo.apk`. No Android device was connected for manual launch/cancel flow verification.

## 2026-10-16 — Event admin details, delete dialog layout, and splash logo clarity

- Made the delete confirmation scrollable to prevent overflow while the keyboard is open. Event owners and facilitator-role accounts now see the host/facilitator information and an attendee-management action in place of registration; service and rules also reject their registrations. Re-rendered the Android splash wordmark at higher resolution and used its full safe drawable area.
- Files: `dalo/lib/screens/organizer/event_attendees_screen.dart`, `dalo/lib/screens/student/event_detail_screen.dart`, `dalo/lib/services/registration_service.dart`, `dalo/android/app/src/main/res/drawable-nodpi/dalo_splash_icon.png`, `firestore.rules`, `AGENTS.md`, `ANTIGRAVITY_PROMPT.md`, `README.md`, `docs/CHANGELOG.md`, `docs/REVIEW_HANDOFF.md`.
- Verification: `flutter analyze` reported no issues; `scripts/build_apk.ps1` built `output/apk/Dalo.apk`; Firestore Emulator started with the updated rules and exited cleanly. Splash bitmap visually inspected at original resolution. Delete dialog and event-admin UI have not been exercised on a physical device; live Firestore rules still need deployment.

## 2026-10-16 — Owner event deletion and 500-person capacity limit

- Added an owner-only Danger zone requiring the exact event title before permanently deleting an event and its registration/check-in records. Deletion first marks the event as closing, preventing new registrations while attendee records are removed in batches. Enforced capacity 1–500 in the form, event service, and Firestore rules.
- Files: `dalo/lib/models/event.dart`, `dalo/lib/screens/organizer/create_event_screen.dart`, `dalo/lib/screens/organizer/event_attendees_screen.dart`, `dalo/lib/services/event_service.dart`, `firestore.rules`, `AGENTS.md`, `ANTIGRAVITY_PROMPT.md`, `README.md`, `docs/REVIEW_HANDOFF.md`, `docs/CHANGELOG.md`.
- Verification: the first APK build caught an unsupported Flutter color API; replaced it with the SDK-compatible API and rebuilt successfully. Updated Firestore rules must still be deployed before the live app can delete events or enforce the new cap. Physical-device flow and rule behavior are not checked.

## 2026-10-16 — Event cover photos and private user profiles

- Added optional compressed event covers on create, event discovery cards, and event details; added a private editable profile with photo, nickname, optional department/year/gender, organizations/positions, and hosted/joined event history. Gender remains open-ended and optional. Restricted user-document reads to their owner and added Firestore validation for profile fields and image size. Kept uploads Spark-compatible by storing compressed Base64 images in Firestore, capped at 280,000 characters; documented the low-volume limitation because Firebase Cloud Storage requires Blaze.
- Files: `dalo/pubspec.yaml`, `dalo/pubspec.lock`, `dalo/lib/models/app_user.dart`, `dalo/lib/models/event.dart`, `dalo/lib/services/image_upload_service.dart`, `dalo/lib/services/profile_service.dart`, `dalo/lib/services/event_service.dart`, `dalo/lib/core/widgets/profile_avatar.dart`, `dalo/lib/screens/student/profile_screen.dart`, `dalo/lib/screens/student/student_home.dart`, `dalo/lib/screens/student/event_detail_screen.dart`, `dalo/lib/screens/organizer/create_event_screen.dart`, `firestore.rules`, `dalo/android/app/build.gradle`, `AGENTS.md`, `ANTIGRAVITY_PROMPT.md`, `README.md`, `docs/REVIEW_HANDOFF.md`, `docs/CHANGELOG.md`.
- Verification: `flutter analyze` passed; the debug APK built against Android SDK 35 and was copied to `output/apk/Dalo.apk`; Firestore Emulator started with the updated rules without a compile error. Rule behavior/live deployment and physical-device image/profile flow are not checked.

## 2026-10-15 — Let users create and manage their own events

- Added a New event action and My events tab to the shared home. All account roles can browse/join events; event creators can view/manage their attendee list and use QR or manual check-in.
- Updated Firestore rules so any verified institutional account may create/register for events, while owner access is limited to events they created; optional facilitators retain cross-event check-in. QR lookup now includes the current event ID to align with owner-scoped rules.
- Updated project instructions, Antigravity prompt, README, and review handoff to reflect event ownership and the required Firestore rules redeployment.
- Files: `dalo/lib/core/auth/auth_gate.dart`, `dalo/lib/screens/student/student_home.dart`, `dalo/lib/screens/organizer/event_attendees_screen.dart`, `dalo/lib/services/event_service.dart`, `dalo/lib/services/registration_service.dart`, `firestore.rules`, `AGENTS.md`, `ANTIGRAVITY_PROMPT.md`, `README.md`, `docs/REVIEW_HANDOFF.md`, `docs/CHANGELOG.md`.
- Verification: `dart analyze` passed with no issues; `flutter build apk --debug` succeeded. Firestore rules have not been deployed or runtime-tested; physical-device smoke test not checked.

## 2026-10-15 — Project brief and implementation workflow

- Added the project instruction file and Antigravity implementation prompt for the Flutter event registration and QR attendance app.
- Updated the implementation workflow to read the preliminary Markdown project notes before every coding task and to record all changes here.
- Added the minimalist white-and-black sketch/drawing UI direction and clarified that scanning must use the camera inside the Flutter app.
- Files: `AGENTS.md`, `ANTIGRAVITY_PROMPT.md`, `docs/CHANGELOG.md`.
- Verification: reviewed the Markdown files for consistent requirements; Flutter build not run because this workspace contains no Flutter application yet.

## 2026-10-15 — Full initial Flutter app implementation

### Summary
Implemented the complete Daló Flutter Android app from scratch. No prior Flutter project existed in the repository.

### What was built

**Flutter app (dalo/)**
- `pubspec.yaml` — all dependencies: firebase_core, firebase_auth, cloud_firestore, firebase_functions, qr_flutter, mobile_scanner, uuid, share_plus, path_provider, google_fonts, intl
- `lib/main.dart` — app entry, Firebase init, portrait lock
- `lib/app.dart` — minimalist black-and-white sketch theme (Caveat headings, Inter body)
- `lib/firebase_options.dart` — placeholder to be replaced by `flutterfire configure`
- `lib/models/` — AppUser (with UserRole enum), Event, Registration models
- `lib/services/auth_service.dart` — sign-up (always student), sign-in, password reset; configurable domain restriction via `kAllowedEmailDomain`
- `lib/services/event_service.dart` — CRUD and Firestore streams for events
- `lib/services/registration_service.dart` — delegates registration/check-in to Cloud Functions for atomicity
- `lib/core/auth/auth_gate.dart` — role-based routing (student/organizer/facilitator)
- `lib/core/widgets/common_widgets.dart` — SketchCard, PrimaryButton, SecondaryButton, LoadingView, EmptyState, ErrorBanner, StatusBadge
- Auth screens: LoginScreen, RegisterScreen, ForgotPasswordScreen
- Student screens: StudentHome (events + my-tickets tabs), EventDetailScreen, QrTicketScreen (QR display + share), MyRegistrationsScreen
- Organizer screens: OrganizerHome, CreateEventScreen, EventAttendeesScreen
- Facilitator screens: FacilitatorHome, ScannerScreen (mobile_scanner, camera permissions, success/error overlays, haptic), ManualCheckinScreen (search + tap-to-check-in)
- `android/app/src/main/AndroidManifest.xml` — CAMERA, INTERNET, WRITE_EXTERNAL_STORAGE permissions
- `android/app/src/main/kotlin/com/dalo/app/MainActivity.kt`
- `android/build.gradle`, `android/app/build.gradle`, `android/settings.gradle`, `android/gradle.properties`
- `android/gradle/wrapper/gradle-wrapper.properties` — Gradle 8.4

**Cloud Functions (functions/)**
- `src/index.ts` — three Cloud Functions:
  - `registerForEvent` — Firestore transaction: capacity check, UUID token generation, registeredCount increment, confirmation email via nodemailer (skips gracefully if not configured)
  - `checkInByQrToken` — role-verified, idempotent, rejects wrong-event tokens
  - `checkInByRegistrationId` — manual check-in path
- `package.json`, `tsconfig.json`

**Firebase config**
- `firestore.rules` — blocks all direct client registration writes; role-locked event creation; students cannot self-elevate role
- `firestore.indexes.json` — composite indexes for registration queries
- `firebase.json`, `.firebaserc`

**Project files**
- `README.md` — setup steps, role assignment, APK build path, email config, known limitations
- `.gitignore`

### Affected files
All files under `dalo/`, `functions/`, `firestore.rules`, `firestore.indexes.json`, `firebase.json`, `.firebaserc`, `.gitignore`, `README.md`, `docs/CHANGELOG.md`

### Verification
- Flutter not yet installed; code written and reviewed for correctness.
- Build not run. To build: install Flutter, run `flutterfire configure`, then `flutter build apk --debug` in `dalo/`.
- APK will be at `dalo/build/app/outputs/flutter-apk/app-debug.apk`.
- Cloud Functions: deploy requires Firebase Blaze plan; `functions/src/index.ts` reviewed for logic correctness.
- Email confirmation: pending mail provider configuration (`firebase functions:config:set mail.*`); documented as not verified.
- Role assignment: documented manual admin step in README (Firestore console edit).

## 2026-10-15 — Audit fixes and build-readiness review

- Fixed the Flutter Cloud Functions dependency/import name (`firebase_functions` was invalid; the package is `cloud_functions`) and removed unused client UUID code.
- Made event registration idempotent and capacity-safe in a single Firestore transaction; derive registration identity from the verified Firebase account instead of trusting client-supplied name/email, and require a student role plus verified email.
- Made QR and manual attendance check-in transactional to prevent two concurrent requests from both succeeding.
- Changed registration emails to include an actual attached QR image, escaped user/event text in the HTML, and awaited the delivery attempt while keeping registration successful if mail delivery fails.
- Restricted organizer event updates from changing ownership or registration counts and prevented reducing capacity below existing registrations. Removed an Android manifest reference to an absent launcher icon resource.
- Enforced email verification at sign-in and sign out newly registered accounts until they verify.
- Files: `dalo/pubspec.yaml`, `dalo/lib/services/auth_service.dart`, `dalo/lib/services/registration_service.dart`, `dalo/lib/screens/auth/login_screen.dart`, `dalo/lib/screens/student/event_detail_screen.dart`, `dalo/android/app/src/main/AndroidManifest.xml`, `functions/src/index.ts`, `functions/package.json`, `firestore.rules`, `docs/CHANGELOG.md`.
- Verification: Flutter 3.24.5 is installed at `C:\src\flutter` but not on PATH; `flutter doctor` reports Android licenses unaccepted and JDK 25 selected. Initial dependency resolution exposed the invalid package name; after correcting it, packages resolved. Full analysis/build and Cloud Functions compilation are pending.

## 2026-10-15 — Static analysis and Android build audit

- Removed the remaining Dart analyzer warnings and aligned the Cloud Functions Node runtime with the installed Node 22 runtime.
- Files: `dalo/lib/screens/facilitator/scanner_screen.dart`, `dalo/lib/screens/student/event_detail_screen.dart`, `dalo/lib/screens/student/qr_ticket_screen.dart`, `dalo/lib/app.dart`, `functions/package.json`, `functions/package-lock.json`, `docs/REVIEW_HANDOFF.md`, `docs/CHANGELOG.md`.
- Verification: `dart analyze` passes with no issues; `npm run build` passes. Flutter dependency resolution passes. Flutter APK build was attempted after selecting JDK 17 and stopped because `dalo/android/app/google-services.json` is missing; Firebase project configuration is required. `flutter analyze` itself crashed once with a Dart worker-thread error; direct `dart analyze` completed successfully. `flutter doctor` also reports Visual Studio missing, which is irrelevant to Android, and initially reported Android licenses; the Android build accepted the required Android 34 licenses.
- Environment notes: Flutter's `jdk-dir` was set to the installed JDK 17 for this machine. `npm install` reported 32 dependency advisories (29 moderate, 3 high); run and review `npm audit` before deployment.

## 2026-10-15 — Setup guide and server-side student domain check

- Added a server-side check for the configured institution email domain, updated setup instructions to configure it in both Flutter and Cloud Functions, corrected the PowerShell email configuration example, and aligned the Node.js prerequisite with the Functions runtime.
- Files: `functions/src/index.ts`, `README.md`, `docs/CHANGELOG.md`.
- Verification: TypeScript build and full Flutter analyzer rerun pending after this change.

## 2026-10-15 — Verification update

- Corrected the prior verification status: `npm run build` passes after adding the backend domain check, and direct Dart analysis passes with no issues. Flutter package resolution generated `dalo/pubspec.lock`.
- Files: `dalo/pubspec.lock`, `docs/CHANGELOG.md`.
- Verification: Android debug APK remains blocked by missing Firebase project configuration (`google-services.json`); no APK was produced. `npm install` reported 32 advisories; details have not yet been triaged.

## 2026-10-15 — Firebase CLI project setup clarification

- Documented selecting the Firebase CLI default project to replace the `.firebaserc` placeholder before deployment.
- Files: `README.md`, `docs/CHANGELOG.md`.
- Verification: reviewed setup steps against the current Firebase project configuration flow; no build rerun (documentation only).

## 2026-10-15 — Support both university student email domains

- Updated client signup/sign-in and the trusted registration backend to accept the exact `udd.edu.ph` and `cdd.edu.ph` domains; documented the matching comma-separated Firebase configuration command.
- Files: `dalo/lib/services/auth_service.dart`, `functions/src/index.ts`, `README.md`, `docs/CHANGELOG.md`.
- Verification: not checked.

## 2026-10-15 — Switch to zero-budget Spark architecture

- Removed the app's Cloud Functions dependency and replaced registration/check-in calls with Firestore transactions guarded by capacity and role security rules. QR tokens now use 256-bit secure random bytes. Kept the Functions source as unused legacy code, removed it from Firebase deploy configuration, and documented registration QR email as pending under Spark.
- Updated the project instructions, Antigravity prompt, README, and implementation handoff to prohibit billing/Functions deployment and describe the Spark tradeoffs.
- Files: `dalo/lib/services/registration_service.dart`, `dalo/lib/services/auth_service.dart`, `dalo/pubspec.yaml`, `dalo/pubspec.lock`, `firestore.rules`, `firebase.json`, `AGENTS.md`, `ANTIGRAVITY_PROMPT.md`, `README.md`, `docs/REVIEW_HANDOFF.md`, `docs/CHANGELOG.md`.
- Verification: `flutter pub get` completed successfully and `dart format` completed for the changed Dart services. Dart analysis, Firestore Rules validation/deployment, and APK build not checked.

## 2026-10-15 — Spark migration build follow-up

- Updated the signup screen to display both approved domains. Raised Android min SDK to 23 for Firebase Auth and Kotlin Gradle plugin to 2.1.0 for Firebase dependency metadata. Ignored the local Firestore emulator log and refreshed the handoff status.
- Files: `dalo/lib/screens/auth/register_screen.dart`, `dalo/android/app/build.gradle`, `dalo/android/build.gradle`, `.gitignore`, `docs/REVIEW_HANDOFF.md`, `docs/CHANGELOG.md`.
- Verification: Flutter dependency resolution succeeded; Dart analysis reported no issues; the Firestore emulator loaded the rules without syntax errors; `flutter build apk --debug` succeeded at `dalo/build/app/outputs/flutter-apk/app-debug.apk`. No device smoke test or automated transaction tests were run, and rules were not deployed to the user's Firebase project.

## 2026-10-15 — Verify second-account event registration

- Fixed Firestore read access for a student's deterministic registration document when it does not exist yet. The existing account check and first transaction read need permission before the ticket is created; access is granted only when the document ID ends in that caller's UID.
- Files: `firestore.rules`, `docs/CHANGELOG.md`, `docs/REVIEW_HANDOFF.md`.
- Verification: Firestore emulator rules-unit check passed for a second verified institutional account reading its absent registration, atomically creating a registration, and incrementing event count below capacity. This used a temporary test harness outside the repository. Live Firebase rules deployment and physical-device sign-up/registration are still pending.

## 2026-10-15 — Keep event management count live

- Changed the owner management screen to listen to the event document so attendee count and Open/Full status refresh immediately after another account registers. Updated registration service comments to reflect that all verified account roles can join events.
- Files: `dalo/lib/screens/organizer/event_attendees_screen.dart`, `dalo/lib/services/registration_service.dart`, `docs/CHANGELOG.md`.
- Verification: `dart analyze` passed with no issues; `flutter build apk --debug` succeeded. Physical-device rendering and live count refresh not checked.

## 2026-10-16 — Modern event UI and login routing recovery

- Replaced the hand-drawn sketch theme with a warm, polished event-discovery design using rounded surfaces, a coral accent, updated typography, and redesigned discovery/hosting navigation and event cards.
- Reworked the auth gate to keep Firebase auth state and the user profile stream separate, wait while profiles load, and show a useful recovery state instead of silently rendering login when a signed-in profile read fails. Sign-in refreshes the Firebase user before checking email verification.
- Files: `dalo/lib/core/theme/dalo_theme.dart`, `dalo/lib/app.dart`, `dalo/lib/core/widgets/common_widgets.dart`, `dalo/lib/core/auth/auth_gate.dart`, `dalo/lib/services/auth_service.dart`, `dalo/lib/screens/auth/login_screen.dart`, `dalo/lib/screens/student/student_home.dart`, shared-card call sites in attendee and event screens, `dalo/pubspec.yaml`, `AGENTS.md`, `ANTIGRAVITY_PROMPT.md`, `docs/CHANGELOG.md`.
- Verification: `flutter analyze` passed with no issues and `flutter build apk --debug` succeeded. Physical sign-in and post-login routing are not checked because no Android device/emulator is connected.
# 2026-10-16 — Instructor project guide

- Created a concise, presentation-ready PDF explaining Daló's student and organizer workflows, QR attendance design, Firebase/security model, verification limits, demo sequence, and project file map.
- Files: `output/pdf/Dalo_Project_Guide.pdf`, `docs/CHANGELOG.md`.
- Verification: rendered all six PDF pages to PNG and visually inspected the page layouts; confirmed the PDF contains six A4 pages and extracted text from all pages. App code was not changed.

# 2026-10-16 — Daló logo, Android launch branding, and named APK

- Redrew the supplied wordmark in a bold sans style with a subtle coral accent; added it to the loading and sign-in screens, set Android launcher/adaptive icons and launch-screen branding, and added a PowerShell build script that copies the debug build to `output/apk/Dalo.apk`. Updated README build steps and ignored the local APK output.
- Files: `dalo/assets/images/dalo_logo.png`, `dalo/lib/core/widgets/dalo_brand_mark.dart`, `dalo/lib/core/auth/auth_gate.dart`, `dalo/lib/screens/auth/login_screen.dart`, `dalo/android/app/src/main/AndroidManifest.xml`, `dalo/android/app/src/main/res/`, `scripts/build_apk.ps1`, `README.md`, `.gitignore`, `docs/CHANGELOG.md`.
- Verification: `flutter analyze` passed; the build script completed `flutter build apk --debug`; Android `aapt` confirmed the APK package metadata. Output: `output/apk/Dalo.apk`. No phone/emulator visual check was performed.

## 2026-10-16 — Align Daló branding across app screens

- Cropped the transparent wordmark margins so its visible artwork centers correctly; redrew the launcher/splash mark inside Android's adaptive-icon safe area. Removed the unrelated ticket symbol from the login brand panel and applied the wordmark consistently to loading, sign-in, registration, student home, organizer home, and facilitator home.
- Files: `dalo/assets/images/dalo_logo.png`, `dalo/android/app/src/main/res/drawable-nodpi/`, `dalo/android/app/src/main/res/mipmap-*/`, `dalo/lib/core/widgets/dalo_brand_mark.dart`, `dalo/lib/core/auth/auth_gate.dart`, `dalo/lib/screens/auth/login_screen.dart`, `dalo/lib/screens/auth/register_screen.dart`, `dalo/lib/screens/student/student_home.dart`, `dalo/lib/screens/organizer/organizer_home.dart`, `dalo/lib/screens/facilitator/facilitator_home.dart`, `docs/CHANGELOG.md`.
- Verification: `flutter analyze` passed and `scripts/build_apk.ps1` rebuilt `output/apk/Dalo.apk` successfully. No physical-device visual check was available.

## 2026-10-16 — Keep the local conversation transcript out of Git

- Added a root-level ignore rule for `Dalo-markdown1.txt` and Windows-added extension variants so the private conversation copy is not staged or pushed.
- Files: `.gitignore`, `docs/CHANGELOG.md`.
- Verification: `git check-ignore` confirmed both `Dalo-markdown1.txt` and the present `Dalo-markdown1.txt.txt` are ignored.

