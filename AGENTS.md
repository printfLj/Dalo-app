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
- Any signed-in verified institution account can browse open events and register without uploading photos or files.
- A successful registration creates a unique, hard-to-guess QR token for that student's registration to that event. Show it in the app and let the student save/share it.
- The event owner or a facilitator scans the QR **inside the Flutter app using the device camera**. Do not use a browser camera or web page.
- A valid scan records attendance promptly. A second scan is rejected with a clear “already checked in” message.
- Event owners and facilitators can search attendees by name and manually check them in.
- Event owners can see registered count and capacity; registration closes as soon as capacity is reached.
- Registration emails containing event details and the QR code are pending in the strict zero-budget Spark version because they need a trusted mail backend/provider. Never put mail-provider secrets in the APK. Keep Firebase Auth's email-verification message distinct from registration confirmation.

## Visual direction
- Give Daló a polished, modern campus-event identity inspired by the clarity and event-first presentation of apps such as Luma. Do not copy Luma's logo, assets, or exact layouts.
- Use a warm off-white canvas, white surfaces, near-black typography, soft gray details, and a restrained coral/terracotta accent. Use a clean sans-serif font and an editorial type hierarchy; do not use handwriting or sketch styling.
- Make event discovery image-like and inviting with tasteful event cover treatments, clear date/location details, rounded cards, calm spacing, and direct calls to action. Keep the UI cohesive across sign-in, event details, tickets, hosting, and check-in.
- Keep accessibility in view: strong contrast, readable type, large tap targets, explicit labels, and clear success/error states. QR codes must remain high contrast and unobstructed. The camera scanner may use a dark immersive view for scan clarity.

## Implementation guidance
- The project has a strict zero-budget constraint: use Firebase Spark with Flutter/Dart, Firebase Authentication, and Cloud Firestore; do not enable billing or deploy Cloud Functions. Use Firestore client transactions guarded by strict Firestore Security Rules (`getAfter`) for capacity checks, QR validation, and one-time check-in. Explain that this college-project client-based design is less resistant to modified clients than a trusted backend.
- Ordinary sign-up creates a student account. Every verified account can browse, join, and host events; hosting rights are scoped to events that account created. Facilitator access can remain admin-assigned for cross-event check-in. Never let users self-assign facilitator privileges.
- Scope each QR token to one event registration, and avoid putting student email or other personal data directly in the QR payload.
- Use a maintained Flutter QR display/scanning package and request camera permission with a clear in-app explanation. Handle denied permission, invalid QR, wrong event, network failure, and duplicate scans with readable messages.
- Keep secrets out of source control. Add only the configuration files and platform setup needed for Firebase/Android; explain manual console setup in the README.
- Build in small, coherent steps. Reuse the current project structure and conventions if a project already exists. Keep screens and data models straightforward.
- Do not claim a feature works when it still needs external credentials or Firebase configuration. State setup requirements and known limitations clearly. Keep QR registration email pending unless a no-cost trusted mail backend is actually configured and verified.

## Completion criteria
The Android app can register/sign in a student, let any verified user create and manage their own event, let any verified account register for any open event while respecting capacity, show/save that registration's QR code, scan it with the in-app camera as the event owner (or optional facilitator), record attendance once, and show live registration counts using Spark-compatible Firestore transactions and rules. Registration confirmation email containing the QR remains pending unless a trusted no-cost email backend is available and verified. Produce a debug APK and provide its path and concise build/setup instructions. Resolve build failures before describing the APK as complete; clearly report any external setup that prevents verification.
