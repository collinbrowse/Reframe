import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user.dart';
import '../../models/activity.dart';
import '../../models/project.dart';
import '../../services/storage/local_storage_service.dart';
import '../../services/api/strava_service.dart';
import '../../services/sources/camera_roll_service.dart';
import '../../services/ai/activity_matcher_service.dart';
import '../../services/video/video_editor_service.dart';
import '../../services/analytics/analytics_service.dart';

// ==================== Service Providers ====================

/// Local storage service provider
final localStorageProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

/// Strava service provider
final stravaServiceProvider = Provider<StravaService>((ref) {
  return StravaService();
});

/// Camera roll service provider
final cameraRollServiceProvider = Provider<CameraRollService>((ref) {
  return CameraRollService();
});

/// Activity matcher service provider
final activityMatcherProvider = Provider<ActivityMatcherService>((ref) {
  return ActivityMatcherService();
});

/// Video editor service provider
final videoEditorProvider = Provider<VideoEditorService>((ref) {
  return VideoEditorService();
});

/// Analytics service provider
final analyticsProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService.instance;
});

// ==================== State Providers ====================

/// Current user state
final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, AsyncValue<AppUser?>>((ref) {
  final storage = ref.watch(localStorageProvider);
  return CurrentUserNotifier(storage);
});

class CurrentUserNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  final LocalStorageService _storage;

  CurrentUserNotifier(this._storage) : super(const AsyncValue.loading()) {
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      await _storage.init();
      final user = _storage.getUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setUser(AppUser user) async {
    await _storage.saveUser(user);
    state = AsyncValue.data(user);
  }

  Future<void> updateUser(AppUser Function(AppUser) update) async {
    final current = state.value;
    if (current != null) {
      final updated = update(current);
      await _storage.saveUser(updated);
      state = AsyncValue.data(updated);
    }
  }

  Future<void> clearUser() async {
    await _storage.deleteUser();
    state = const AsyncValue.data(null);
  }

  Future<void> createLocalUser() async {
    final user = AppUser.local();
    await setUser(user);
  }
}

/// User preferences state
final userPreferencesProvider = StateNotifierProvider<UserPreferencesNotifier, UserPreferences>((ref) {
  final storage = ref.watch(localStorageProvider);
  return UserPreferencesNotifier(storage);
});

class UserPreferencesNotifier extends StateNotifier<UserPreferences> {
  final LocalStorageService _storage;

  UserPreferencesNotifier(this._storage) : super(UserPreferences.defaults()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      await _storage.init();
      state = _storage.getPreferences();
    } catch (e) {
      state = UserPreferences.defaults();
    }
  }

  Future<void> updatePreferences(UserPreferences Function(UserPreferences) update) async {
    final updated = update(state);
    await _storage.savePreferences(updated);
    state = updated;
  }
}

/// Strava connection state
final stravaConnectionProvider = StateNotifierProvider<StravaConnectionNotifier, AsyncValue<StravaConnection?>>((ref) {
  final storage = ref.watch(localStorageProvider);
  final stravaService = ref.watch(stravaServiceProvider);
  return StravaConnectionNotifier(storage, stravaService);
});

class StravaConnectionNotifier extends StateNotifier<AsyncValue<StravaConnection?>> {
  final LocalStorageService _storage;
  final StravaService _stravaService;

  StravaConnectionNotifier(this._storage, this._stravaService) : super(const AsyncValue.loading()) {
    _loadConnection();
  }

  Future<void> _loadConnection() async {
    try {
      await _storage.init();
      final connection = await _storage.getStravaConnection();
      if (connection != null) {
        _stravaService.setConnection(connection);
      }
      state = AsyncValue.data(connection);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> connect(String authCode) async {
    state = const AsyncValue.loading();
    try {
      final connection = await _stravaService.exchangeCodeForToken(authCode);
      await _storage.saveStravaConnection(connection);
      _stravaService.setConnection(connection);
      state = AsyncValue.data(connection);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> disconnect() async {
    try {
      await _stravaService.deauthorize();
    } finally {
      await _storage.deleteStravaConnection();
      _stravaService.setConnection(null);
      state = const AsyncValue.data(null);
    }
  }

  Future<void> refreshIfNeeded() async {
    final connection = state.value;
    if (connection != null && connection.needsRefresh) {
      try {
        final refreshed = await _stravaService.refreshToken(connection);
        await _storage.saveStravaConnection(refreshed);
        state = AsyncValue.data(refreshed);
      } catch (e, st) {
        state = AsyncValue.error(e, st);
      }
    }
  }
}

/// Activities list state
final activitiesProvider = StateNotifierProvider<ActivitiesNotifier, AsyncValue<List<Activity>>>((ref) {
  final storage = ref.watch(localStorageProvider);
  final stravaService = ref.watch(stravaServiceProvider);
  final stravaConnection = ref.watch(stravaConnectionProvider);
  return ActivitiesNotifier(storage, stravaService, stravaConnection);
});

class ActivitiesNotifier extends StateNotifier<AsyncValue<List<Activity>>> {
  final LocalStorageService _storage;
  final StravaService _stravaService;
  final AsyncValue<StravaConnection?> _stravaConnection;

  ActivitiesNotifier(this._storage, this._stravaService, this._stravaConnection) 
      : super(const AsyncValue.loading()) {
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    try {
      await _storage.init();
      final activities = _storage.getAllActivities();
      state = AsyncValue.data(activities);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> syncFromStrava() async {
    final connection = _stravaConnection.value;
    if (connection == null) return;

    state = const AsyncValue.loading();
    try {
      final lastSync = _storage.getLastSyncTime('strava_activities');
      final activities = await _stravaService.getAllActivities(
        after: lastSync,
        maxActivities: 50,
      );
      
      await _storage.saveActivities(activities);
      await _storage.setLastSyncTime('strava_activities', DateTime.now());
      
      final allActivities = _storage.getAllActivities();
      state = AsyncValue.data(allActivities);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await _loadActivities();
  }

  Activity? getActivity(String id) {
    return state.value?.firstWhere((a) => a.id == id);
  }
}

/// Projects list state
final projectsProvider = StateNotifierProvider<ProjectsNotifier, AsyncValue<List<Project>>>((ref) {
  final storage = ref.watch(localStorageProvider);
  return ProjectsNotifier(storage);
});

class ProjectsNotifier extends StateNotifier<AsyncValue<List<Project>>> {
  final LocalStorageService _storage;

  ProjectsNotifier(this._storage) : super(const AsyncValue.loading()) {
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      await _storage.init();
      final projects = _storage.getAllProjects();
      state = AsyncValue.data(projects);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Project> createProject(Project project) async {
    await _storage.saveProject(project);
    await _loadProjects();
    return project;
  }

  Future<void> updateProject(Project project) async {
    await _storage.saveProject(project);
    await _loadProjects();
  }

  Future<void> deleteProject(String id) async {
    await _storage.deleteProject(id);
    await _loadProjects();
  }

  Project? getProject(String id) {
    return state.value?.firstWhere((p) => p.id == id);
  }
}

/// Current project being edited
final currentProjectProvider = StateProvider<Project?>((ref) => null);

/// App initialization state
final appInitializedProvider = FutureProvider<bool>((ref) async {
  final storage = ref.watch(localStorageProvider);
  await storage.init();
  
  final analytics = ref.watch(analyticsProvider);
  await analytics.init();
  
  return true;
});

/// Onboarding complete state
final onboardingCompleteProvider = Provider<bool>((ref) {
  final storage = ref.watch(localStorageProvider);
  return storage.isOnboardingComplete;
});

// ==================== Computed Providers ====================

/// Check if user has Strava connected
final hasStravaConnectionProvider = Provider<bool>((ref) {
  final connection = ref.watch(stravaConnectionProvider);
  return connection.value != null;
});

/// Check if user is premium
final isPremiumProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user.value?.isPremium ?? false;
});

/// Recent activities (last 7 days)
final recentActivitiesProvider = Provider<List<Activity>>((ref) {
  final activities = ref.watch(activitiesProvider);
  final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
  
  return activities.value
      ?.where((a) => a.startDate.isAfter(sevenDaysAgo))
      .toList() ?? [];
});

/// Recent projects (last 5)
final recentProjectsProvider = Provider<List<Project>>((ref) {
  final projects = ref.watch(projectsProvider);
  return projects.value?.take(5).toList() ?? [];
});
