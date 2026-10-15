# Antigravity implementation prompt for Daló

You are the implementation engineer for **Daló**. Treat `AGENTS.md` and this prompt as the project's product decisions. Implement the app and deliver a working Android APK; keep the solution simple and suitable for a college project. Avoid unrelated features and unnecessary complexity. The user requires a strict zero-budget Firebase Spark setup: never enable billing or deploy Cloud Functions.

## Read and record before coding

At the start of this task and before each later implementation task, read `AGENTS.md`, this prompt, and every Markdown file in `docs/`. Follow the latest project decisions. After every feature, revision, fix, or other project change, append an entry to `docs/CHANGELOG.md` in the same work session with the date, summary, affected files, and verification performed (or “not checked”). Never silently replace previous log history.

## Product

Build a Flutter Android app for university event registration and QR attendance using Firebase Authentication and Cloud Firestore on Spark. Do not deploy Cloud Functions or other paid backend services. Implement capacity enforcement and one-time check-in with Firestore client transactions guarded by strict Security Rules (`getAfter`) so concurrent clients cannot overbook or double-check in. Document that this client-based college-project MVP is less resistant to modified clients than a trusted backend. Do not embed secrets or privileged credentials in the APK.

Implement these flows:

1. **Student account:** Register and sign in with a verified student email. Keep the accepted institution domain configurable; do not assume one. Public sign-up always creates a student role.
2. **Events:** Any signed-in verified institution account can create an event with title, date, time, location, and capacity. The creator owns and manages their event's attendees and check-in; all accounts can browse and register for any open event. Add clear New Event and My Events actions to the shared home, regardless of any optional facilitator role.
3. **Registration and QR:** A student registers without uploading photos or files. On success, create a unique, unpredictable token for that student's registration to that event. Show the QR in the app and let the student save/share it. Never put personal information in the QR payload.
4. **Attendance:** The event owner (or an admin-authorized facilitator) scans the QR using the device camera **inside the Flutter app**. Do not implement browser-based scanning. Show clear results for success, duplicate check-in, invalid code, wrong event, denied camera permission, and network failure. Record attendance once. Include attendee search by name and manual check-in.
5. **Confirmation:** Firebase Auth sends its email-verification message. Registration confirmation containing event details and the QR is pending in the zero-budget Spark version because it requires a trusted mail backend/provider. Show the QR in the app and allow saving/sharing; do not put mail credentials in the APK or claim the registration email works.

Do not allow public sign-up to grant facilitator privileges. Every verified account can browse, join, and create events; event management is limited to events they created. Document optional admin assignment for cross-event facilitator access. Close registration as soon as capacity is reached.

## UI direction

Give Daló a polished, modern campus-event identity inspired by the clarity and event-first presentation of apps such as Luma. Do not copy Luma's logo, assets, or exact layouts. Use a warm off-white canvas, white surfaces, near-black typography, soft gray details, and restrained coral/terracotta accents. Use a clean sans-serif font and an editorial type hierarchy; do not use handwriting or sketch styling. Make event discovery inviting with tasteful event-cover treatments, clear date/location details, rounded cards, calm spacing, and direct calls to action. Keep the visual system cohesive across sign-in, event details, tickets, hosting, and check-in. Maintain strong contrast, readable type, explicit labels, and large tap targets. Keep QR codes crisp, high contrast, and unobstructed; the camera scanner may use a dark immersive view for scan clarity.

## Delivery

First inspect and reuse the repository's existing structure. Implement in small, understandable steps. Add only necessary dependencies and explain Spark-only Firebase, role, camera, and email limitations in the README. Handle empty/loading/error states and prevent duplicate submissions. Build the debug APK, address build errors and issues found during verification, and provide the exact APK path plus concise setup and role-by-role walkthrough instructions. If external credentials or configuration are unavailable, report that limitation precisely and do not describe the affected feature as verified. Keep `docs/CHANGELOG.md` up to date throughout.
