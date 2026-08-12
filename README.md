# Bloom

An AI-powered menstrual health and wellness companion for Android and iOS. Log symptoms,
track your cycle, and get advice that adapts to the phase you're actually in — with the
whole thing locked behind device biometrics, because this is the most private data most
people carry.

Built with Flutter (Dart 3).

## What it does

- **Cycle tracking** — calendar view with phase prediction and an ovulation window
- **Daily check-in** — symptom, mood and energy logging
- **Insights** — charts over your own history (`fl_chart`), not population averages
- **Fitness and nutrition** — guidance tuned to the current cycle phase
- **Messages** — conversational AI advice
- **Privacy first** — biometric unlock (`local_auth`), a locked state when auth fails,
  a privacy shield that blanks the app in the recents switcher, and secrets in the
  device keystore (`flutter_secure_storage`) rather than shared preferences

## How it's put together

```
lib/pages/      15 screens — onboarding, auth, dashboard, check-in, insights, settings
lib/services/   auth, notifications, security/biometrics, haptics
lib/state/      cycle state, message store, theme — Provider
lib/widgets/    cycle + phase calendars, symptom logger, glass containers, advice cards
lib/app_router  go_router route table
```

The AI key is injected at compile time with `--dart-define` and read through
`String.fromEnvironment`, so no key is ever written into a file that gets committed.

## Running it locally

The Flutter project lives at `APPB/MYAPPS/Bloom_app/bloom_app/`:

```bash
cd APPB/MYAPPS/Bloom_app/bloom_app
flutter pub get
flutter run --dart-define=GROQ_API_KEY=your_key_here
```

Requires the Flutter SDK (Dart `^3.10.8`).

## Status

A personal project, not a shipped product. It is not a contraceptive tool and gives no
medical advice — predictions are estimates from your own logged data.

## License

MIT
