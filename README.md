# RupeeFlow

A production-ready Flutter application for tracking income, expenses, debts, and reminders — built specifically for Indian users with ₹ (INR) support.

---

## Features

### Authentication
- Google OAuth Login
- Email & Password Login
- Email Verification
- Forgot Password (rate-limited: 10/hour)
- Fingerprint / Biometric Auth
- Optional PIN Lock (SHA-256 hashed, stored in secure storage)
- Account lockout after 5 failed login attempts (15-minute cooldown)

### Transactions
- Credit / Debit / Cash transactions
- 9 categories: Food, Transport, Shopping, Salary, Bills, Medical, Education, Entertainment, Other
- Search, filter (All/Credit/Debit/Cash/Bank), and month-wise grouping
- SMS auto-import (Android) with bank name detection and dedup (max 500/day)

### Debt Tracker
- Track money lent and borrowed
- Progress bar showing amount paid vs total
- Status: Pending / Overdue / Completed
- Record partial or full payments

### Reminders
- Due Date, Payment, and Collection reminder types
- Scheduled local push notifications
- Mark-done functionality

### Dashboard
- Real-time balance (Credits - Debits)
- Pending Receivables & Payables chips
- Quick Add Credit / Add Debit buttons
- Recent transactions list

### Security
- Firestore Security Rules (user data isolation)
- Encrypted local storage (flutter_secure_storage)
- No plaintext passwords or API keys
- HTTPS only (cleartext disabled in AndroidManifest)
- PIN stored as SHA-256 hash

---

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x |
| State Management | Riverpod 2 |
| Navigation | go_router 13 |
| Backend | Firebase (Auth, Firestore, FCM) |
| Local DB | Hive |
| Secure Storage | flutter_secure_storage |
| Notifications | flutter_local_notifications |
| Models | freezed + json_serializable |

---

## Project Structure

```
lib/
├── main.dart
├── firebase_options.dart       
├── core/
│   ├── constants/app_constants.dart
│   ├── providers/theme_provider.dart
│   ├── router/app_router.dart
│   ├── services/notification_service.dart
│   ├── theme/app_theme.dart
│   └── utils/formatters.dart
└── features/
    ├── auth/          # Login, Signup, PIN, Biometric
    ├── dashboard/     # Home screen with balance
    ├── transactions/  # Add/view/filter transactions
    ├── debts/         # Debt tracker (lent/borrowed)
    ├── reminders/     # Due date & payment reminders
    ├── notifications/ # Local notification service
    ├── sms/           # SMS auto-import (Android)
    ├── profile/       # User profile
    └── settings/      # App settings
```

---


## Prerequisites
- Flutter SDK 3.2+
- Dart 3.2+
- Firebase project with Auth + Firestore + FCM enabled

### 1. Install Flutter
```bash
# Via snap (Ubuntu/Linux)
sudo snap install flutter --classic
flutter doctor
```

### 2. Clone & Setup
```bash
flutter pub get
```

### 3. Configure Firebase
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure your Firebase project
flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID
```
This will auto-generate `lib/firebase_options.dart` with real values.

### 4. Deploy Firestore Rules & Indexes
```bash
firebase deploy --only firestore
```

### 5. Generate Freezed Models
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 6. Run the App
```bash
flutter run
```

---

## Firestore Security Rules

Rules enforce:
- **User isolation** — users can only access their own data
- **Type validation** — amount must be positive number
- **Enum validation** — type must be one of allowed values
- **Soft delete** — `delete` is disabled; use `isDeleted: true`
- **Email verification** — production rules require `email_verified`

---

<!--## Indian Currency Format

All amounts use Indian numbering system:

| Value | Display |
|-------|---------|
| 500 | ₹500 |
| 2500 | ₹2,500 |
| 25000 | ₹25,000 |
| 125000 | ₹1,25,000 |
| 10000000 | ₹1.00Cr |

---
-->

## Supported Platforms

- ✅ Android (primary — SMS import supported)
- ✅ iOS (without SMS import)

---

<!--## 🗄 Firestore Schema

### `/users/{uid}`
```
uid, email, displayName, photoUrl, phoneNumber,
emailVerified, biometricEnabled, pinEnabled,
themeMode, locale, createdAt, updatedAt
```

### `/transactions/{txId}`
```
userId, amount, type, category, date, notes,
bankName, smsId, isDeleted, createdAt, updatedAt
```

### `/loans/{loanId}`
```
userId, type, personName, phoneNumber, amount,
amountPaid, dueDate, status, notes, isDeleted,
createdAt, updatedAt
```

### `/reminders/{remId}`
```
userId, title, type, dueDate, notes, linkedLoanId,
isDone, isDeleted, createdAt, updatedAt
```

---

## ⚠️ Important Notes

1. **`firebase_options.dart`** — Contains placeholder values. Run `flutterfire configure` before running the app.
2. **Font files** — Add Inter font `.ttf` files to `assets/fonts/` (download from fonts.google.com).
3. **SMS Permission** — Android 6.0+ requires runtime SMS permission grant.
4. **Freezed models** — Run `build_runner` to generate `.freezed.dart` and `.g.dart` files.
5. **Google Sign-In** — Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS).
-->
