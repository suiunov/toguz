# Тогуз коргоол

Кыргыздын улуттук оюну — телефондо ойноого ылайыкталган веб-тиркеме.

- Компьютерге каршы (Жеңил / Орто / Оор / Чебер / Улуу чебер), 2 оюнчу, же компьютер өзү ойнойт
- 10 тапшырма (Башталгычтан Чеберге чейин): кеңеш жана мыкты жүрүш
- Үн эффекттери, жүрүштү алдын ала көрүү, ылдамдык (Дароо да бар)
- Меню, жөндөөлөр, кыргызча / English
- Интернетсиз иштейт, Chrome аркылуу телефонго орнотулат

**Ойноо:** https://suiunov.github.io/toguz/

Телефондо Chrome менен ачып, «Телефонго орнотуу» баскычын басыңыз.

## Компьютер оюнчу

Компьютер позицияны 6 белги менен баалайт (казан, туздук, тактадагы коргоолдор, жүрүш жасала турган үйлөр, утуу коркунучтары). Салмактары өзү менен өзү ойногон миңдеген оюн аркылуу үйрөтүлгөн (`tools/tune.js`, `tools/engine.js`).

## Онлайн оюн / Online play

Player enters a name, creates a game and sends the 4-digit code (or link) to a friend. No sign-in.
Moves go through Firebase Realtime Database (free plan is enough).

Turn it on once:
1. https://console.firebase.google.com → **Add project** (Analytics not needed).
2. **Build → Authentication → Get started → Anonymous → Enable**.
3. **Build → Realtime Database → Create database** (any location, start in locked mode) → **Rules** tab → paste `tools/firebase-rules.json` → **Publish**.
4. **Project settings → Your apps → Web (</>)** → register → copy the `firebaseConfig` object into `FIREBASE_CONFIG` in `index.html`.

Test without Firebase: open `index.html?net=local` in two tabs of the same browser.
