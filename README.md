# AccessWay AI

Accessibility intelligence platform prototype.

## Current MVP
- Home dashboard
- Searchable demo place directory
- Feature-by-feature Accessibility Passport
- Barrier report form
- In-session report list/count
- Light, dark and system themes

## Run locally
Install Flutter and Android Studio, then:

```bash
flutter create . --platforms=android
flutter pub get
flutter run
```

Build a debug APK:

```bash
flutter build apk --debug
```

## Current limitations
This is an early UI prototype. Sample places are fictional demo data and are not verified real-world locations. Reports are stored only in memory and disappear when the app restarts. There is no cloud backend, live map, photo upload, AI image recognition, Scout BLE connection, or institutional dashboard yet.

## Data integrity principles
- Unknown does not mean inaccessible.
- Community reports are not institution-confirmed facts.
- Keep timestamps and evidence sources.
- Mark old records as needing rechecking.
- A photo or one measurement cannot certify a whole building.

## Planned milestones
1. SQLite persistence
2. Supabase sync and institution roles
3. Evidence/photo upload with privacy controls
4. ESP32 Scout BLE integration
5. Command dashboard
6. Human-reviewed AI barrier suggestions
