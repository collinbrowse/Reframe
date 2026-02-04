import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import '../core/constants/app_constants.dart';

part 'user.g.dart';

/// User model for Reframe app
@JsonSerializable()
class AppUser extends Equatable {
  final String id;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
  final AuthMode authMode;
  final DateTime createdAt;
  final DateTime? lastSyncAt;
  final UserPreferences preferences;
  final StravaConnection? stravaConnection;
  final SubscriptionStatus subscriptionStatus;

  const AppUser({
    required this.id,
    this.email,
    this.displayName,
    this.avatarUrl,
    required this.authMode,
    required this.createdAt,
    this.lastSyncAt,
    required this.preferences,
    this.stravaConnection,
    required this.subscriptionStatus,
  });

  factory AppUser.local() {
    return AppUser(
      id: 'local_user',
      authMode: AuthMode.local,
      createdAt: DateTime.now(),
      preferences: UserPreferences.defaults(),
      subscriptionStatus: SubscriptionStatus.free,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);
  Map<String, dynamic> toJson() => _$AppUserToJson(this);

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    AuthMode? authMode,
    DateTime? createdAt,
    DateTime? lastSyncAt,
    UserPreferences? preferences,
    StravaConnection? stravaConnection,
    SubscriptionStatus? subscriptionStatus,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      authMode: authMode ?? this.authMode,
      createdAt: createdAt ?? this.createdAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      preferences: preferences ?? this.preferences,
      stravaConnection: stravaConnection ?? this.stravaConnection,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
    );
  }

  bool get isLocalOnly => authMode == AuthMode.local;
  bool get isAuthenticated => authMode == AuthMode.authenticated;
  bool get hasStravaConnected => stravaConnection != null && stravaConnection!.isValid;
  bool get isPremium => subscriptionStatus != SubscriptionStatus.free;

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        avatarUrl,
        authMode,
        createdAt,
        lastSyncAt,
        preferences,
        stravaConnection,
        subscriptionStatus,
      ];
}

/// User preferences stored locally
@JsonSerializable()
class UserPreferences extends Equatable {
  final PrivacyLevel privacyLevel;
  final bool darkMode;
  final OutputFormat defaultOutputFormat;
  final int defaultReelDuration;
  final int defaultStoryDuration;
  final bool autoDetectActivities;
  final bool enableNotifications;
  final bool enableAnalytics;
  final String? preferredMusicGenre;
  final bool showTutorialHints;

  const UserPreferences({
    required this.privacyLevel,
    required this.darkMode,
    required this.defaultOutputFormat,
    required this.defaultReelDuration,
    required this.defaultStoryDuration,
    required this.autoDetectActivities,
    required this.enableNotifications,
    required this.enableAnalytics,
    this.preferredMusicGenre,
    required this.showTutorialHints,
  });

  factory UserPreferences.defaults() {
    return const UserPreferences(
      privacyLevel: PrivacyLevel.standard,
      darkMode: true,
      defaultOutputFormat: OutputFormat.reel,
      defaultReelDuration: 30,
      defaultStoryDuration: 15,
      autoDetectActivities: true,
      enableNotifications: true,
      enableAnalytics: true,
      showTutorialHints: true,
    );
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      _$UserPreferencesFromJson(json);
  Map<String, dynamic> toJson() => _$UserPreferencesToJson(this);

  UserPreferences copyWith({
    PrivacyLevel? privacyLevel,
    bool? darkMode,
    OutputFormat? defaultOutputFormat,
    int? defaultReelDuration,
    int? defaultStoryDuration,
    bool? autoDetectActivities,
    bool? enableNotifications,
    bool? enableAnalytics,
    String? preferredMusicGenre,
    bool? showTutorialHints,
  }) {
    return UserPreferences(
      privacyLevel: privacyLevel ?? this.privacyLevel,
      darkMode: darkMode ?? this.darkMode,
      defaultOutputFormat: defaultOutputFormat ?? this.defaultOutputFormat,
      defaultReelDuration: defaultReelDuration ?? this.defaultReelDuration,
      defaultStoryDuration: defaultStoryDuration ?? this.defaultStoryDuration,
      autoDetectActivities: autoDetectActivities ?? this.autoDetectActivities,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableAnalytics: enableAnalytics ?? this.enableAnalytics,
      preferredMusicGenre: preferredMusicGenre ?? this.preferredMusicGenre,
      showTutorialHints: showTutorialHints ?? this.showTutorialHints,
    );
  }

  @override
  List<Object?> get props => [
        privacyLevel,
        darkMode,
        defaultOutputFormat,
        defaultReelDuration,
        defaultStoryDuration,
        autoDetectActivities,
        enableNotifications,
        enableAnalytics,
        preferredMusicGenre,
        showTutorialHints,
      ];
}

/// Strava connection details
@JsonSerializable()
class StravaConnection extends Equatable {
  final String athleteId;
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final String? athleteName;
  final String? athleteAvatar;

  const StravaConnection({
    required this.athleteId,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    this.athleteName,
    this.athleteAvatar,
  });

  factory StravaConnection.fromJson(Map<String, dynamic> json) =>
      _$StravaConnectionFromJson(json);
  Map<String, dynamic> toJson() => _$StravaConnectionToJson(this);

  bool get isValid => DateTime.now().isBefore(expiresAt);
  bool get needsRefresh => DateTime.now().isAfter(
        expiresAt.subtract(const Duration(minutes: 5)),
      );

  StravaConnection copyWith({
    String? athleteId,
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    String? athleteName,
    String? athleteAvatar,
  }) {
    return StravaConnection(
      athleteId: athleteId ?? this.athleteId,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      athleteName: athleteName ?? this.athleteName,
      athleteAvatar: athleteAvatar ?? this.athleteAvatar,
    );
  }

  @override
  List<Object?> get props => [
        athleteId,
        accessToken,
        refreshToken,
        expiresAt,
        athleteName,
        athleteAvatar,
      ];
}

/// Subscription status enum
enum SubscriptionStatus {
  free,
  trial,
  premium,
  premiumPlus,
  lifetime;

  bool get canAccessCloudSync => this != free;
  bool get canAccessAiNarration => this == premium || this == premiumPlus || this == lifetime;
  bool get canAccessAdvancedEditing => this != free && this != trial;
}
