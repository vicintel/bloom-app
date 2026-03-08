# Bloom — AI-Powered Menstrual & Wellness Companion

Bloom is a privacy-first Flutter app that helps users track their menstrual cycle, log daily wellness, and receive AI-powered personalized insights — including tailored nutrition and fitness guidance — powered by the Groq API (Llama 3.3 70B).

Live demo: [https://bloom-app-iota.vercel.app](https://bloom-app-iota.vercel.app)

---

## Features

### Cycle Tracking
- Log period start dates and cycle length
- Automatically calculates your current cycle phase: **Menstrual**, **Follicular**, **Ovulation**, or **Luteal**
- Phase-aware UI — gradients, colors, and advice all change with your phase

### Phase-Aware Dashboard
- Circular cycle progress ring built with `CustomPainter`
- Collapsible gradient hero header with current phase and day count
- AI-generated daily insight card, refreshable on demand
- Quick-access cards for Nutrition and Fitness

### AI Daily Check-In
- Log your mood (Happy, Calm, Tired, Anxious, Irritable, Sad, Energetic, Unwell), symptoms, and a free-text description
- The app sends your check-in data + current cycle phase to the Groq AI
- Receives structured AI analysis with three cards:
  - **Insight** — personalized wellness reflection
  - **Nutrition** — what to eat today based on your mood and phase
  - **Fitness** — workout recommendation tailored to how you're feeling
- Tap any recommendation card to go directly to the full Nutrition or Fitness page

### Nutrition Page
- Phase-specific food recommendations (4 foods per phase)
- Each food card includes: name, benefit, and a real photo
- AI-generated meal idea at the top — tap refresh for a new suggestion
- Foods are curated per phase:
  - **Menstrual**: Iron-rich foods (leafy greens, dark chocolate, lentils, red meat)
  - **Follicular**: Hormone-supporting foods (eggs, fermented foods, flaxseeds, quinoa)
  - **Ovulation**: Anti-inflammatory foods (salmon, avocado, berries, Brazil nuts)
  - **Luteal**: Mood-stabilizing foods (sweet potato, pumpkin seeds, chamomile, oats)

### Fitness Page
- Phase-specific workout recommendations (4 workouts per phase)
- Full-width workout cards with background images, intensity badge, and duration
- Intensity color coding: Rest=grey, Low=green, Moderate=blue, High=red
- AI-generated workout plan at the top — refreshable
- Workouts adapt to your energy levels per phase:
  - **Menstrual**: Rest, gentle yoga, walking, light stretching
  - **Follicular**: HIIT, strength training, running, cycling
  - **Ovulation**: High-intensity circuits, group classes, dance, plyometrics
  - **Luteal**: Pilates, swimming, barre, hiking

### Personalization & Settings
- Dark mode and light mode toggle
- Accent color picker — theme updates app-wide
- Settings persist across sessions via `shared_preferences`
- Biometric lock (fingerprint / Face ID) on app open
- Privacy screen — app content hidden in device app switcher
- Push notification reminders at 8am daily

---

## Screenshots

> Coming soon

---

## Getting Started

### Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install) SDK >= 3.10
- A [Groq API key](https://console.groq.com) (free tier available)

### Setup

```bash
# 1. Clone the repo
git clone https://github.com/vicintel/bloom-app.git
cd bloom-app/APPB/MYAPPS/Bloom_app/bloom_app

# 2. Install dependencies
flutter pub get

# 3. Create your .env file
echo "GROQ_API_KEY=your_key_here" > .env

# 4. Run the app
flutter run
```

### Running on specific platforms

```bash
flutter run -d chrome        # Web
flutter run -d macos         # macOS desktop
flutter run -d android       # Android device/emulator
flutter run -d ios           # iOS simulator
```

### Build for web

```bash
flutter build web --release --base-href "/"
```

---

## Project Structure

```
lib/
├── main.dart                    # App entry point, providers, theme setup
├── app_router.dart              # go_router config + NavigationBar shell
├── pages/
│   ├── dashboard_page.dart      # Phase hero, AI insight, quick-nav cards
│   ├── checkin_page.dart        # Mood check-in with AI-powered recommendations
│   ├── nutrition_page.dart      # Phase-specific food guide + AI meal ideas
│   ├── fitness_page.dart        # Phase-specific workout guide + AI workout plans
│   ├── onboarding_page.dart     # First-run setup flow
│   ├── login_page.dart          # Auth screen (mock, ready for Firebase)
│   ├── signup_page.dart
│   ├── profile_page.dart        # User profile + theme settings
│   ├── security_settings.dart   # Biometric & security config
│   └── locked_page.dart         # Biometric lock screen
├── state/
│   ├── cycle_state.dart         # Cycle tracking, phase calculation, persistence
│   └── theme_notifier.dart      # Dark mode + seed color, persisted
├── services/
│   ├── auth_service.dart        # Mock auth (swap with Firebase)
│   ├── security_service.dart    # Biometric auth wrapper
│   ├── notification_service.dart
│   └── haptics.dart
└── widgets/
    ├── advice_card.dart         # Phase-specific advice card (dashboard)
    ├── privacy_shield.dart      # Privacy screen wrapper
    ├── theme_settings_sheet.dart
    └── ...
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x (Dart) |
| State Management | Provider (ChangeNotifier) |
| Navigation | go_router v13 |
| AI / LLM | Groq API — Llama 3.3 70B Versatile |
| Local Storage | shared_preferences, flutter_secure_storage |
| Biometric Auth | local_auth |
| Notifications | flutter_local_notifications |
| Fonts | Google Fonts (Poppins, Philosopher) |
| Calendar | table_calendar |
| Environment | flutter_dotenv |

---

## AI Integration

Bloom uses the **Groq API** with the `llama-3.3-70b-versatile` model for three AI features:

1. **Dashboard Insight Card** — generates a short daily wellness tip based on your cycle phase
2. **Check-In Analysis** — takes your mood, symptoms, description, and cycle phase; returns structured JSON with an insight, nutrition recommendation, and fitness recommendation
3. **Nutrition & Fitness Pages** — generates personalized meal ideas and workout plans on demand

All AI requests use `response_format: { type: "json_object" }` for reliable structured output. If the API is unavailable, the app falls back to curated phase-specific content.

Your API key is stored in a local `.env` file and is never committed to version control.

---

## Privacy

- All cycle and health data is stored **locally on device** — nothing is sent to any server
- The `.env` file containing your API key is gitignored and never committed
- The privacy screen hides app content in the iOS/Android app switcher
- Biometric authentication locks the app on every open

---

## Deployment

### Vercel (current)

The web build is deployed to Vercel. After building:

```bash
flutter build web --release --base-href "/"
vercel --prod build/web
```

### GitHub Pages

A GitHub Actions workflow (`.github/workflows/deploy.yml`) is configured to build and deploy automatically on push to `main`.

To enable:
1. Go to **Settings → Pages** → set source to **GitHub Actions**
2. Go to **Settings → Secrets → Actions** → add `GROQ_API_KEY`
3. Push to `main` — the app deploys to `https://vicintel.github.io/bloom-app/`

---

## Roadmap

- [ ] Firebase auth + cloud sync across devices
- [ ] Symptom history charts and trends
- [ ] Period prediction with AI confidence scoring
- [ ] Partner mode (shared cycle visibility)
- [ ] Apple Health / Google Fit integration
- [ ] Wearable data (heart rate, sleep) integration
- [ ] Offline AI fallback with on-device model
- [ ] iOS & Android store release

---

## License

MIT License — see [LICENSE](LICENSE) for details.
