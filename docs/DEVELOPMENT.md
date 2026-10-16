# Daló developer setup

This guide covers local development, Firebase configuration, Firestore rules, and APK builds. For the app overview shown to repository visitors, see the root [README](../README.md).

## Requirements

- Flutter SDK 3.24 or newer
- Android Studio and Android SDK (API 35 used for the current build)
- Node.js and npm
- Firebase CLI: `npm install -g firebase-tools`
- FlutterFire CLI: `dart pub global activate flutterfire_cli`

## Firebase project setup

Daló uses Firebase Authentication and Cloud Firestore on the Spark plan. Do not enable billing or deploy Cloud Functions for this project.

1. Create or select a Firebase project and keep it on Spark.
2. Enable Authentication → Email/Password.
3. Enable email enumeration protection. Configure a password policy requiring at least 8 characters, including lowercase, uppercase, and a number.
4. Create a Cloud Firestore database.
5. Configure the Flutter app from the `dalo/` directory:

   ```powershell
   dart pub global run flutterfire_cli:flutterfire configure --project=YOUR_PROJECT_ID
   ```

   Select Android. This generates `dalo/lib/firebase_options.dart` and the Android `google-services.json`. These generated files are ignored by Git; each developer must configure their own Firebase project.

6. The current allowed email domains are `udd.edu.ph` and `cdd.edu.ph`. They are configured in the app and `firestore.rules` and must remain aligned.

## Install dependencies and run

From the repository root:

```powershell
cd dalo
flutter pub get
flutter run
```

You need an Android device or emulator. The scanner requires camera permission.

## Test and deploy Firestore rules

From the repository root, install the test dependencies and run the emulator-backed rules tests:

```powershell
npm install
npm run test:rules
```

These tests use the Firebase Emulator and a demo project ID; they do not write to the live project. After the tests pass and you have reviewed `firestore.rules`, deploy only the rules with:

```powershell
firebase deploy --only firestore:rules --project=YOUR_PROJECT_ID
```

Use the intended Firebase project ID explicitly. Do not deploy unreviewed rules. Deploy indexes separately only when they have changed.

## Build the Android APK

From the repository root:

```powershell
.\scripts\build_apk.ps1
```

The script copies the debug APK to `output\apk\Dalo.apk`. That output folder is ignored by Git. To install on an already connected Android device, run from `dalo/`:

```powershell
flutter install
```

## Security and feature notes

- Public sign-up creates student accounts only. Facilitator roles are assigned by an administrator in Firestore; users cannot grant themselves elevated roles.
- Event owners manage their own attendee list. Verified, eligible accounts may browse and register for open events.
- QR tokens are generated as opaque random values and are scoped to a registration; they do not contain student email or other personal information.
- Registration capacity and one-time check-in use client Firestore transactions guarded by Security Rules. This is appropriate for a small college-project MVP but is less resistant to modified clients than a trusted backend.
- Registration confirmation emails containing QR tickets are pending because they require a trusted mail backend/provider. Firebase Authentication's email verification is a separate message.
- Firebase Cloud Storage requires Blaze for this project. To remain on Spark, optional photos are compressed and stored as Base64 in Firestore documents with a 280,000-character limit. This is for low-volume use only and increases Firestore document usage; it is not scalable media storage.
- Firebase App Check is not enforced until an Android provider is selected and verified for direct APK distribution.
