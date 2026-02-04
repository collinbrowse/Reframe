# Reframe

Transform your activities into stunning social content. Reframe is a mobile app that automatically syncs your Strava activities, matches them with photos and videos from your camera roll, and creates beautiful reels, vlogs, and stories with AI-powered editing.

## Features

### Content Sources
- **Camera Roll**: Automatically import photos and videos with metadata extraction
- **Strava Integration**: Sync activities, routes, and stats
- **Manual Import**: Import files from cloud storage or local files
- **Coming Soon**: Instagram, TikTok, YouTube, GoPro

### Activity Matching
- **Smart Timestamp Matching**: Matches media to activities based on time
- **Location-Based Matching**: Uses GPS data to match content to routes
- **AI Content Analysis**: On-device AI identifies activity-related content

### Output Formats
- **Reels** (9:16 vertical, up to 90s)
- **Vlogs** (16:9 horizontal, unlimited length)
- **Stories** (9:16 vertical, 15s segments)

### Editing Features
- **AI-Powered Editing**: Describe your style and let AI create the edit
- **Filters & Color Grading**: Professional presets and adjustments
- **Transitions**: Smooth transitions between clips
- **Text Overlays**: Add captions and titles
- **Music Library**: Royalty-free tracks and user music

### Privacy & Data
- **Local-First**: Works offline, all data stored on device by default
- **Cloud Sync**: Optional cloud backup with account signup
- **Privacy Controls**: Configurable data collection and analytics
- **Data Export**: Download or delete all your data

## Getting Started

### Prerequisites

- Flutter SDK 3.10.8 or higher
- Dart SDK 3.10.8 or higher
- Xcode 15+ (for iOS)
- Android Studio / Android SDK (for Android)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/your-org/reframe.git
cd reframe
```

2. Install dependencies:
```bash
flutter pub get
```

3. Set up environment variables (see Configuration section)

4. Run the app:
```bash
flutter run
```

## Configuration

### Environment Variables

Create environment variables for the following services:

```bash
# Supabase (Cloud Sync)
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key

# Strava API
STRAVA_CLIENT_ID=your_strava_client_id
STRAVA_CLIENT_SECRET=your_strava_client_secret
STRAVA_REDIRECT_URI=reframe://strava-callback

# PostHog Analytics
POSTHOG_API_KEY=your_posthog_api_key
POSTHOG_HOST=https://app.posthog.com

# RevenueCat (Monetization)
REVENUECAT_API_KEY_IOS=your_revenuecat_ios_key
REVENUECAT_API_KEY_ANDROID=your_revenuecat_android_key

# Optional: OpenAI (Enhanced AI features)
OPENAI_API_KEY=your_openai_api_key
```

Run with environment variables:
```bash
flutter run \
  --dart-define=SUPABASE_URL=xxx \
  --dart-define=SUPABASE_ANON_KEY=xxx \
  --dart-define=STRAVA_CLIENT_ID=xxx \
  --dart-define=STRAVA_CLIENT_SECRET=xxx \
  --dart-define=POSTHOG_API_KEY=xxx
```

### Strava API Setup

1. Go to [Strava API Settings](https://www.strava.com/settings/api)
2. Create a new application:
   - **Application Name**: Reframe
   - **Category**: Social
   - **Website**: Your website URL
   - **Authorization Callback Domain**: `reframe`
3. Copy the Client ID and Client Secret
4. Add them to your environment variables

### Supabase Setup

1. Create a new project at [Supabase](https://supabase.com)
2. Enable Email/Password authentication
3. Enable Google and Apple OAuth providers
4. Create the required tables (see `database/schema.sql`)
5. Copy the project URL and anon key

### PostHog Setup

1. Create an account at [PostHog](https://posthog.com)
2. Create a new project
3. Copy the API key
4. Configure event tracking as needed

### RevenueCat Setup

1. Create an account at [RevenueCat](https://www.revenuecat.com)
2. Set up your app for iOS and Android
3. Create products for:
   - Monthly subscription ($9.99/month)
   - Annual subscription ($79.99/year)
   - Lifetime purchase ($199.99)
4. Copy the API keys for each platform

## Project Structure

```
lib/
├── main.dart                  # App entry point
├── core/
│   ├── config/               # Environment configuration
│   ├── constants/            # App constants and enums
│   ├── providers/            # Riverpod providers
│   ├── routing/              # Go Router configuration
│   └── theme/                # App theme and styling
├── features/
│   ├── auth/                 # Authentication screens
│   ├── onboarding/           # Onboarding flow
│   ├── home/                 # Home dashboard
│   ├── activities/           # Activity list and details
│   ├── sources/              # Content source connections
│   ├── editor/               # Video editor
│   ├── export/               # Export and sharing
│   ├── settings/             # Settings and privacy
│   └── monetization/         # Subscription screens
├── models/                   # Data models
├── services/
│   ├── ai/                   # Activity matching AI
│   ├── analytics/            # PostHog analytics
│   ├── api/                  # Strava API service
│   ├── sources/              # Camera roll service
│   ├── storage/              # Local storage
│   └── video/                # FFmpeg video editor
└── widgets/                  # Reusable widgets
```

## Tech Stack

- **Framework**: Flutter 3.10+
- **State Management**: Riverpod
- **Navigation**: Go Router
- **Local Storage**: Hive + SharedPreferences
- **Secure Storage**: flutter_secure_storage
- **Video Processing**: FFmpeg Kit
- **Analytics**: PostHog
- **Auth & Backend**: Supabase
- **Monetization**: RevenueCat

## Building for Production

### iOS

```bash
flutter build ios --release \
  --dart-define=SUPABASE_URL=xxx \
  --dart-define=SUPABASE_ANON_KEY=xxx \
  # ... other environment variables
```

### Android

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=xxx \
  --dart-define=SUPABASE_ANON_KEY=xxx \
  # ... other environment variables
```

## Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is proprietary software. All rights reserved.

## Support

For questions or support, please contact support@reframe.app

---

Built with Flutter and lots of caffeine by the Reframe team.
