import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/constants/app_constants.dart';

class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(userPreferencesProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Privacy Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Privacy level selector
          const Text(
            'Privacy Level',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose how much data Reframe collects to improve your experience',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),

          ...PrivacyLevel.values.map((level) {
            final isSelected = preferences.privacyLevel == level;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PrivacyLevelCard(
                level: level,
                isSelected: isSelected,
                onTap: () {
                  ref.read(userPreferencesProvider.notifier).updatePreferences(
                    (p) => p.copyWith(privacyLevel: level),
                  );
                  ref.read(analyticsProvider).trackPrivacyLevelChanged(level.name);
                },
              ),
            );
          }),

          const SizedBox(height: 24),

          // Individual settings
          const Text(
            'Data Collection',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          _SettingsToggle(
            icon: Icons.analytics,
            title: 'Usage Analytics',
            description: 'Help us improve Reframe by sharing anonymous usage data',
            value: preferences.enableAnalytics,
            onChanged: (value) {
              ref.read(userPreferencesProvider.notifier).updatePreferences(
                (p) => p.copyWith(enableAnalytics: value),
              );
              ref.read(analyticsProvider).setEnabled(value);
            },
          ),

          const Divider(height: 32, color: Colors.white12),

          _SettingsToggle(
            icon: Icons.notifications,
            title: 'Notifications',
            description: 'Receive updates about your activities and exports',
            value: preferences.enableNotifications,
            onChanged: (value) {
              ref.read(userPreferencesProvider.notifier).updatePreferences(
                (p) => p.copyWith(enableNotifications: value),
              );
            },
          ),

          const Divider(height: 32, color: Colors.white12),

          _SettingsToggle(
            icon: Icons.tips_and_updates,
            title: 'Tutorial Hints',
            description: 'Show helpful tips as you use the app',
            value: preferences.showTutorialHints,
            onChanged: (value) {
              ref.read(userPreferencesProvider.notifier).updatePreferences(
                (p) => p.copyWith(showTutorialHints: value),
              );
            },
          ),

          const SizedBox(height: 32),

          // Data management
          const Text(
            'Your Data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          _DataActionTile(
            icon: Icons.download,
            title: 'Export Your Data',
            description: 'Download a copy of your data',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data export coming soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          _DataActionTile(
            icon: Icons.delete_forever,
            title: 'Delete All Data',
            description: 'Permanently delete all your data from this device',
            isDestructive: true,
            onTap: () => _confirmDeleteAllData(context, ref),
          ),

          const SizedBox(height: 32),

          // Privacy policy
          Center(
            child: TextButton(
              onPressed: () {
                // Open privacy policy
              },
              child: const Text('View Privacy Policy'),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAllData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Delete All Data?'),
        content: const Text(
          'This will permanently delete all your activities, projects, and settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(localStorageProvider).clearAllData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All data deleted'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _PrivacyLevelCard extends StatelessWidget {
  final PrivacyLevel level;
  final bool isSelected;
  final VoidCallback onTap;

  const _PrivacyLevelCard({
    required this.level,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getIcon(),
              color: isSelected ? AppTheme.primaryColor : Colors.white54,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    level.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (level) {
      case PrivacyLevel.minimal:
        return Icons.lock;
      case PrivacyLevel.standard:
        return Icons.shield;
      case PrivacyLevel.maximum:
        return Icons.visibility;
    }
  }
}

class _SettingsToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggle({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryColor),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _DataActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isDestructive;
  final VoidCallback onTap;

  const _DataActionTile({
    required this.icon,
    required this.title,
    required this.description,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? AppTheme.error : AppTheme.primaryColor,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDestructive ? AppTheme.error : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDestructive ? AppTheme.error : Colors.white38,
            ),
          ],
        ),
      ),
    );
  }
}
