/// Environment configuration for Reframe
/// These values should be set via environment variables or a secure config
class EnvConfig {
  EnvConfig._();

  // Supabase Configuration
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // Strava API Configuration
  static const String stravaClientId = String.fromEnvironment(
    'STRAVA_CLIENT_ID',
    defaultValue: '',
  );
  
  static const String stravaClientSecret = String.fromEnvironment(
    'STRAVA_CLIENT_SECRET',
    defaultValue: '',
  );
  
  static const String stravaRedirectUri = String.fromEnvironment(
    'STRAVA_REDIRECT_URI',
    defaultValue: 'reframe://strava-callback',
  );

  // PostHog Analytics
  static const String posthogApiKey = String.fromEnvironment(
    'POSTHOG_API_KEY',
    defaultValue: '',
  );
  
  static const String posthogHost = String.fromEnvironment(
    'POSTHOG_HOST',
    defaultValue: 'https://app.posthog.com',
  );

  // RevenueCat (Monetization)
  static const String revenuecatApiKeyIos = String.fromEnvironment(
    'REVENUECAT_API_KEY_IOS',
    defaultValue: '',
  );
  
  static const String revenuecatApiKeyAndroid = String.fromEnvironment(
    'REVENUECAT_API_KEY_ANDROID',
    defaultValue: '',
  );

  // AI Services (Optional - for enhanced features)
  static const String openaiApiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );

  // Feature Flags
  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: true,
  );
  
  static const bool enableCloudSync = bool.fromEnvironment(
    'ENABLE_CLOUD_SYNC',
    defaultValue: true,
  );
  
  static const bool enableAiNarration = bool.fromEnvironment(
    'ENABLE_AI_NARRATION',
    defaultValue: false,
  );

  // Check if required configs are set
  static bool get isSupabaseConfigured => 
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  
  static bool get isStravaConfigured => 
      stravaClientId.isNotEmpty && stravaClientSecret.isNotEmpty;
  
  static bool get isPosthogConfigured => posthogApiKey.isNotEmpty;
  
  static bool get isRevenuecatConfigured => 
      revenuecatApiKeyIos.isNotEmpty || revenuecatApiKeyAndroid.isNotEmpty;
  
  static bool get isOpenaiConfigured => openaiApiKey.isNotEmpty;
}

/// Strava API setup instructions
class StravaSetupInstructions {
  static const String instructions = '''
To set up Strava API access:

1. Go to https://www.strava.com/settings/api
2. Create a new application with these details:
   - Application Name: Reframe
   - Category: Social
   - Website: Your website URL
   - Authorization Callback Domain: reframe://strava-callback
   
3. After creation, you'll receive:
   - Client ID
   - Client Secret
   
4. Set these as environment variables:
   - STRAVA_CLIENT_ID=your_client_id
   - STRAVA_CLIENT_SECRET=your_client_secret
   
5. In your Flutter run command:
   flutter run --dart-define=STRAVA_CLIENT_ID=xxx --dart-define=STRAVA_CLIENT_SECRET=xxx
''';
}
