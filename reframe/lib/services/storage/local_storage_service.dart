import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../models/user.dart';
import '../../models/activity.dart';
import '../../models/project.dart';

/// Service for managing local storage
class LocalStorageService {
  static const String _userBoxName = 'user_box';
  static const String _activitiesBoxName = 'activities_box';
  static const String _projectsBoxName = 'projects_box';
  static const String _settingsBoxName = 'settings_box';

  late Box<String> _userBox;
  late Box<String> _activitiesBox;
  late Box<String> _projectsBox;
  late Box<String> _settingsBox;
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late SharedPreferences _prefs;

  bool _isInitialized = false;

  /// Initialize the storage service
  Future<void> init() async {
    if (_isInitialized) return;

    await Hive.initFlutter();
    
    _userBox = await Hive.openBox<String>(_userBoxName);
    _activitiesBox = await Hive.openBox<String>(_activitiesBoxName);
    _projectsBox = await Hive.openBox<String>(_projectsBoxName);
    _settingsBox = await Hive.openBox<String>(_settingsBoxName);
    
    _prefs = await SharedPreferences.getInstance();
    
    _isInitialized = true;
  }

  // ==================== User Storage ====================

  /// Save user data
  Future<void> saveUser(AppUser user) async {
    await _userBox.put('current_user', jsonEncode(user.toJson()));
  }

  /// Get current user
  AppUser? getUser() {
    final data = _userBox.get('current_user');
    if (data == null) return null;
    return AppUser.fromJson(jsonDecode(data));
  }

  /// Delete user data
  Future<void> deleteUser() async {
    await _userBox.delete('current_user');
  }

  /// Save user preferences
  Future<void> savePreferences(UserPreferences preferences) async {
    await _settingsBox.put('user_preferences', jsonEncode(preferences.toJson()));
  }

  /// Get user preferences
  UserPreferences getPreferences() {
    final data = _settingsBox.get('user_preferences');
    if (data == null) return UserPreferences.defaults();
    return UserPreferences.fromJson(jsonDecode(data));
  }

  // ==================== Secure Storage ====================

  /// Save Strava connection securely
  Future<void> saveStravaConnection(StravaConnection connection) async {
    await _secureStorage.write(
      key: 'strava_connection',
      value: jsonEncode(connection.toJson()),
    );
  }

  /// Get Strava connection
  Future<StravaConnection?> getStravaConnection() async {
    final data = await _secureStorage.read(key: 'strava_connection');
    if (data == null) return null;
    return StravaConnection.fromJson(jsonDecode(data));
  }

  /// Delete Strava connection
  Future<void> deleteStravaConnection() async {
    await _secureStorage.delete(key: 'strava_connection');
  }

  /// Save auth token securely
  Future<void> saveAuthToken(String token) async {
    await _secureStorage.write(key: AppConstants.authTokenKey, value: token);
  }

  /// Get auth token
  Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: AppConstants.authTokenKey);
  }

  /// Delete auth token
  Future<void> deleteAuthToken() async {
    await _secureStorage.delete(key: AppConstants.authTokenKey);
  }

  // ==================== Activity Storage ====================

  /// Save activity
  Future<void> saveActivity(Activity activity) async {
    await _activitiesBox.put(activity.id, jsonEncode(activity.toJson()));
  }

  /// Save multiple activities
  Future<void> saveActivities(List<Activity> activities) async {
    final entries = {
      for (final activity in activities) 
        activity.id: jsonEncode(activity.toJson())
    };
    await _activitiesBox.putAll(entries);
  }

  /// Get activity by ID
  Activity? getActivity(String id) {
    final data = _activitiesBox.get(id);
    if (data == null) return null;
    return Activity.fromJson(jsonDecode(data));
  }

  /// Get all activities
  List<Activity> getAllActivities() {
    return _activitiesBox.values
        .map((data) => Activity.fromJson(jsonDecode(data)))
        .toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  /// Get activities within date range
  List<Activity> getActivitiesInRange(DateTime start, DateTime end) {
    return getAllActivities()
        .where((a) => a.startDate.isAfter(start) && a.startDate.isBefore(end))
        .toList();
  }

  /// Delete activity
  Future<void> deleteActivity(String id) async {
    await _activitiesBox.delete(id);
  }

  /// Clear all activities
  Future<void> clearActivities() async {
    await _activitiesBox.clear();
  }

  // ==================== Project Storage ====================

  /// Save project
  Future<void> saveProject(Project project) async {
    final updated = project.copyWith(modifiedAt: DateTime.now());
    await _projectsBox.put(project.id, jsonEncode(updated.toJson()));
  }

  /// Get project by ID
  Project? getProject(String id) {
    final data = _projectsBox.get(id);
    if (data == null) return null;
    return Project.fromJson(jsonDecode(data));
  }

  /// Get all projects
  List<Project> getAllProjects() {
    return _projectsBox.values
        .map((data) => Project.fromJson(jsonDecode(data)))
        .toList()
      ..sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
  }

  /// Get projects for activity
  List<Project> getProjectsForActivity(String activityId) {
    return getAllProjects()
        .where((p) => p.activityId == activityId)
        .toList();
  }

  /// Delete project
  Future<void> deleteProject(String id) async {
    await _projectsBox.delete(id);
  }

  // ==================== Settings Storage ====================

  /// Check if onboarding is complete
  bool get isOnboardingComplete {
    return _prefs.getBool(AppConstants.onboardingCompleteKey) ?? false;
  }

  /// Set onboarding complete
  Future<void> setOnboardingComplete(bool value) async {
    await _prefs.setBool(AppConstants.onboardingCompleteKey, value);
  }

  /// Get last sync time
  DateTime? getLastSyncTime(String key) {
    final timestamp = _prefs.getInt('last_sync_$key');
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Set last sync time
  Future<void> setLastSyncTime(String key, DateTime time) async {
    await _prefs.setInt('last_sync_$key', time.millisecondsSinceEpoch);
  }

  // ==================== Cache Management ====================

  /// Get total storage used (approximate)
  Future<int> getStorageUsed() async {
    int total = 0;
    total += _userBox.values.fold(0, (sum, v) => sum + v.length);
    total += _activitiesBox.values.fold(0, (sum, v) => sum + v.length);
    total += _projectsBox.values.fold(0, (sum, v) => sum + v.length);
    total += _settingsBox.values.fold(0, (sum, v) => sum + v.length);
    return total;
  }

  /// Clear all local data
  Future<void> clearAllData() async {
    await _userBox.clear();
    await _activitiesBox.clear();
    await _projectsBox.clear();
    await _settingsBox.clear();
    await _secureStorage.deleteAll();
    await _prefs.clear();
  }

  /// Close all boxes
  Future<void> close() async {
    await _userBox.close();
    await _activitiesBox.close();
    await _projectsBox.close();
    await _settingsBox.close();
  }
}
