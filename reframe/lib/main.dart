import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'core/config/env_config.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.backgroundDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(
    const ProviderScope(
      child: ReframeApp(),
    ),
  );
}

class ReframeApp extends ConsumerStatefulWidget {
  const ReframeApp({super.key});

  @override
  ConsumerState<ReframeApp> createState() => _ReframeAppState();
}

class _ReframeAppState extends ConsumerState<ReframeApp> {
  late AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter();
  }

  @override
  Widget build(BuildContext context) {
    final appInitialized = ref.watch(appInitializedProvider);
    final userPrefs = ref.watch(userPreferencesProvider);
    
    return appInitialized.when(
      loading: () => const MaterialApp(
        home: _LoadingScreen(),
        debugShowCheckedModeBanner: false,
      ),
      error: (error, stack) => MaterialApp(
        home: _ErrorScreen(error: error.toString()),
        debugShowCheckedModeBanner: false,
      ),
      data: (_) {
        // Wrap with PostHog if configured
        Widget app = MaterialApp.router(
          title: 'Reframe',
          debugShowCheckedModeBanner: false,
          theme: userPrefs.darkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: userPrefs.darkMode ? ThemeMode.dark : ThemeMode.light,
          routerConfig: _appRouter.router,
        );
        
        if (EnvConfig.isPosthogConfigured) {
          app = PostHogWidget(
            child: app,
          );
        }
        
        return app;
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.video_camera_back_rounded,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Reframe',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Transform your activities',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String error;

  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.error,
              ),
              const SizedBox(height: 24),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                error,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // Restart app
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
