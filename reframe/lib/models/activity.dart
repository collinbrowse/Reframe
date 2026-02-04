import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import '../core/constants/app_constants.dart';

part 'activity.g.dart';

/// Activity model representing a Strava activity
@JsonSerializable()
class Activity extends Equatable {
  final String id;
  final String name;
  final ActivityType type;
  final DateTime startDate;
  final DateTime endDate;
  final Duration elapsedTime;
  final Duration? movingTime;
  final double? distance; // in meters
  final double? totalElevationGain; // in meters
  final double? averageSpeed; // m/s
  final double? maxSpeed; // m/s
  final int? averageHeartrate;
  final int? maxHeartrate;
  final double? averageCadence;
  final int? calories;
  final String? description;
  final List<LatLng>? route;
  final String? mapPolyline;
  final String? thumbnailUrl;
  final bool isPrivate;
  final List<String> matchedMediaIds;
  final DateTime? lastSyncedAt;

  const Activity({
    required this.id,
    required this.name,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.elapsedTime,
    this.movingTime,
    this.distance,
    this.totalElevationGain,
    this.averageSpeed,
    this.maxSpeed,
    this.averageHeartrate,
    this.maxHeartrate,
    this.averageCadence,
    this.calories,
    this.description,
    this.route,
    this.mapPolyline,
    this.thumbnailUrl,
    this.isPrivate = false,
    this.matchedMediaIds = const [],
    this.lastSyncedAt,
  });

  factory Activity.fromJson(Map<String, dynamic> json) => _$ActivityFromJson(json);
  Map<String, dynamic> toJson() => _$ActivityToJson(this);

  /// Create Activity from Strava API response
  factory Activity.fromStravaJson(Map<String, dynamic> json) {
    final startDate = DateTime.parse(json['start_date'] as String);
    final elapsedSeconds = json['elapsed_time'] as int;
    
    return Activity(
      id: json['id'].toString(),
      name: json['name'] as String,
      type: ActivityType.fromString(json['type'] as String),
      startDate: startDate,
      endDate: startDate.add(Duration(seconds: elapsedSeconds)),
      elapsedTime: Duration(seconds: elapsedSeconds),
      movingTime: json['moving_time'] != null 
          ? Duration(seconds: json['moving_time'] as int)
          : null,
      distance: (json['distance'] as num?)?.toDouble(),
      totalElevationGain: (json['total_elevation_gain'] as num?)?.toDouble(),
      averageSpeed: (json['average_speed'] as num?)?.toDouble(),
      maxSpeed: (json['max_speed'] as num?)?.toDouble(),
      averageHeartrate: (json['average_heartrate'] as num?)?.toInt(),
      maxHeartrate: (json['max_heartrate'] as num?)?.toInt(),
      averageCadence: (json['average_cadence'] as num?)?.toDouble(),
      calories: json['calories'] as int?,
      description: json['description'] as String?,
      mapPolyline: json['map']?['summary_polyline'] as String?,
      isPrivate: json['private'] as bool? ?? false,
    );
  }

  Activity copyWith({
    String? id,
    String? name,
    ActivityType? type,
    DateTime? startDate,
    DateTime? endDate,
    Duration? elapsedTime,
    Duration? movingTime,
    double? distance,
    double? totalElevationGain,
    double? averageSpeed,
    double? maxSpeed,
    int? averageHeartrate,
    int? maxHeartrate,
    double? averageCadence,
    int? calories,
    String? description,
    List<LatLng>? route,
    String? mapPolyline,
    String? thumbnailUrl,
    bool? isPrivate,
    List<String>? matchedMediaIds,
    DateTime? lastSyncedAt,
  }) {
    return Activity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      movingTime: movingTime ?? this.movingTime,
      distance: distance ?? this.distance,
      totalElevationGain: totalElevationGain ?? this.totalElevationGain,
      averageSpeed: averageSpeed ?? this.averageSpeed,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      averageHeartrate: averageHeartrate ?? this.averageHeartrate,
      maxHeartrate: maxHeartrate ?? this.maxHeartrate,
      averageCadence: averageCadence ?? this.averageCadence,
      calories: calories ?? this.calories,
      description: description ?? this.description,
      route: route ?? this.route,
      mapPolyline: mapPolyline ?? this.mapPolyline,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isPrivate: isPrivate ?? this.isPrivate,
      matchedMediaIds: matchedMediaIds ?? this.matchedMediaIds,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  /// Get formatted distance string
  String get formattedDistance {
    if (distance == null) return 'N/A';
    if (distance! >= 1000) {
      return '${(distance! / 1000).toStringAsFixed(2)} km';
    }
    return '${distance!.toStringAsFixed(0)} m';
  }

  /// Get formatted duration string
  String get formattedDuration {
    final hours = elapsedTime.inHours;
    final minutes = elapsedTime.inMinutes % 60;
    final seconds = elapsedTime.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  /// Get formatted pace (for running activities)
  String get formattedPace {
    if (distance == null || distance == 0) return 'N/A';
    final paceSecondsPerKm = (elapsedTime.inSeconds / (distance! / 1000));
    final paceMinutes = (paceSecondsPerKm / 60).floor();
    final paceSeconds = (paceSecondsPerKm % 60).floor();
    return '$paceMinutes:${paceSeconds.toString().padLeft(2, '0')} /km';
  }

  /// Get time window for media matching (with buffer)
  DateTimeRange getMatchingWindow({int bufferMinutes = 30}) {
    return DateTimeRange(
      start: startDate.subtract(Duration(minutes: bufferMinutes)),
      end: endDate.add(Duration(minutes: bufferMinutes)),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        startDate,
        endDate,
        elapsedTime,
        movingTime,
        distance,
        totalElevationGain,
        averageSpeed,
        maxSpeed,
        averageHeartrate,
        maxHeartrate,
        averageCadence,
        calories,
        description,
        route,
        mapPolyline,
        thumbnailUrl,
        isPrivate,
        matchedMediaIds,
        lastSyncedAt,
      ];
}

/// Date time range helper
class DateTimeRange {
  final DateTime start;
  final DateTime end;

  const DateTimeRange({required this.start, required this.end});

  bool contains(DateTime date) {
    return date.isAfter(start) && date.isBefore(end);
  }

  Duration get duration => end.difference(start);
}

/// Latitude/Longitude point
@JsonSerializable()
class LatLng extends Equatable {
  final double latitude;
  final double longitude;

  const LatLng({required this.latitude, required this.longitude});

  factory LatLng.fromJson(Map<String, dynamic> json) => _$LatLngFromJson(json);
  Map<String, dynamic> toJson() => _$LatLngToJson(this);

  factory LatLng.fromList(List<num> coords) {
    return LatLng(
      latitude: coords[0].toDouble(),
      longitude: coords[1].toDouble(),
    );
  }

  @override
  List<Object> get props => [latitude, longitude];
}

/// Activity summary for list display
@JsonSerializable()
class ActivitySummary extends Equatable {
  final String id;
  final String name;
  final ActivityType type;
  final DateTime startDate;
  final Duration elapsedTime;
  final double? distance;
  final int matchedMediaCount;
  final String? thumbnailUrl;

  const ActivitySummary({
    required this.id,
    required this.name,
    required this.type,
    required this.startDate,
    required this.elapsedTime,
    this.distance,
    this.matchedMediaCount = 0,
    this.thumbnailUrl,
  });

  factory ActivitySummary.fromActivity(Activity activity) {
    return ActivitySummary(
      id: activity.id,
      name: activity.name,
      type: activity.type,
      startDate: activity.startDate,
      elapsedTime: activity.elapsedTime,
      distance: activity.distance,
      matchedMediaCount: activity.matchedMediaIds.length,
      thumbnailUrl: activity.thumbnailUrl,
    );
  }

  factory ActivitySummary.fromJson(Map<String, dynamic> json) =>
      _$ActivitySummaryFromJson(json);
  Map<String, dynamic> toJson() => _$ActivitySummaryToJson(this);

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        startDate,
        elapsedTime,
        distance,
        matchedMediaCount,
        thumbnailUrl,
      ];
}
