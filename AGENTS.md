# Daló project instructions

## Project goal
Build **Daló**, a straightforward Flutter Android app for university event registration and QR attendance. Keep it suitable for a college project: understandable code, a small dependency set, and no unrelated features. The final deliverable is a working Android APK.

## Read-first and change-log workflow
- Before starting any new implementation task or making edits, read `AGENTS.md`, `ANTIGRAVITY_PROMPT.md`, and every Markdown file in `docs/` so current decisions and prior work are understood.
- Follow those project notes while making changes. If a note conflicts with the user's latest request, follow the latest user request and update the relevant note.
- Log every implementation change, revision, and feature in `docs/CHANGELOG.md` in the same work session. Each entry must include the date, what changed, affected files, and how it was checked (or say “not checked”). Do not silently rewrite or remove earlier history; add a new entry to correct it.
- If an implementation task creates, changes, or removes project files, include that work in the log. Keep entries concise and useful.

## Product requirements
- Students can register and sign in with a verified student email. Keep the allowed institution email domain configurable; do not invent one.
- Any verified institution account can create an event with title, date, time, location, and attendee capacity. The creator owns and manages that event's attendees and check-in; students can browse and join any open event.
- Any signed-in verified institution account can browse open events. Non-owner accounts without facilitator privileges can register without uploading photos or files; owners and facilitator-role accounts use event-management tools instead.
- Event creators and facilitator-role accounts see event-management information/tools instead of a registration action; other verified accounts can register. Event-specific facilitator assignment is a future feature, so current facilitator access remains global/admin-assigned.
- A successful registration creates a unique, hard-to-guess QR token for that student's registration to that event. Show it in the app and let the student save/share it.
- The event owner or a facilitator scans the QR **inside the Flutter app using the device camera**. Do not use a browser camera or web page.
- A valid scan records attendance promptly. A second scan is rejected with a clear “already checked in” message.
- Event owners and facilitators can search attendees by name and manually check them in.
- Event owners can see registered count and capacity; registration closes as soon as capacity is reached.
- Event capacity must be between 1 and 500 attendees. Enforce the 500-person maximum in the UI, service, and Firestore rules.
- Event owners can permanently delete their own event from a clearly marked Danger zone. Require typing the exact event title before enabling permanent deletion; block new registrations during cleanup and delete its attendee/check-in records too.
- Users can edit their own profile with a nickname, optional department, year, inclusive self-described gender, organizations/positions, profile photo, and lists of events they hosted or joined. Keep profile fields private to the profile owner unless a later explicit product decision adds sharing controls.
- Event creators can optionally add a photo cover shown on event cards and details.
- Registration emails containing event details and the QR code are pending in the strict zero-budget Spark version because they need a trusted mail backend/provider. Never put mail-provider secrets in the APK. Keep Firebase Auth's email-verification message distinct from registration confirmation.

## Visual direction
- Give Daló a polished, modern campus-event identity inspired by the clarity and event-first presentation of apps such as Luma. Do not copy Luma's logo, assets, or exact layouts.
- Use a warm off-white canvas, white surfaces, near-black typography, soft gray details, and a restrained coral/terracotta accent. Use a clean sans-serif font and an editorial type hierarchy; do not use handwriting or sketch styling.
- Make event discovery image-like and inviting with tasteful event cover treatments, clear date/location details, rounded cards, calm spacing, and direct calls to action. Keep the UI cohesive across sign-in, event details, tickets, hosting, and check-in.
- Keep accessibility in view: strong contrast, readable type, large tap targets, explicit labels, and clear success/error states. QR codes must remain high contrast and unobstructed. The camera scanner may use a dark immersive view for scan clarity.

## Implementation guidance
- The project has a strict zero-budget constraint: use Firebase Spark with Flutter/Dart, Firebase Authentication, and Cloud Firestore; do not enable billing or deploy Cloud Functions. Use Firestore client transactions guarded by strict Firestore Security Rules (`getAfter`) for capacity checks, QR validation, and one-time check-in. Explain that this college-project client-based design is less resistant to modified clients than a trusted backend.
- Cloud Storage for Firebase currently requires Blaze, so do not add it under the zero-budget constraint. For this small college project only, compress gallery photos to at most 280,000 Base64 characters and store them on the corresponding Firestore user/event document. Keep the limit enforced in client code and Firestore rules. Explain that Firestore is not scalable media storage and that image data increases document reads/writes; a larger deployment needs an explicitly approved storage/budget change.
- Ordinary sign-up creates a student account. Every verified account can browse, join, and host events; hosting rights are scoped to events that account created. Facilitator access can remain admin-assigned for cross-event check-in. Never let users self-assign facilitator privileges.
- Scope each QR token to one event registration, and avoid putting student email or other personal data directly in the QR payload.
- Use a maintained Flutter QR display/scanning package and request camera permission with a clear in-app explanation. Handle denied permission, invalid QR, wrong event, network failure, and duplicate scans with readable messages.
- Keep secrets out of source control. Add only the configuration files and platform setup needed for Firebase/Android; explain manual console setup in the README.
- Require a verified allowlisted institutional email in Firestore rules for event discovery and registration data. User profile documents are private; public sign-up may create only a student role, and users must never be able to grant themselves organizer/facilitator privileges.
- Validate Firestore rules in the emulator with `npm run test:rules` before deployment. Treat the Android APK as an untrusted client; do not rely on client-side checks for access control. Keep password policy and email-enumeration protection enabled in Firebase Authentication settings.
- Do not enforce Firebase App Check in production until an Android provider has been selected and verified with the project's direct-APK distribution; document the remaining abuse risk in the meantime.
- Build in small, coherent steps. Reuse the current project structure and conventions if a project already exists. Keep screens and data models straightforward.
- Do not claim a feature works when it still needs external credentials or Firebase configuration. State setup requirements and known limitations clearly. Keep QR registration email pending unless a no-cost trusted mail backend is actually configured and verified.

## Completion criteria
The Android app can register/sign in a student, let any verified user create and manage their own event, let eligible non-owner/non-facilitator accounts register for open events within capacity, show/save each registration's QR code, scan it with the in-app camera as the event owner (or optional facilitator), record attendance once, show live registration counts, provide optional event covers and private editable profiles with hosted/joined history, using Spark-compatible Firestore transactions and rules. Registration confirmation email containing the QR remains pending unless a trusted no-cost email backend is available and verified. Produce a debug APK and provide its path and concise build/setup instructions. Resolve build failures before describing the APK as complete; clearly report any external setup that prevents verification.
