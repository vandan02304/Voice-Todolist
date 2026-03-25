# Firebase Setup Guide for Voice Todo

This guide walks you through connecting the Voice Todo app to your own Firebase project.

---

## Prerequisites
- Flutter SDK installed and on your PATH
- Node.js installed (for Firebase CLI)
- A Google account

---

## Step 1 — Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **Add project** → give it a name (e.g. `voice-todo`)
3. Disable Google Analytics if not needed → **Create project**

---

## Step 2 — Enable Firebase Services

### Authentication (Anonymous Sign-in)
1. Sidebar → **Authentication** → **Get started**
2. **Sign-in method** tab → Enable **Anonymous** → **Save**

### Firestore Database
1. Sidebar → **Firestore Database** → **Create database**
2. Choose **Start in test mode** (you can tighten rules later)
3. Pick a region close to your users → **Enable**

---

## Step 3 — Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

Add the pub cache bin to your PATH if prompted.

---

## Step 4 — Run `flutterfire configure`

From inside the `voice_todo` project folder:

```bash
cd e:\APP\voice_todo
flutterfire configure
```

- Select your Firebase project when prompted
- Select **android** and **ios** platforms
- This auto-generates `lib/firebase_options.dart` with your real config values

> ⚠️ The existing `lib/firebase_options.dart` contains placeholder values — **flutterfire configure will overwrite it automatically**.

---

## Step 5 — Add `google-services.json` (Android)

`flutterfire configure` does this automatically. If you need to do it manually:
1. Firebase Console → Project Settings → **Your apps** → Android → Download `google-services.json`
2. Place it at `android/app/google-services.json`

---

## Step 6 — Firestore Security Rules (for production)

Replace the default test-mode rules with:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/tasks/{taskId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

Publish from **Firestore → Rules** tab.

---

## Step 7 — Run the App

```bash
flutter pub get
flutter run
```

The app will:
- Sign in anonymously on first launch
- Store tasks in `users/{uid}/tasks/` in Firestore
- Work offline and sync when reconnected

---

## Common Issues

| Issue | Fix |
|---|---|
| `FirebaseException: No Firebase App` | Run `flutterfire configure` and replace `firebase_options.dart` |
| `permission-denied` in Firestore | Check security rules allow the current UID |
| Mic not working | Ensure `RECORD_AUDIO` permission granted on device |
| TTS not speaking | Enable device audio / check volume |
