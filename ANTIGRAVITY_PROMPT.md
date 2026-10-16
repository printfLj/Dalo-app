# Antigravity implementation prompt for Daló

You are the implementation engineer for **Daló**. Treat `AGENTS.md` and this prompt as the project's product decisions. Implement the app and deliver a working Android APK; keep the solution simple and suitable for a college project. Avoid unrelated features and unnecessary complexity. The user requires a strict zero-budget Firebase Spark setup: never enable billing or deploy Cloud Functions.

## Read and record before coding

At the start of this task and before each later implementation task, read `AGENTS.md`, this prompt, and every Markdown file in `docs/`. Follow the latest project decisions. After every feature, revision, fix, or other project change, append an entry to `docs/CHANGELOG.md` in the same work session with the date, summary, affected files, and verification performed (or “not checked”). Never silently replace previous log history.

## Product

Build a Flutter Android app for university event registration and QR attendance using Firebase Authentication and Cloud Firestore on Spark. Do not deploy Cloud Functions or other paid backend services. Implement capacity enforcement and one-time check-in with Firestore client transactions guarded by strict Security Rules (`getAfter`) so concurrent clients cannot overbook or double-check in. Document that this client-based college-project MVP is less resistant to modified clients than a trusted backend. Do not embed secrets or privileged credentials in the APK.

For every security change, first read `AGENTS.md`, this prompt, and every Markdown file in `docs/`. Require verified allowlisted school email in Firestore rules, keep profile documents private, make public account creation student-only, and protect every role field from user edits. Run `npm run test:rules` against the Firestore Emulator before changing deployed rules. Keep Firebase Authentication email enumeration protection enabled and set a server-enforced password policy as documented in `README.md`. Do not claim the APK is immune to modified clients; this Spark-only design has no trusted backend.
Do not turn on App Check enforcement until its Android provider is verified with Daló's direct APK distribution, or legitimate users could be blocked.

Implement these flows:

1. **Student account:** Register and sign in with a verified student email. Keep the accepted institution domain configurable; do not assume one. Public sign-up always creates a student role.
2. **Events:** Any signed-in verified institution account can create an event with title, date, time, location, and capacity. The creator owns and manages their event's attendees and check-in; all accounts can browse open events, and eligible non-owner/non-facilitator accounts can register. Add clear New Event and My Events actions to the shared home, regardless of any optional facilitator role.
   - Do not show registration to the event owner or facilitator-role accounts. Show an event management panel with the host name, a clear note that event-specific facilitator assignments are a future feature, and an action to manage attendees/check-in. Other verified accounts can register.
   - Capacity is at least 1 and no more than 500, enforced in the form/service and Firestore Security Rules.
   - The creator can permanently delete their event from a Danger zone. Require typing the event's exact title; safely block new registrations while deleting its registration/check-in records and event document. Only the event owner may do this.
3. **Registration and QR:** An eligible verified account registers without uploading proof photos or files. Event owners and facilitator-role accounts do not register for events. On success, create a unique, unpredictable token for that student's registration to that event. Show the QR in the app and let the student save/share it. Never put personal information in the QR payload.
4. **Attendance:** The event owner (or an admin-authorized facilitator) scans the QR using the device camera **inside the Flutter app**. Do not implement browser-based scanning. Show clear results for success, duplicate check-in, invalid code, wrong event, denied camera permission, and network failure. Record attendance once. Include attendee search by name and manual check-in.
5. **Confirmation:** Firebase Auth sends its email-verification message. Registration confirmation containing event details and the QR is pending in the zero-budget Spark version because it requires a trusted mail backend/provider. Show the QR in the app and allow saving/sharing; do not put mail credentials in the APK or claim the registration email works.

6. **Profiles and event covers:** Event hosts may add a cover photo. Each user can edit a private profile with a nickname, optional department and year level, optional inclusive self-described gender, organization/position details, and a profile photo. Show events they host and events they registered for, including check-in status. Never expose profile details or gender to other users by default. Cloud Storage for Firebase requires Blaze, so for this small Spark-only MVP compress gallery photos and store them as Base64 fields in Firestore with a 280,000-character limit enforced by Firestore Rules. Explain that this is only a low-volume workaround; image bytes increase Firestore document usage and this is not scalable media storage.

Do not allow public sign-up to grant facilitator privileges. Every verified account can browse, join, and create events; event management is limited to events they created. Document optional admin assignment for cross-event facilitator access. Close registration as soon as capacity is reached.

## UI direction

Give Daló a polished, modern campus-event identity inspired by the clarity and event-first presentation of apps such as Luma. Do not copy Luma's logo, assets, or exact layouts. Use a warm off-white canvas, white surfaces, near-black typography, soft gray details, and restrained coral/terracotta accents. Use a clean sans-serif font and an editorial type hierarchy; do not use handwriting or sketch styling. Make event discovery inviting with tasteful event-cover treatments, clear date/location details, rounded cards, calm spacing, and direct calls to action. Keep the visual system cohesive across sign-in, event details, tickets, hosting, and check-in. Maintain strong contrast, readable type, explicit labels, and large tap targets. Keep QR codes crisp, high contrast, and unobstructed; the camera scanner may use a dark immersive view for scan clarity.

## Delivery

First inspect and reuse the repository's existing structure. Implement in small, understandable steps. Add only necessary dependencies and explain Spark-only Firebase, role, camera, and email limitations in the README. Handle empty/loading/error states and prevent duplicate submissions. Build the debug APK, address build errors and issues found during verification, and provide the exact APK path plus concise setup and role-by-role walkthrough instructions. If external credentials or configuration are unavailable, report that limitation precisely and do not describe the affected feature as verified. Keep `docs/CHANGELOG.md` up to date throughout.
