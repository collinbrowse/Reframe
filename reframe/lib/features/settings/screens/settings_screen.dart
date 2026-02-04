import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/constants/app_constants.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final preferences = ref.watch(userPreferencesProvider);
    final hasStrava = ref.watch(hasStravaConnectionProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // User profile card
                    user.when(
                      data: (u) => _buildProfileCard(context, u, ref),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),

            // Settings sections
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 16),

                  // Connected Services
                  _SectionHeader(title: 'Connected Services'),
                  _SettingsCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.directions_run,
                        iconColor: const Color(0xFFFC4C02),
                        title: 'Strava',
                        subtitle: hasStrava ? 'Connected' : 'Not connected',
                        trailing: hasStrava
                            ? const Icon(Icons.check_circle, color: AppTheme.success)
                            : const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => context.push(AppRoutes.stravaConnect),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Preferences
                  _SectionHeader(title: 'Preferences'),
                  _SettingsCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.dark_mode,
                        title: 'Dark Mode',
                        trailing: Switch(
                          value: preferences.darkMode,
                          onChanged: (value) {
                            ref.read(userPreferencesProvider.notifier).updatePreferences(
                              (p) => p.copyWith(darkMode: value),
                            );
                          },
                        ),
                      ),
                      const Divider(height: 1, color: Colors.white12),
                      _SettingsTile(
                        icon: Icons.video_settings,
                        title: 'Default Format',
                        subtitle: preferences.defaultOutputFormat.label,
                        onTap: () => _showFormatPicker(context, ref),
                      ),
                      const Divider(height: 1, color: Colors.white12),
                      _SettingsTile(
                        icon: Icons.auto_awesome,
                        title: 'Auto-detect Activities',
                        trailing: Switch(
                          value: preferences.autoDetectActivities,
                          onChanged: (value) {
                            ref.read(userPreferencesProvider.notifier).updatePreferences(
                              (p) => p.copyWith(autoDetectActivities: value),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Privacy & Data
                  _SectionHeader(title: 'Privacy & Data'),
                  _SettingsCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.shield,
                        title: 'Privacy Settings',
                        subtitle: preferences.privacyLevel.label,
                        onTap: () => context.push(AppRoutes.privacySettings),
                      ),
                      const Divider(height: 1, color: Colors.white12),
                      _SettingsTile(
                        icon: Icons.analytics,
                        title: 'Analytics',
                        trailing: Switch(
                          value: preferences.enableAnalytics,
                          onChanged: (value) {
                            ref.read(userPreferencesProvider.notifier).updatePreferences(
                              (p) => p.copyWith(enableAnalytics: value),
                            );
                            ref.read(analyticsProvider).setEnabled(value);
                          },
                        ),
                      ),
                      const Divider(height: 1, color: Colors.white12),
                      _SettingsTile(
                        icon: Icons.delete_outline,
                        title: 'Clear Cache',
                        subtitle: 'Free up storage space',
                        onTap: () => _clearCache(context, ref),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Subscription
                  _SectionHeader(title: 'Subscription'),
                  _SettingsCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.star,
                        iconColor: AppTheme.accentColor,
                        title: 'Upgrade to Premium',
                        subtitle: 'Unlock all features',
                        onTap: () => context.push(AppRoutes.subscription),
                      ),
                      const Divider(height: 1, color: Colors.white12),
                      _SettingsTile(
                        icon: Icons.receipt_long,
                        title: 'Restore Purchases',
                        onTap: () => _restorePurchases(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Support
                  _SectionHeader(title: 'Support'),
                  _SettingsCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.help_outline,
                        title: 'Help & FAQ',
                        onTap: () {},
                      ),
                      const Divider(height: 1, color: Colors.white12),
                      _SettingsTile(
                        icon: Icons.feedback_outlined,
                        title: 'Send Feedback',
                        onTap: () {},
                      ),
                      const Divider(height: 1, color: Colors.white12),
                      _SettingsTile(
                        icon: Icons.info_outline,
                        title: 'About',
                        subtitle: 'Version 1.0.0',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Sign out
                  if (user.value?.isAuthenticated ?? false)
                    _SettingsCard(
                      children: [
                        _SettingsTile(
                          icon: Icons.logout,
                          iconColor: AppTheme.error,
                          title: 'Sign Out',
                          titleColor: AppTheme.error,
                          onTap: () => _signOut(context, ref),
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, dynamic user, WidgetRef ref) {
    if (user == null) {
      return _SettingsCard(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.surfaceDark,
                  child: const Icon(Icons.person, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Local User',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Sign in to sync your data',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => context.push(AppRoutes.login),
                  child: const Text('Sign In'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return _SettingsCard(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                child: Text(
                  user.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? 'User',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (user.email != null)
                      Text(
                        user.email!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showFormatPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Default Output Format',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ...OutputFormat.values.map((format) {
              final isSelected = ref.read(userPreferencesProvider).defaultOutputFormat == format;
              return ListTile(
                leading: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? AppTheme.primaryColor : Colors.white38,
                ),
                title: Text(format.label),
                subtitle: Text(format.description),
                onTap: () {
                  ref.read(userPreferencesProvider.notifier).updatePreferences(
                    (p) => p.copyWith(defaultOutputFormat: format),
                  );
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _clearCache(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Clear Cache?'),
        content: const Text('This will remove cached media and temporary files.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Clear cache
      await ref.read(videoEditorProvider).cleanupTempFiles();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache cleared'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _restorePurchases(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Restoring purchases...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Sign Out?'),
        content: const Text('Your local data will be kept on this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(currentUserProvider.notifier).clearUser();
      context.go(AppRoutes.auth);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final Color? titleColor;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    this.iconColor,
    required this.title,
    this.titleColor,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppTheme.primaryColor),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            )
          : null,
      trailing: trailing ?? (onTap != null ? const Icon(Icons.arrow_forward_ios, size: 16) : null),
      onTap: onTap,
    );
  }
}
