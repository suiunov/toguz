# Тогуз коргоол — Android and iOS app (Flutter)

The same game as the web version, as a real app for Google Play and the App Store.

## Try it on Android (no setup)

1. On your Android phone, open **https://github.com/suiunov/toguz/releases/tag/app-latest**.
2. Download **app-release.apk** and open it. Allow "Install unknown apps" when asked.

Every push to `main` that changes `app/` builds a new APK there automatically (GitHub Actions, file `.github/workflows/app.yml`).

## Run it on your iPhone from the Mac

One-time setup (about 30–60 minutes, mostly downloads):

1. Install **Xcode** from the Mac App Store, open it once and accept the licence.
2. Install Flutter: https://docs.flutter.dev/get-started/install/macos (choose "iOS").
   Then in Terminal: `flutter doctor` — fix anything it marks with ✗ for iOS.
3. Install CocoaPods if `flutter doctor` asks: `sudo gem install cocoapods`.

Run the app:

```bash
git clone https://github.com/suiunov/toguz.git
cd toguz/app
flutter pub get
open ios/Runner.xcworkspace
```

In Xcode: click **Runner** → **Signing & Capabilities** → choose your Apple ID as **Team**
(add it in Xcode → Settings → Accounts). Plug in the iPhone, trust the computer, then:

```bash
flutter run --release
```

The first time, on the iPhone go to **Settings → General → VPN & Device Management** and trust your developer certificate.

## Put it on the stores

### Google Play
1. Create a developer account at https://play.google.com/console ($25 once).
2. New personal accounts must run a **closed test with at least 12 testers for 14 days** before going public — invite friends early.
3. Make an upload key once, on the Mac:
   ```bash
   keytool -genkey -v -keystore ~/toguz-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   Keep this file and its password safe — you need it for every update.
4. Create `app/android/key.properties` (never commit it):
   ```
   storePassword=...
   keyPassword=...
   keyAlias=upload
   storeFile=/Users/<you>/toguz-upload.jks
   ```
   and add the signing config to `app/android/app/build.gradle(.kts)` as described in
   https://docs.flutter.dev/deployment/android#configure-signing-in-gradle
5. Build the store file: `flutter build appbundle` → upload `build/app/outputs/bundle/release/app-release.aab`.

### App Store
1. Join the Apple Developer Program at https://developer.apple.com/programs/ ($99 per year).
2. In https://appstoreconnect.apple.com create the app (bundle id `kg.toguz.toguzKorgool` or the one shown in Xcode).
3. On the Mac: `flutter build ipa`, then open `build/ios/archive/Runner.xcarchive` in Xcode → **Distribute App** → App Store Connect.
4. Test it with TestFlight, then submit for review.

Both stores need: app name, short description, screenshots (phone), a 512×512 / 1024×1024 icon (`assets/icon.png`), a privacy policy link, and a content rating. The app collects no data, works offline and has no ads.

## Code

- `lib/engine/` — rules, trained computer, tasks (same as the web version; tests in `test/` replay games recorded with the web engine)
- `lib/ui/` — board, menu, task panel
- `lib/controller.dart` — game flow, animation, settings
- `lib/i18n.dart` — Kyrgyz and English texts
