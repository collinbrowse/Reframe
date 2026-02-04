import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/user.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              
              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.video_camera_back_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              
              const Text(
                'Welcome to Reframe',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how you want to use the app',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              
              const Spacer(),
              
              // Sign in with Apple
              _AuthButton(
                icon: Icons.apple,
                label: 'Continue with Apple',
                backgroundColor: Colors.white,
                textColor: Colors.black,
                onPressed: () => _signInWithApple(context, ref),
              ),
              const SizedBox(height: 12),
              
              // Sign in with Google
              _AuthButton(
                icon: Icons.g_mobiledata,
                label: 'Continue with Google',
                backgroundColor: Colors.white,
                textColor: Colors.black,
                onPressed: () => _signInWithGoogle(context, ref),
              ),
              const SizedBox(height: 12),
              
              // Sign in with Email
              _AuthButton(
                icon: Icons.email_outlined,
                label: 'Continue with Email',
                backgroundColor: AppTheme.surfaceDark,
                textColor: Colors.white,
                onPressed: () => context.push(AppRoutes.login),
              ),
              
              const SizedBox(height: 24),
              
              // Divider
              Row(
                children: [
                  Expanded(
                    child: Divider(color: Colors.white.withOpacity(0.2)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: Colors.white.withOpacity(0.2)),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Continue without account
              _AuthButton(
                icon: Icons.phone_android_rounded,
                label: 'Use Without Account',
                backgroundColor: Colors.transparent,
                textColor: AppTheme.primaryColor,
                borderColor: AppTheme.primaryColor,
                onPressed: () => _continueLocally(context, ref),
              ),
              
              const SizedBox(height: 16),
              
              // Privacy note
              Text(
                'Your data stays on your device unless you sign in',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithApple(BuildContext context, WidgetRef ref) async {
    // TODO: Implement Apple Sign In
    _showComingSoon(context, 'Apple Sign In');
  }

  Future<void> _signInWithGoogle(BuildContext context, WidgetRef ref) async {
    // TODO: Implement Google Sign In
    _showComingSoon(context, 'Google Sign In');
  }

  Future<void> _continueLocally(BuildContext context, WidgetRef ref) async {
    // Create local user
    await ref.read(currentUserProvider.notifier).createLocalUser();
    
    ref.read(analyticsProvider).trackLocalModeSelected();
    
    if (context.mounted) {
      context.go(AppRoutes.home);
    }
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback onPressed;

  const _AuthButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          side: BorderSide(
            color: borderColor ?? Colors.transparent,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
