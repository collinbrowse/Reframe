/// App-wide constants for Reframe
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Reframe';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String userPrefsKey = 'user_preferences';
  static const String authTokenKey = 'auth_token';
  static const String localUserKey = 'local_user';
  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String privacySettingsKey = 'privacy_settings';
  
  // API Endpoints
  static const String stravaAuthUrl = 'https://www.strava.com/oauth/authorize';
  static const String stravaTokenUrl = 'https://www.strava.com/oauth/token';
  static const String stravaApiBaseUrl = 'https://www.strava.com/api/v3';
  
  // Strava Scopes
  static const List<String> stravaScopes = [
    'read',
    'activity:read',
    'activity:read_all',
    'profile:read_all',
  ];
  
  // Video Defaults
  static const int defaultReelDuration = 30; // seconds
  static const int defaultStoryDuration = 15; // seconds
  static const int maxVlogDuration = 600; // 10 minutes
  static const int videoExportQuality = 1080; // pixels
  static const String videoCodec = 'libx264';
  static const String audioCodec = 'aac';
  
  // Activity Matching
  static const int activityBufferMinutes = 30; // Buffer before/after activity
  static const double locationMatchRadius = 500; // meters
  
  // Cache Settings
  static const int maxCachedActivities = 100;
  static const int maxCachedMedia = 500;
  static const Duration cacheExpiry = Duration(days: 7);
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 12.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
  
  // Monetization
  static const String revenucatApiKey = ''; // Set in environment
  static const String freeTrialDays = '7';
  
  // Analytics
  static const bool analyticsEnabled = true;
}

/// Output format types
enum OutputFormat {
  reel('Reel', 'Short-form vertical video', '9:16'),
  vlog('Vlog', 'Long-form horizontal video', '16:9'),
  story('Story', 'Temporary vertical content', '9:16');

  final String label;
  final String description;
  final String aspectRatio;
  
  const OutputFormat(this.label, this.description, this.aspectRatio);
}

/// Content source types
enum ContentSource {
  cameraRoll('Camera Roll', 'photos_library'),
  strava('Strava', 'strava'),
  instagram('Instagram', 'instagram'),
  tiktok('TikTok', 'tiktok'),
  youtube('YouTube', 'youtube'),
  manualImport('Import File', 'file_upload');

  final String label;
  final String icon;
  
  const ContentSource(this.label, this.icon);
}

/// Activity types matching Strava
enum ActivityType {
  run('Run', '🏃'),
  ride('Ride', '🚴'),
  swim('Swim', '🏊'),
  walk('Walk', '🚶'),
  hike('Hike', '🥾'),
  alpineSki('Alpine Ski', '⛷️'),
  backcountrySki('Backcountry Ski', '🎿'),
  workout('Workout', '💪'),
  weightTraining('Weight Training', '🏋️'),
  yoga('Yoga', '🧘'),
  crossfit('CrossFit', '🔥'),
  rockClimbing('Rock Climbing', '🧗'),
  surfing('Surfing', '🏄'),
  kayaking('Kayaking', '🚣'),
  rowing('Rowing', '🚣'),
  golf('Golf', '⛳'),
  other('Other', '🎯');

  final String label;
  final String emoji;
  
  const ActivityType(this.label, this.emoji);
  
  static ActivityType fromString(String type) {
    return ActivityType.values.firstWhere(
      (e) => e.name.toLowerCase() == type.toLowerCase(),
      orElse: () => ActivityType.other,
    );
  }
}

/// Auth mode for the app
enum AuthMode {
  local('Local Only'),
  authenticated('Cloud Sync');

  final String label;
  const AuthMode(this.label);
}

/// Privacy levels
enum PrivacyLevel {
  minimal('Minimal', 'Only essential data collection'),
  standard('Standard', 'Balanced privacy and features'),
  maximum('Maximum', 'Full features, more data collection');

  final String label;
  final String description;
  
  const PrivacyLevel(this.label, this.description);
}
