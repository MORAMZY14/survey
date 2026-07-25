# Block Survey

A Flutter field-survey application for mapping apartment blocks by GPS and
storing the results in Firebase.

## Included features

- Email/password registration and sign-in.
- Central organization for areas such as El-Hadra and Karmouz.
- Shared Central filter across the map and survey list.
- In-app Central creation and activation controls visible only to admins.
- GPS-centred Google Map with manual map selection when GPS is unavailable.
- Existing block markers and a warning when a new point is within 15 metres of
  a surveyed block.
- Apartment-block photo.
- A marker placed directly on the block photo to show the exact proposed
  Internet-box mounting point.
- Optional close-up photo and installation instructions for the mounting point.
- Automatic floor generation from a default number of apartments.
- Per-floor apartment-count and note exceptions.
- Live Firestore survey map and searchable survey list.
- Firebase Storage uploads limited to authenticated surveyors by the included
  rules.
- Light and dark themes.

## Data stored for each block

The `blockSurveys/{surveyId}` document contains:

```text
centralId
centralName
blockName
address
location                 GeoPoint
locationAccuracy
geohash
defaultApartmentsPerFloor
startsWithGroundFloor
totalFloors
totalApartments
exceptionCount
floors[]                 label, apartmentCount, notes, isException
blockPhotoUrl
blockPhotoStoragePath
internetBox              mountingArea, instructions, photo URL,
                         normalized x/y marker on the block photo
generalNotes
status                   submitted / approved / rejected
createdBy
createdByName
createdAt
updatedAt
```

The `centrals/{centralId}` collection contains:

```text
name
normalizedName
active
createdBy
createdByName
createdAt
updatedAt
```

Central document IDs are derived from normalized names, so capitalization or
extra spaces cannot create duplicate El-Hadra records. Inactive Centrals keep
their existing surveys but cannot receive new ones.

## First-time setup on Windows

The Android and iOS projects are included and were generated with Flutter
3.44.2 / Dart 3.12.2.

### 1. Create Google Maps keys

In Google Cloud Console:

1. Enable **Maps SDK for Android** and **Maps SDK for iOS**.
2. Create an Android API key and restrict it to your Android application.
3. Create a separate iOS API key and restrict it to your iOS bundle ID.
4. Keep billing enabled for Google Maps Platform.

Open PowerShell inside this project and download the packages:

```powershell
flutter clean
flutter pub get
```

Add the restricted Android key to `android/local.properties`. Flutter creates
this file automatically; add the final line without removing `flutter.sdk`:

```properties
MAPS_API_KEY=YOUR_ANDROID_GOOGLE_MAPS_API_KEY
```

For iOS, copy the ignored key template:

```powershell
Copy-Item `
  .\ios\Flutter\MapsKeys.xcconfig.example `
  .\ios\Flutter\MapsKeys.xcconfig
```

Open `ios/Flutter/MapsKeys.xcconfig` and replace the placeholder with the
restricted iOS key. Android minimum SDK 24, iOS minimum version 14, GPS
permissions, and the native Google Maps initialization are already configured.

Do not commit real API keys to a public repository.

### 2. Connect Firebase

Install and sign in to the Firebase tools:

```powershell
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
```

From this project folder, run:

```powershell
flutterfire configure
```

Select your Firebase project and the Android and iOS applications. This command
replaces the placeholder `lib/firebase_options.dart` with your real,
non-secret Firebase application identifiers.

### 3. Enable Firebase products

In Firebase Console:

1. Authentication → Sign-in method → enable **Email/Password**.
2. Firestore Database → create the database.
3. Storage → create the default bucket.

Cloud Storage for Firebase currently requires the pay-as-you-go **Blaze** plan.
Set budget alerts in Google Cloud before field deployment.

Deploy the included protected rules and indexes:

```powershell
firebase use YOUR_FIREBASE_PROJECT_ID
firebase deploy --only firestore:rules,firestore:indexes,storage
```

### 4. Create the first admin

All accounts created inside the app start with `role: surveyor`. This prevents
users from giving themselves admin access.

1. Register the first account in the app.
2. Open Firestore Console → `users` → the document matching that user's UID.
3. Change `role` from `surveyor` to `admin`.
4. Sign out and back in.
5. Open **Profile → Manage Centrals** and create El-Hadra, Karmouz, or the
   required Centrals.

The interface hides Central management from surveyors, and the included
Firestore rules independently reject Central writes from non-admin accounts.

### 5. Run and test

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```

Test camera and GPS on a real phone. Simulators can use mock locations but do
not reproduce field accuracy.

## Survey workflow

1. Sign in as a surveyor.
2. On the map, tap the centre of the apartment block.
3. Select **Survey**.
4. Select its Central, such as El-Hadra or Karmouz.
5. Enter the block name and its normal floor layout.
6. Change any floor that has a different apartment count. It is automatically
   marked as an exception.
7. Take the block photo.
8. Tap the exact wall position on the photo where the Internet box should be
   installed.
9. Choose the mounting area, add installation notes, and optionally take a
   close-up photo.
10. Save the survey. Firestore receives the complete survey only after the
   photo uploads succeed; failed uploads are cleaned up on a best-effort basis.

## Production notes

- Use separate restricted Google Maps keys for Android and iOS.
- Enable Firebase App Check before public deployment.
- Keep the provided rules; do not use test-mode public rules.
- The map intentionally uses a pin rather than relying on selectable building
  outlines. Map providers do not expose reliable building identifiers
  everywhere, so the pin keeps the survey usable where footprint data is
  missing.
- Firestore mobile clients cache documents, but a brand-new survey containing
  photos needs a connection to upload to Storage. A true offline photo queue can
  be added as a second phase.
