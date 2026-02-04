import 'package:posthog_flutter/posthog_flutter.dart';
import '../../core/config/env_config.dart';
import '../../core/constants/app_constants.dart';
import '../../models/user.dart';

/// Analytics service using PostHog
class AnalyticsService {
  static AnalyticsService? _instance;
  bool _isInitialized = false;
  bool _isEnabled = true;

  AnalyticsService._();

  static AnalyticsService get instance {
    _instance ??= AnalyticsService._();
    return _instance!;
  }

  /// Initialize PostHog
  Future<void> init() async {
    if (_isInitialized) return;
    if (!EnvConfig.isPosthogConfigured) {
      _isEnabled = false;
      return;
    }

    // PostHog is initialized in main.dart via PostHogWidget
    _isInitialized = true;
  }

  /// Enable/disable analytics
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      Posthog().optOut();
    } else {
      Posthog().optIn();
    }
  }

  /// Identify user
  Future<void> identifyUser(AppUser user) async {
    if (!_isEnabled) return;

    await Posthog().identify(
      userId: user.id,
      userProperties: {
        'auth_mode': user.authMode.name,
        'subscription_status': user.subscriptionStatus.name,
        'has_strava': user.hasStravaConnected,
        'created_at': user.createdAt.toIso8601String(),
      },
    );
  }

  /// Reset user identity (logout)
  Future<void> resetUser() async {
    if (!_isEnabled) return;
    await Posthog().reset();
  }

  /// Track screen view
  Future<void> trackScreen(String screenName, {Map<String, dynamic>? properties}) async {
    if (!_isEnabled) return;
    
    await Posthog().screen(
      screenName: screenName,
      properties: properties,
    );
  }

  /// Track custom event
  Future<void> trackEvent(String eventName, {Map<String, dynamic>? properties}) async {
    if (!_isEnabled) return;

    await Posthog().capture(
      eventName: eventName,
      properties: properties,
    );
  }

  // ==================== App Events ====================

  Future<void> trackAppOpen() async {
    await trackEvent('app_opened');
  }

  Future<void> trackOnboardingStart() async {
    await trackEvent('onboarding_started');
  }

  Future<void> trackOnboardingComplete() async {
    await trackEvent('onboarding_completed');
  }

  Future<void> trackOnboardingStep(int step, String stepName) async {
    await trackEvent('onboarding_step', properties: {
      'step': step,
      'step_name': stepName,
    });
  }

  // ==================== Auth Events ====================

  Future<void> trackSignUp(String method) async {
    await trackEvent('user_signed_up', properties: {
      'method': method,
    });
  }

  Future<void> trackSignIn(String method) async {
    await trackEvent('user_signed_in', properties: {
      'method': method,
    });
  }

  Future<void> trackSignOut() async {
    await trackEvent('user_signed_out');
  }

  Future<void> trackLocalModeSelected() async {
    await trackEvent('local_mode_selected');
  }

  // ==================== Strava Events ====================

  Future<void> trackStravaConnected() async {
    await trackEvent('strava_connected');
  }

  Future<void> trackStravaDisconnected() async {
    await trackEvent('strava_disconnected');
  }

  Future<void> trackStravaSync({required int activityCount}) async {
    await trackEvent('strava_synced', properties: {
      'activity_count': activityCount,
    });
  }

  // ==================== Activity Events ====================

  Future<void> trackActivityViewed(String activityId, String activityType) async {
    await trackEvent('activity_viewed', properties: {
      'activity_id': activityId,
      'activity_type': activityType,
    });
  }

  Future<void> trackMediaMatched({
    required String activityId,
    required int mediaCount,
    required int photoCount,
    required int videoCount,
  }) async {
    await trackEvent('media_matched', properties: {
      'activity_id': activityId,
      'media_count': mediaCount,
      'photo_count': photoCount,
      'video_count': videoCount,
    });
  }

  // ==================== Project Events ====================

  Future<void> trackProjectCreated({
    required String projectId,
    required String outputFormat,
    String? activityId,
  }) async {
    await trackEvent('project_created', properties: {
      'project_id': projectId,
      'output_format': outputFormat,
      'has_activity': activityId != null,
    });
  }

  Future<void> trackProjectEdited(String projectId) async {
    await trackEvent('project_edited', properties: {
      'project_id': projectId,
    });
  }

  Future<void> trackClipAdded({
    required String projectId,
    required String mediaType,
  }) async {
    await trackEvent('clip_added', properties: {
      'project_id': projectId,
      'media_type': mediaType,
    });
  }

  Future<void> trackMusicAdded({
    required String projectId,
    required String source,
  }) async {
    await trackEvent('music_added', properties: {
      'project_id': projectId,
      'source': source,
    });
  }

  Future<void> trackAiPromptUsed({
    required String projectId,
    required String prompt,
  }) async {
    await trackEvent('ai_prompt_used', properties: {
      'project_id': projectId,
      'prompt_length': prompt.length,
    });
  }

  // ==================== Export Events ====================

  Future<void> trackExportStarted({
    required String projectId,
    required String format,
    required int clipCount,
    required int durationSeconds,
  }) async {
    await trackEvent('export_started', properties: {
      'project_id': projectId,
      'format': format,
      'clip_count': clipCount,
      'duration_seconds': durationSeconds,
    });
  }

  Future<void> trackExportCompleted({
    required String projectId,
    required int fileSizeBytes,
    required int processingTimeMs,
  }) async {
    await trackEvent('export_completed', properties: {
      'project_id': projectId,
      'file_size_bytes': fileSizeBytes,
      'processing_time_ms': processingTimeMs,
    });
  }

  Future<void> trackExportFailed({
    required String projectId,
    required String error,
  }) async {
    await trackEvent('export_failed', properties: {
      'project_id': projectId,
      'error': error,
    });
  }

  // ==================== Share Events ====================

  Future<void> trackShareInitiated({
    required String projectId,
    required String destination,
  }) async {
    await trackEvent('share_initiated', properties: {
      'project_id': projectId,
      'destination': destination,
    });
  }

  Future<void> trackShareCompleted({
    required String projectId,
    required String destination,
  }) async {
    await trackEvent('share_completed', properties: {
      'project_id': projectId,
      'destination': destination,
    });
  }

  // ==================== Monetization Events ====================

  Future<void> trackPaywallViewed(String source) async {
    await trackEvent('paywall_viewed', properties: {
      'source': source,
    });
  }

  Future<void> trackSubscriptionStarted({
    required String plan,
    required String price,
  }) async {
    await trackEvent('subscription_started', properties: {
      'plan': plan,
      'price': price,
    });
  }

  Future<void> trackSubscriptionCancelled(String plan) async {
    await trackEvent('subscription_cancelled', properties: {
      'plan': plan,
    });
  }

  Future<void> trackPurchaseCompleted({
    required String productId,
    required String price,
  }) async {
    await trackEvent('purchase_completed', properties: {
      'product_id': productId,
      'price': price,
    });
  }

  // ==================== Settings Events ====================

  Future<void> trackSettingsChanged({
    required String setting,
    required dynamic oldValue,
    required dynamic newValue,
  }) async {
    await trackEvent('settings_changed', properties: {
      'setting': setting,
      'old_value': oldValue.toString(),
      'new_value': newValue.toString(),
    });
  }

  Future<void> trackPrivacyLevelChanged(String level) async {
    await trackEvent('privacy_level_changed', properties: {
      'level': level,
    });
  }

  // ==================== Error Events ====================

  Future<void> trackError({
    required String errorType,
    required String message,
    String? stackTrace,
    Map<String, dynamic>? context,
  }) async {
    await trackEvent('error_occurred', properties: {
      'error_type': errorType,
      'message': message,
      if (stackTrace != null) 'stack_trace': stackTrace.substring(0, 500),
      ...?context,
    });
  }

  // ==================== Performance Events ====================

  Future<void> trackPerformance({
    required String operation,
    required int durationMs,
    Map<String, dynamic>? metadata,
  }) async {
    await trackEvent('performance_metric', properties: {
      'operation': operation,
      'duration_ms': durationMs,
      ...?metadata,
    });
  }
}
