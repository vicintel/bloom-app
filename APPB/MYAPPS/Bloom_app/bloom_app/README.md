# Bloom — AI-Powered Menstrual & Wellness Companion

Bloom is a privacy-first Flutter app that helps users track their menstrual cycle, log daily wellness, and receive AI-powered personalized insights — including tailored nutrition, fitness, and supplement guidance — powered by the Groq API (Llama 3.3 70B).

Live demo: [https://bloom-app-iota.vercel.app](https://bloom-app-iota.vercel.app)

---

## Features

### Cycle Tracking & Prediction
- Log period start dates and cycle length
- Automatically calculates current cycle phase: **Menstrual**, **Follicular**, **Ovulation**, or **Luteal**
- **Period prediction** — predicts next period date based on logged history; confidence improves with each cycle logged
- **Fertile window & ovulation day** calculated and shown on calendar
- **Birth Control Mode** — switches phase display to Active/Inactive for pill users
- Custom cycle length setting (21–45 days)

### Phase-Aware Dashboard
- Circular cycle progress ring built with `CustomPainter`
- Collapsible gradient hero header with current phase and day count
- **Next period prediction card** with countdown and urgency color coding
- **Calendar** highlights: predicted period (red), fertile window (green), ovulation day (yellow star), logged period dates (red dot)
- Calendar legend for all markers
- **Water & sleep wellness chips** shown if logged today
- AI-generated daily insight card, refreshable on demand
- Quick-access cards for Nutrition and Fitness

### Daily Check-In (Enhanced)
- Log your mood (8 options: Happy, Calm, Tired, Anxious, Irritable, Sad, Energetic, Unwell)
- **Flow intensity** selector (Spotting / Light / Medium / Heavy) — shown during Menstrual phase
- **Pain scale** slider 0–5
- **Water tracker** — 8 tap-to-fill drop icons
- **Sleep hours** slider 0–12
- Free-text mood description and symptoms
- AI analysis sends all check-in data + cycle phase to Groq and returns:
  - **Insight** — personalized wellness reflection
  - **Nutrition** — what to eat today based on your mood and phase
  - **Fitness** — workout recommendation tailored to how you're feeling
- All check-in data saved to local history for chart analysis

### Nutrition Page
- Phase-specific food recommendations (4 foods per phase) with real photos
- AI-generated meal idea at the top — refreshable
- Foods curated per phase: iron-rich (Menstrual), hormone-supporting (Follicular), anti-inflammatory (Ovulation), mood-stabilizing (Luteal)

### Fitness Page
- Phase-specific workout recommendations (4 per phase) with background images
- Intensity badge color coding: Rest=grey, Low=green, Moderate=blue, High=red
- AI-generated workout plan at the top — refreshable

### History Page (Charts)
- **Mood trend line chart** — last 14 check-ins plotted as a score (1–5)
- **Cycle length bar chart** — last 6 periods showing length variation
- **Symptom frequency chart** — top 5 symptoms (cramps, bloating, headache, fatigue, nausea) from check-in history
- **Recent check-ins list** — last 5 entries with date, mood emoji, pain level, flow

### Insights Page
- **AI Monthly Report** — Groq-powered summary of your cycle: mood patterns, common symptoms, recommendations for next month
- **Fertile window info card** with days countdown
- **Phase-specific supplement suggestions** (3 per phase):
  - Menstrual: Iron, Magnesium, Ginger
  - Follicular: B Vitamins, Zinc, Probiotics
  - Ovulation: Vitamin C, CoQ10, Maca
  - Luteal: Vitamin D, Calcium, Evening Primrose
- **Custom cycle length** slider (21–45 days)
- **Birth Control Mode** toggle

### Profile & Settings
- Name and email editing
- Cycle settings section with length display and birth control mode toggle
- Navigation links to History, Monthly Report, and Security Settings
- Dark/light mode toggle with accent color picker
- Theme persists across sessions

### Security & Privacy
- Biometric lock (fingerprint / Face ID) on app open
- Privacy screen — app content hidden in device app switcher
- Push notification reminders (8am daily check-in, late period alert 2 days after expected date)

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
│   ├── dashboard_page.dart      # Phase hero, prediction, calendar, AI insight
│   ├── checkin_page.dart        # Full wellness check-in with AI recommendations
│   ├── nutrition_page.dart      # Phase-specific food guide + AI meal ideas
│   ├── fitness_page.dart        # Phase-specific workout guide + AI plans
│   ├── history_page.dart        # Charts: mood trend, cycle length, symptoms
│   ├── insights_page.dart       # AI monthly report, supplements, cycle settings
│   ├── onboarding_page.dart     # First-run setup flow
│   ├── login_page.dart          # Auth screen
│   ├── signup_page.dart
│   ├── profile_page.dart        # User profile, cycle settings, navigation links
│   ├── security_settings.dart   # Biometric & security config
│   └── locked_page.dart         # Biometric lock screen
├── state/
│   ├── cycle_state.dart         # Cycle tracking, phase, prediction, check-in history
│   └── theme_notifier.dart      # Dark mode + seed color, persisted
├── services/
│   ├── auth_service.dart        # Mock auth (swap with Firebase)
│   ├── security_service.dart    # Biometric auth wrapper
│   ├── notification_service.dart # Daily reminders + late period alert
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
| Charts | fl_chart |
| Local Storage | shared_preferences, flutter_secure_storage |
| Biometric Auth | local_auth |
| Notifications | flutter_local_notifications |
| Fonts | Google Fonts (Poppins, Philosopher) |
| Calendar | table_calendar |
| Environment | flutter_dotenv |

---

## AI Integration

Bloom uses the **Groq API** with the `llama-3.3-70b-versatile` model for four AI features:

1. **Dashboard Insight Card** — daily wellness tip based on your cycle phase
2. **Check-In Analysis** — takes mood, pain, flow, sleep, water, symptoms, and cycle phase; returns structured JSON with insight, nutrition, and fitness recommendations
3. **Nutrition & Fitness Pages** — personalized meal ideas and workout plans on demand
4. **Monthly Insights Report** — comprehensive summary of cycle patterns, mood trends, and recommendations for next month

All AI requests use `response_format: { type: "json_object" }` for reliable structured output. The app falls back to curated phase-specific content if the API is unavailable.

Your API key is stored in a local `.env` file and is never committed to version control.

---

## Privacy

- All cycle, health, and check-in data is stored **locally on device** — nothing is sent to any server
- The `.env` file containing your API key is gitignored and never committed
- The privacy screen hides app content in the iOS/Android app switcher
- Biometric authentication locks the app on every open

---

## Deployment

### Vercel (current)

```bash
flutter build web --release --base-href "/"
vercel --prod build/web
```

### GitHub Pages

A GitHub Actions workflow (`.github/workflows/deploy.yml`) is configured to build and deploy automatically on push to `main`.

To enable:
1. Go to **Settings → Pages** → set source to **GitHub Actions**
2. Go to **Settings → Secrets → Actions** → add `GROQ_API_KEY`
3. Push to `main`

---

## Roadmap

- [ ] Firebase auth + cloud sync across devices
- [ ] Doctor export — PDF cycle report
- [ ] Partner mode (shared cycle visibility)
- [ ] Apple Health / Google Fit integration
- [ ] Wearable data (heart rate, sleep) integration
- [ ] Offline AI fallback with on-device model
- [ ] iOS & Android store release

---

## License

MIT License — see [LICENSE](LICENSE) for details.
