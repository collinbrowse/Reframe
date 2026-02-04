import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/activities/screens/activities_screen.dart';
import '../../features/activities/screens/activity_detail_screen.dart';
import '../../features/editor/screens/editor_screen.dart';
import '../../features/editor/screens/project_preview_screen.dart';
import '../../features/export/screens/export_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/privacy_settings_screen.dart';
import '../../features/sources/screens/sources_screen.dart';
import '../../features/sources/strava/screens/strava_connect_screen.dart';
import '../../features/monetization/screens/subscription_screen.dart';

/// App route paths
class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String login = '/login';
  static const String home = '/home';
  static const String activities = '/activities';
  static const String activityDetail = '/activities/:id';
  static const String sources = '/sources';
  static const String stravaConnect = '/sources/strava';
  static const String editor = '/editor/:projectId';
  static const String newProject = '/editor/new';
  static const String preview = '/preview/:projectId';
  static const String export = '/export/:projectId';
  static const String settings = '/settings';
  static const String privacySettings = '/settings/privacy';
  static const String subscription = '/subscription';
}

/// App router configuration
class AppRouter {
  final bool isOnboardingComplete;
  final bool isAuthenticated;

  AppRouter({
    this.isOnboardingComplete = false,
    this.isAuthenticated = false,
  });

  late final GoRouter router = GoRouter(
    initialLocation: _getInitialLocation(),
    debugLogDiagnostics: true,
    routes: [
      // Splash/Loading
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Onboarding
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Auth
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // Main App Shell
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const HomeScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: AppRoutes.activities,
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ActivitiesScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: AppRoutes.sources,
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const SourcesScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const SettingsScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
        ],
      ),

      // Activity Detail
      GoRoute(
        path: AppRoutes.activityDetail,
        builder: (context, state) {
          final activityId = state.pathParameters['id']!;
          return ActivityDetailScreen(activityId: activityId);
        },
      ),

      // Strava Connect
      GoRoute(
        path: AppRoutes.stravaConnect,
        builder: (context, state) => const StravaConnectScreen(),
      ),

      // Editor
      GoRoute(
        path: AppRoutes.newProject,
        builder: (context, state) {
          final activityId = state.uri.queryParameters['activityId'];
          final format = state.uri.queryParameters['format'];
          return EditorScreen(
            projectId: null,
            activityId: activityId,
            initialFormat: format,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.editor,
        builder: (context, state) {
          final projectId = state.pathParameters['projectId']!;
          return EditorScreen(projectId: projectId);
        },
      ),

      // Preview
      GoRoute(
        path: AppRoutes.preview,
        builder: (context, state) {
          final projectId = state.pathParameters['projectId']!;
          return ProjectPreviewScreen(projectId: projectId);
        },
      ),

      // Export
      GoRoute(
        path: AppRoutes.export,
        builder: (context, state) {
          final projectId = state.pathParameters['projectId']!;
          return ExportScreen(projectId: projectId);
        },
      ),

      // Privacy Settings
      GoRoute(
        path: AppRoutes.privacySettings,
        builder: (context, state) => const PrivacySettingsScreen(),
      ),

      // Subscription
      GoRoute(
        path: AppRoutes.subscription,
        builder: (context, state) => const SubscriptionScreen(),
      ),
    ],
    errorBuilder: (context, state) => ErrorScreen(error: state.error),
    redirect: (context, state) {
      // Redirect logic for auth guards
      return null;
    },
  );

  String _getInitialLocation() {
    if (!isOnboardingComplete) {
      return AppRoutes.onboarding;
    }
    return AppRoutes.home;
  }

  static Widget _fadeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }
}

/// Main shell with bottom navigation
class MainShell extends StatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onDestinationSelected(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_run_outlined),
            selectedIcon: Icon(Icons.directions_run),
            label: 'Activities',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Create',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/activities')) return 1;
    if (location.startsWith('/sources')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.activities);
        break;
      case 2:
        context.push(AppRoutes.newProject);
        break;
      case 3:
        context.go(AppRoutes.settings);
        break;
    }
  }
}

/// Splash screen
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_camera_back, size: 80),
            SizedBox(height: 24),
            Text(
              'Reframe',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

/// Error screen
class ErrorScreen extends StatelessWidget {
  final Exception? error;

  const ErrorScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
