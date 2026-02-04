import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/providers/app_providers.dart';

class SourcesScreen extends ConsumerWidget {
  const SourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasStrava = ref.watch(hasStravaConnectionProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Content Sources',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Sources list
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Connected sources section
                  const Text(
                    'CONNECTED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white54,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Camera Roll (always available)
                  _SourceCard(
                    icon: Icons.photo_library,
                    iconColor: AppTheme.primaryColor,
                    title: 'Camera Roll',
                    subtitle: 'Photos and videos from your device',
                    isConnected: true,
                    onTap: () {
                      // Open camera roll browser
                    },
                  ),
                  const SizedBox(height: 12),

                  // Strava
                  _SourceCard(
                    icon: Icons.directions_run,
                    iconColor: const Color(0xFFFC4C02),
                    title: 'Strava',
                    subtitle: hasStrava ? 'Connected' : 'Connect to sync activities',
                    isConnected: hasStrava,
                    onTap: () => context.push(AppRoutes.stravaConnect),
                  ),

                  const SizedBox(height: 32),

                  // Available sources section
                  const Text(
                    'COMING SOON',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white54,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Instagram
                  _SourceCard(
                    icon: Icons.camera_alt,
                    iconColor: const Color(0xFFE4405F),
                    title: 'Instagram',
                    subtitle: 'Import posts, stories, and reels',
                    isConnected: false,
                    isComingSoon: true,
                    onTap: () => _showComingSoon(context, 'Instagram'),
                  ),
                  const SizedBox(height: 12),

                  // TikTok
                  _SourceCard(
                    icon: Icons.music_note,
                    iconColor: Colors.white,
                    title: 'TikTok',
                    subtitle: 'Import your TikTok videos',
                    isConnected: false,
                    isComingSoon: true,
                    onTap: () => _showComingSoon(context, 'TikTok'),
                  ),
                  const SizedBox(height: 12),

                  // YouTube
                  _SourceCard(
                    icon: Icons.play_circle_fill,
                    iconColor: const Color(0xFFFF0000),
                    title: 'YouTube',
                    subtitle: 'Import your YouTube content',
                    isConnected: false,
                    isComingSoon: true,
                    onTap: () => _showComingSoon(context, 'YouTube'),
                  ),
                  const SizedBox(height: 12),

                  // GoPro
                  _SourceCard(
                    icon: Icons.videocam,
                    iconColor: const Color(0xFF00A7E1),
                    title: 'GoPro',
                    subtitle: 'Connect your GoPro cloud',
                    isConnected: false,
                    isComingSoon: true,
                    onTap: () => _showComingSoon(context, 'GoPro'),
                  ),

                  const SizedBox(height: 32),

                  // Manual import
                  const Text(
                    'MANUAL IMPORT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white54,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _SourceCard(
                    icon: Icons.file_upload,
                    iconColor: AppTheme.secondaryColor,
                    title: 'Import Files',
                    subtitle: 'Import from files or cloud storage',
                    isConnected: true,
                    onTap: () => _importFiles(context),
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

  void _showComingSoon(BuildContext context, String source) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('$source Coming Soon'),
        content: Text(
          '$source integration is in development. We\'ll notify you when it\'s ready!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Add to waitlist
            },
            child: const Text('Notify Me'),
          ),
        ],
      ),
    );
  }

  void _importFiles(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File picker coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isConnected;
  final bool isComingSoon;
  final VoidCallback onTap;

  const _SourceCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isConnected,
    this.isComingSoon = false,
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
          borderRadius: BorderRadius.circular(16),
          border: isComingSoon
              ? Border.all(color: Colors.white12)
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isComingSoon ? Colors.white54 : Colors.white,
                        ),
                      ),
                      if (isComingSoon) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Soon',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (isConnected && !isComingSoon)
              const Icon(Icons.check_circle, color: AppTheme.success)
            else
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isComingSoon ? Colors.white24 : Colors.white54,
              ),
          ],
        ),
      ),
    );
  }
}
