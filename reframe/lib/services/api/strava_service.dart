import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/env_config.dart';
import '../../core/constants/app_constants.dart';
import '../../models/activity.dart';
import '../../models/user.dart';

/// Service for Strava API integration
class StravaService {
  final Dio _dio;
  StravaConnection? _connection;

  StravaService({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(
          baseUrl: AppConstants.stravaApiBaseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ));

  /// Set the current Strava connection
  void setConnection(StravaConnection? connection) {
    _connection = connection;
    if (connection != null) {
      _dio.options.headers['Authorization'] = 'Bearer ${connection.accessToken}';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  /// Check if configured
  bool get isConfigured => EnvConfig.isStravaConfigured;

  /// Get authorization URL for OAuth
  String getAuthorizationUrl() {
    final params = {
      'client_id': EnvConfig.stravaClientId,
      'redirect_uri': EnvConfig.stravaRedirectUri,
      'response_type': 'code',
      'approval_prompt': 'auto',
      'scope': AppConstants.stravaScopes.join(','),
    };
    
    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    return '${AppConstants.stravaAuthUrl}?$queryString';
  }

  /// Launch Strava authorization
  Future<bool> launchAuthorization() async {
    final url = Uri.parse(getAuthorizationUrl());
    if (await canLaunchUrl(url)) {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Exchange authorization code for tokens
  Future<StravaConnection> exchangeCodeForToken(String code) async {
    final response = await Dio().post(
      AppConstants.stravaTokenUrl,
      data: {
        'client_id': EnvConfig.stravaClientId,
        'client_secret': EnvConfig.stravaClientSecret,
        'code': code,
        'grant_type': 'authorization_code',
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    final data = response.data;
    final athlete = data['athlete'] as Map<String, dynamic>;
    
    return StravaConnection(
      athleteId: athlete['id'].toString(),
      accessToken: data['access_token'],
      refreshToken: data['refresh_token'],
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        (data['expires_at'] as int) * 1000,
      ),
      athleteName: '${athlete['firstname']} ${athlete['lastname']}'.trim(),
      athleteAvatar: athlete['profile_medium'],
    );
  }

  /// Refresh access token
  Future<StravaConnection> refreshToken(StravaConnection connection) async {
    final response = await Dio().post(
      AppConstants.stravaTokenUrl,
      data: {
        'client_id': EnvConfig.stravaClientId,
        'client_secret': EnvConfig.stravaClientSecret,
        'refresh_token': connection.refreshToken,
        'grant_type': 'refresh_token',
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    final data = response.data;
    
    final refreshed = connection.copyWith(
      accessToken: data['access_token'],
      refreshToken: data['refresh_token'],
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        (data['expires_at'] as int) * 1000,
      ),
    );
    
    setConnection(refreshed);
    return refreshed;
  }

  /// Ensure valid token (refresh if needed)
  Future<void> ensureValidToken() async {
    if (_connection == null) {
      throw StravaException('Not connected to Strava');
    }
    
    if (_connection!.needsRefresh) {
      final refreshed = await refreshToken(_connection!);
      _connection = refreshed;
    }
  }

  /// Get authenticated athlete
  Future<Map<String, dynamic>> getAthlete() async {
    await ensureValidToken();
    
    final response = await _dio.get('/athlete');
    return response.data;
  }

  /// Get activities with pagination
  Future<List<Activity>> getActivities({
    int page = 1,
    int perPage = 30,
    DateTime? before,
    DateTime? after,
  }) async {
    await ensureValidToken();
    
    final params = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    
    if (before != null) {
      params['before'] = before.millisecondsSinceEpoch ~/ 1000;
    }
    if (after != null) {
      params['after'] = after.millisecondsSinceEpoch ~/ 1000;
    }
    
    final response = await _dio.get(
      '/athlete/activities',
      queryParameters: params,
    );
    
    final activities = (response.data as List)
        .map((json) => Activity.fromStravaJson(json))
        .toList();
    
    return activities;
  }

  /// Get all activities (handles pagination)
  Future<List<Activity>> getAllActivities({
    DateTime? after,
    int maxActivities = 100,
  }) async {
    final allActivities = <Activity>[];
    int page = 1;
    const perPage = 30;
    
    while (allActivities.length < maxActivities) {
      final activities = await getActivities(
        page: page,
        perPage: perPage,
        after: after,
      );
      
      if (activities.isEmpty) break;
      
      allActivities.addAll(activities);
      
      if (activities.length < perPage) break;
      
      page++;
    }
    
    return allActivities.take(maxActivities).toList();
  }

  /// Get detailed activity
  Future<Activity> getActivity(String activityId) async {
    await ensureValidToken();
    
    final response = await _dio.get('/activities/$activityId');
    return Activity.fromStravaJson(response.data);
  }

  /// Get activity streams (GPS data, heart rate, etc.)
  Future<Map<String, dynamic>> getActivityStreams(
    String activityId, {
    List<String> keys = const [
      'time',
      'latlng',
      'altitude',
      'heartrate',
      'cadence',
      'velocity_smooth',
    ],
  }) async {
    await ensureValidToken();
    
    final response = await _dio.get(
      '/activities/$activityId/streams',
      queryParameters: {
        'keys': keys.join(','),
        'key_by_type': true,
      },
    );
    
    return response.data;
  }

  /// Get activity photos
  Future<List<Map<String, dynamic>>> getActivityPhotos(
    String activityId, {
    int size = 2048,
  }) async {
    await ensureValidToken();
    
    final response = await _dio.get(
      '/activities/$activityId/photos',
      queryParameters: {'size': size},
    );
    
    return List<Map<String, dynamic>>.from(response.data);
  }

  /// Get activity laps
  Future<List<Map<String, dynamic>>> getActivityLaps(String activityId) async {
    await ensureValidToken();
    
    final response = await _dio.get('/activities/$activityId/laps');
    return List<Map<String, dynamic>>.from(response.data);
  }

  /// Deauthorize (revoke access)
  Future<void> deauthorize() async {
    if (_connection == null) return;
    
    try {
      await Dio().post(
        'https://www.strava.com/oauth/deauthorize',
        data: {'access_token': _connection!.accessToken},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
    } finally {
      _connection = null;
      _dio.options.headers.remove('Authorization');
    }
  }

  /// Decode polyline to list of coordinates
  static List<LatLng> decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int b;
      
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      
      shift = 0;
      result = 0;
      
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      
      points.add(LatLng(
        latitude: lat / 1e5,
        longitude: lng / 1e5,
      ));
    }
    
    return points;
  }
}

/// Strava-specific exception
class StravaException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  StravaException(this.message, {this.statusCode, this.originalError});

  @override
  String toString() => 'StravaException: $message';
}
