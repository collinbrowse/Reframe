import 'dart:math';
import '../../core/constants/app_constants.dart';
import '../../models/activity.dart';
import '../../models/media.dart';

/// Service for matching media to activities using timestamp and AI analysis
class ActivityMatcherService {
  /// Default time buffer for matching (minutes before/after activity)
  static const int defaultBufferMinutes = 30;

  /// Match media items to an activity
  Future<List<MediaItem>> matchMediaToActivity(
    Activity activity,
    List<MediaItem> availableMedia, {
    int bufferMinutes = defaultBufferMinutes,
    bool useAiAnalysis = true,
  }) async {
    final matchedMedia = <MediaItem>[];
    final window = activity.getMatchingWindow(bufferMinutes: bufferMinutes);

    for (final media in availableMedia) {
      // Primary match: timestamp
      if (_isWithinTimeWindow(media.createdAt, window)) {
        matchedMedia.add(media.copyWith(activityId: activity.id));
        continue;
      }

      // Secondary match: location (if available)
      if (_isNearActivityLocation(media, activity)) {
        matchedMedia.add(media.copyWith(activityId: activity.id));
        continue;
      }

      // AI-based match: content analysis
      if (useAiAnalysis && await _matchesByContent(media, activity)) {
        matchedMedia.add(media.copyWith(activityId: activity.id));
      }
    }

    // Sort by creation time
    matchedMedia.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return matchedMedia;
  }

  /// Match all activities to available media
  Future<Map<String, List<MediaItem>>> matchAllActivities(
    List<Activity> activities,
    List<MediaItem> availableMedia, {
    int bufferMinutes = defaultBufferMinutes,
  }) async {
    final matches = <String, List<MediaItem>>{};

    for (final activity in activities) {
      final matched = await matchMediaToActivity(
        activity,
        availableMedia,
        bufferMinutes: bufferMinutes,
      );
      matches[activity.id] = matched;
    }

    return matches;
  }

  /// Find unmatched media (not associated with any activity)
  Future<List<MediaItem>> findUnmatchedMedia(
    List<Activity> activities,
    List<MediaItem> allMedia, {
    int bufferMinutes = defaultBufferMinutes,
  }) async {
    final matchedIds = <String>{};

    for (final activity in activities) {
      final matched = await matchMediaToActivity(
        activity,
        allMedia,
        bufferMinutes: bufferMinutes,
      );
      matchedIds.addAll(matched.map((m) => m.id));
    }

    return allMedia.where((m) => !matchedIds.contains(m.id)).toList();
  }

  /// Calculate match confidence score (0-1)
  Future<double> calculateMatchConfidence(
    MediaItem media,
    Activity activity,
  ) async {
    double score = 0;
    int factors = 0;

    // Time proximity score (max 0.5)
    final timeScore = _calculateTimeProximityScore(media.createdAt, activity);
    if (timeScore > 0) {
      score += timeScore * 0.5;
      factors++;
    }

    // Location score (max 0.3)
    if (media.hasLocation && activity.route != null && activity.route!.isNotEmpty) {
      final locationScore = _calculateLocationScore(media, activity);
      score += locationScore * 0.3;
      factors++;
    }

    // Content relevance score (max 0.2)
    final contentScore = await _calculateContentRelevanceScore(media, activity);
    score += contentScore * 0.2;
    factors++;

    return factors > 0 ? score / factors * factors : 0;
  }

  /// Check if media is within the activity time window
  bool _isWithinTimeWindow(DateTime mediaTime, DateTimeRange window) {
    return window.contains(mediaTime);
  }

  /// Check if media location is near the activity route
  bool _isNearActivityLocation(MediaItem media, Activity activity) {
    if (!media.hasLocation) return false;
    if (activity.route == null || activity.route!.isEmpty) return false;

    final mediaLat = media.metadata!.latitude!;
    final mediaLng = media.metadata!.longitude!;

    // Check if media is within radius of any point on the route
    for (final point in activity.route!) {
      final distance = _calculateDistance(
        mediaLat,
        mediaLng,
        point.latitude,
        point.longitude,
      );
      if (distance <= AppConstants.locationMatchRadius) {
        return true;
      }
    }

    return false;
  }

  /// AI-based content matching (simplified on-device version)
  Future<bool> _matchesByContent(MediaItem media, Activity activity) async {
    // Check if media has AI labels that match the activity type
    if (media.aiLabels == null || media.aiLabels!.isEmpty) {
      return false;
    }

    final activityKeywords = _getActivityKeywords(activity.type);
    
    for (final label in media.aiLabels!) {
      final normalizedLabel = label.toLowerCase();
      for (final keyword in activityKeywords) {
        if (normalizedLabel.contains(keyword)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Calculate time proximity score
  double _calculateTimeProximityScore(DateTime mediaTime, Activity activity) {
    final activityMid = activity.startDate.add(
      Duration(milliseconds: activity.elapsedTime.inMilliseconds ~/ 2),
    );
    
    final diff = mediaTime.difference(activityMid).abs();
    final activityHalfDuration = activity.elapsedTime.inMinutes / 2;
    final bufferMinutes = AppConstants.activityBufferMinutes.toDouble();
    
    final maxDiff = activityHalfDuration + bufferMinutes;
    
    if (diff.inMinutes > maxDiff) return 0;
    
    // Linear decay from 1.0 at center to 0 at edge
    return 1 - (diff.inMinutes / maxDiff);
  }

  /// Calculate location match score
  double _calculateLocationScore(MediaItem media, Activity activity) {
    if (!media.hasLocation || activity.route == null) return 0;

    final mediaLat = media.metadata!.latitude!;
    final mediaLng = media.metadata!.longitude!;

    double minDistance = double.infinity;
    for (final point in activity.route!) {
      final distance = _calculateDistance(
        mediaLat,
        mediaLng,
        point.latitude,
        point.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    // Score based on distance (closer = higher score)
    if (minDistance <= 50) return 1.0;
    if (minDistance <= 100) return 0.9;
    if (minDistance <= 250) return 0.7;
    if (minDistance <= 500) return 0.5;
    if (minDistance <= 1000) return 0.3;
    return 0;
  }

  /// Calculate content relevance score
  Future<double> _calculateContentRelevanceScore(
    MediaItem media,
    Activity activity,
  ) async {
    if (media.aiLabels == null || media.aiLabels!.isEmpty) {
      return 0.5; // Neutral score when no labels
    }

    final activityKeywords = _getActivityKeywords(activity.type);
    int matchCount = 0;

    for (final label in media.aiLabels!) {
      final normalizedLabel = label.toLowerCase();
      for (final keyword in activityKeywords) {
        if (normalizedLabel.contains(keyword)) {
          matchCount++;
        }
      }
    }

    if (matchCount == 0) return 0.3;
    if (matchCount == 1) return 0.6;
    if (matchCount == 2) return 0.8;
    return 1.0;
  }

  /// Get keywords associated with activity type
  List<String> _getActivityKeywords(ActivityType type) {
    switch (type) {
      case ActivityType.run:
        return ['running', 'runner', 'jogging', 'trail', 'road', 'track', 'marathon', 'shoes'];
      case ActivityType.ride:
        return ['cycling', 'bicycle', 'bike', 'cyclist', 'road', 'wheel', 'helmet'];
      case ActivityType.swim:
        return ['swimming', 'pool', 'water', 'ocean', 'lake', 'swimmer', 'goggles'];
      case ActivityType.hike:
        return ['hiking', 'mountain', 'trail', 'nature', 'forest', 'peak', 'backpack'];
      case ActivityType.walk:
        return ['walking', 'path', 'park', 'street', 'urban'];
      case ActivityType.alpineSki:
      case ActivityType.backcountrySki:
        return ['skiing', 'snow', 'mountain', 'ski', 'slope', 'powder', 'lift'];
      case ActivityType.workout:
      case ActivityType.weightTraining:
      case ActivityType.crossfit:
        return ['gym', 'fitness', 'workout', 'weights', 'exercise', 'training'];
      case ActivityType.yoga:
        return ['yoga', 'mat', 'pose', 'stretch', 'meditation', 'wellness'];
      case ActivityType.rockClimbing:
        return ['climbing', 'rock', 'cliff', 'boulder', 'wall', 'rope'];
      case ActivityType.surfing:
        return ['surfing', 'wave', 'beach', 'ocean', 'board', 'surf'];
      case ActivityType.kayaking:
      case ActivityType.rowing:
        return ['kayak', 'rowing', 'paddle', 'boat', 'water', 'river', 'lake'];
      case ActivityType.golf:
        return ['golf', 'course', 'club', 'green', 'fairway', 'tee'];
      default:
        return ['sport', 'outdoor', 'activity', 'exercise'];
    }
  }

  /// Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000.0; // meters
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * pi / 180;
}

/// Result of activity matching
class ActivityMatchResult {
  final Activity activity;
  final List<MediaItem> matchedMedia;
  final Map<String, double> confidenceScores;

  const ActivityMatchResult({
    required this.activity,
    required this.matchedMedia,
    required this.confidenceScores,
  });

  double get averageConfidence {
    if (confidenceScores.isEmpty) return 0;
    return confidenceScores.values.reduce((a, b) => a + b) / confidenceScores.length;
  }

  List<MediaItem> get highConfidenceMedia {
    return matchedMedia
        .where((m) => (confidenceScores[m.id] ?? 0) >= 0.7)
        .toList();
  }
}
