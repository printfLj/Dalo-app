# Daló — University Event Registration & QR Attendance

A Flutter Android app for university event registration and in-app QR attendance scanning. Uses Firebase Authentication and Cloud Firestore on the no-cost Spark plan. It does not deploy Cloud Functions.

---

## Repository structure

```
Dalo-app/
├── dalo/                  Flutter app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart       Theme + root widget
│   │   ├── firebase_options.dart  ← REPLACE with generated file
│   │   ├── models/        Data models (AppUser, Event, Registration)
│   │   ├── services/      Auth, Event, Registration services
│   │   ├── core/          AuthGate, shared widgets
│   │   └── screens/
│   │       ├── auth/      Login, Register, ForgotPassword
│   │       ├── student/   Home, EventDetail, QrTicket, MyRegistrations
│   │       ├── organizer/ OrganizerHome, CreateEvent, EventAttendees
│   │       └── facilitator/ FacilitatorHome, Scanner, ManualCheckin
│   └── android/
├── functions/             Legacy Cloud Functions source; unused by the Spark app
├── firestore.rules        Firestore security rules
├── firestore.indexes.json Composite indexes
└── firebase.json
```

---

## Prerequisites

| Tool | Minimum version | How to install |
|------|----------------|----------------|
| Flutter | 3.24 | https://flutter.dev/docs/get-started/install |
| Android Studio | Hedgehog+ | https://developer.android.com/studio |
| Android SDK API | 34 | Via Android Studio SDK Manager |
| Firebase CLI | latest | `npm install -g firebase-tools` |
| FlutterFire CLI | latest | `dart pub global activate flutterfire_cli` |

---

## Step 1 — Firebase console setup

1. Go to https://console.firebase.google.com and **create a new project**.
2. Enable **Authentication** → Sign-in methods → **Email/Password**.
3. Create a **Firestore database** in production mode (you will deploy the rules next).
4. Keep the project on the **Spark** plan. The app does not require Cloud Functions or a billing account.

---

## Step 2 — Connect the app to Firebase

```powershell
# From the repository root, point the Firebase CLI at the same project:
firebase use --add
# Select the project and make it the default. This replaces the placeholder in .firebaserc.

# Then configure the Flutter app:
cd dalo
dart pub global run flutterfire_cli:flutterfire configure --project=YOUR_PROJECT_ID
```

This generates `lib/firebase_options.dart` with real credentials and places `google-services.json` in `android/app/`. The placeholder file already present will be overwritten.

---

## Step 3 — Allowed student email domains

The college-approved domains are already configured in the app and Firestore rules. They must stay in sync:

```dart
const List<String> kAllowedEmailDomains = ['udd.edu.ph', 'cdd.edu.ph'];
```

Students must verify their Firebase email before registering for events. No Functions config or backend deployment is needed.

---

## Step 4 — Deploy Firestore rules and indexes

```powershell
firebase deploy --only firestore
```

After downloading an app update that changes Firestore permissions, run this command again from the repository root. The app and deployed rules must agree; otherwise event creation or check-in may be rejected.

---

## Step 5 — Build the named debug APK

```powershell
.\scripts\build_apk.ps1
```

The script builds the debug APK and copies it to:

```
output\apk\Dalo.apk
```

The original Flutter build remains at `dalo\build\app\outputs\flutter-apk\app-debug.apk`.

Install on a connected Android device:

```powershell
flutter install
```

---

## Event ownership and optional facilitator role

Roles are stored as a `role` field (`student`, `organizer`, `facilitator`) in each user's Firestore document at `users/{uid}`.

**Public sign-up always creates a `student` account.** Every verified institution account can create events. The creator owns the event and can see its attendee list, scan QR codes, and manually check attendees. No admin role change is needed to host. Facilitators are optional admin-assigned users with cross-event check-in access:

1. Go to the **Firebase Console → Firestore → users** collection.
2. Find the user's document (by `email` field or browse the list).
3. Edit the `role` field to `"facilitator"`.
4. The user can check in attendees across events (the stream updates live without sign-out).

> ⚠️ Never create a public endpoint that lets users set their own role. Event-owner access is limited to events whose `organizerUid` matches that user's UID; only facilitators receive cross-event access.

---

## Email confirmation setup *(pending — not verified)*

Registration confirmation emails containing the QR code are **not available in the zero-budget Spark setup**. The app displays and lets students save/share their QR ticket. Firebase Authentication's separate email verification message is used for account verification. Do not add mail-provider secrets to the APK. Email confirmation can be added later with a trusted server and a mail provider, which may require a paid plan.

---

## Role-by-role walkthrough

### Student

1. Open the app → **Sign up** with your institution email.
2. Check your inbox → click the verification link.
3. **Sign in** → browse the **Events** tab.
4. Tap an event → **Register for this event**.
5. A QR ticket appears. Tap **Share QR code** to save or share it.
6. View all your tickets in the **My tickets** tab.

### Event creator

1. Sign in with a verified institution email.
2. In **Events**, tap **New event** and fill in title/date/time/location/capacity.
3. Open **My events** and tap your event to view attendees, scan QR codes, or manually check in.
4. You can browse and register for other users' open events.

### Facilitator

1. An admin may set your Firestore `role` to `facilitator` for cross-event access.
2. Sign in → **Daló — Facilitator** home.
3. Tap **Scan QR** for the relevant event → point camera at a student's QR code.
4. The app shows success, "already checked in", or an error message.
5. Tap **Manual** to search by name and check in without a QR scan.

---

## Known limitations and pending items

| Feature | Status |
|---------|--------|
| Registration email containing QR | **Pending** — requires a trusted mail backend/provider; not included in Spark setup |
| Cloud Functions | Not used; deployment requires Blaze and is intentionally excluded |
| iOS support | Not implemented |
| Web support | Not implemented — scanning requires in-app camera |
| Email domain restriction | Limited to `@udd.edu.ph` and `@cdd.edu.ph` in app and Firestore rules |

---

## Security notes

- QR tokens are 256-bit secure random values — opaque, hard to guess, and contain no personal data.
- Capacity enforcement and one-time attendance updates use Firestore client transactions guarded by rules (`getAfter`) on Spark; concurrent transactions retry against the event/registration documents.
- QR tokens are generated with secure random bytes on the device and contain no personal data. Students can write only their own registration as part of the matching capacity-counter transaction.
- A client-based design has less protection than a trusted server against modified or compromised app clients. Security Rules constrain allowed writes, but this is a college-project MVP, not a high-risk ticketing system.
- Students cannot self-assign elevated roles (blocked by Firestore security rules).
- No secrets or service account keys are embedded in the APK.
- Spark has free usage limits. Firebase may pause a service for the rest of the billing period if a Spark quota is exceeded; check the Firebase Console usage page during demonstrations.
