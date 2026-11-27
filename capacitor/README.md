# Тогуз коргоол — web version as an app (Capacitor)

This folder wraps the web game (`../index.html`) as a real Android and iOS app.
It doesn't run in Chrome, so there's no swipe-to-refresh and no address bar, and it works with no internet (fonts are bundled).

Change the game only in `../index.html`. This folder copies it in when you build.

## Try it on Android (no setup)

Open **https://github.com/suiunov/toguz/releases/tag/web-app-latest** on your phone, download `toguz-web-app.apk`, open it.
A new APK is built automatically on every push to `main` that changes `index.html` or `capacitor/`.

## Build on the Mac

Needs Node.js, Android Studio (for Android) and Xcode (for iOS).

```bash
cd toguz/capacitor
npm install
npm run android   # copies the game, opens Android Studio → Run, or Build → Generate Signed Bundle (.aab) for Google Play
npm run ios       # copies the game, opens Xcode → pick your Team in Signing → Run, or Product → Archive for the App Store
```

## Commands

- `npm run build` — copy `../index.html` into `www/` (bundled fonts, no service worker, no "Install app" button)
- `npm run sync` — build + update both native projects
- `npm run icons` — remake icons and splash from `assets/`

App id: `kg.toguz.web` (different from the Flutter app `kg.toguz.toguzKorgool`, so both can be on one phone).
