# Daló

**A campus event registration and QR attendance app for Android.** Daló helps university students discover events, register, and check in with a QR ticket. Event hosts can publish events and manage attendance from the app.

> Daló is a college project built for a zero-budget Firebase Spark setup. It is an educational MVP, not a production ticketing or identity system.

## What it does

- Student sign-up and sign-in with verified `@udd.edu.ph` or `@cdd.edu.ph` email addresses.
- Browse events created by verified Daló users, host events, and register for events you are eligible to attend.
- Receive an in-app QR ticket for each registration.
- Scan tickets in the Android app, search attendees, and record check-in once.
- View and edit a private profile, including optional profile details and photo.
- Set event capacity up to 500 attendees and manage or delete events you host.

## Try Daló

If an APK has been published, download it from [Releases](../../releases). Install it on an Android device, create an account with an allowed school email, and verify that email before using event features. Daló requires an internet connection and camera access when scanning tickets.

## Project status and limitations

- Android app built with Flutter and Dart; Firebase Authentication and Cloud Firestore run on the Firebase Spark plan.
- Event registration confirmation emails containing QR tickets are not implemented. Tickets are available in the app.
- Optional profile and event images use a small-project Firestore workaround; this is not scalable media storage.
- Firestore rules constrain client actions, but this client-based college-project design is less resistant to modified clients than a trusted backend.
- iOS and web apps are not provided. QR scanning uses the in-app Android camera.

## For contributors

See [Developer setup and Firebase configuration](docs/DEVELOPMENT.md) for prerequisites, local setup, rules testing, and APK build instructions. Product decisions and the change history are in [AGENTS.md](AGENTS.md), [ANTIGRAVITY_PROMPT.md](ANTIGRAVITY_PROMPT.md), and [`docs/`](docs/).

## License

No license has been added yet. Unless a license is added, standard copyright applies and reuse or redistribution is not granted by default.
