import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/activity.dart';
import '../../../models/project.dart';
import '../../../widgets/cards/activity_card.dart';
import '../../../widgets/cards/project_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).trackScreen('home');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final hasStrava = ref.watch(hasStravaConnectionProvider);
    final recentActivities = ref.watch(recentActivitiesProvider);
    final recentProjects = ref.watch(recentProjectsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              backgroundColor: AppTheme.backgroundDark,
              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.video_camera_back_rounded,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Reframe',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    // Show notifications
                  },
                ),
              ],
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Welcome message
                  user.when(
                    data: (u) => _buildWelcomeCard(u?.displayName),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),

                  // Connect Strava prompt if not connected
                  if (!hasStrava) ...[
                    _buildConnectStravaCard(),
                    const SizedBox(height: 24),
                  ],

                  // Quick actions
                  _buildQuickActions(),
                  const SizedBox(height: 24),

                  // Recent Activities
                  _buildSectionHeader(
                    'Recent Activities',
                    onViewAll: () => context.go(AppRoutes.activities),
                  ),
                  const SizedBox(height: 12),
                  if (recentActivities.isEmpty)
                    _buildEmptyActivities()
                  else
                    ...recentActivities.take(3).map(
                          (activity) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ActivityCard(
                              activity: activity,
                              onTap: () => context.push('/activities/${activity.id}'),
                            ),
                          ),
                        ),
                  const SizedBox(height: 24),

                  // Recent Projects
                  _buildSectionHeader(
                    'Your Projects',
                    onViewAll: () {
                      // Navigate to projects
                    },
                  ),
                  const SizedBox(height: 12),
                  if (recentProjects.isEmpty)
                    _buildEmptyProjects()
                  else
                    ...recentProjects.map(
                          (project) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ProjectCard(
                              project: project,
                              onTap: () => context.push('/editor/${project.id}'),
                            ),
                          ),
                        ),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.newProject),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('Create'),
      ),
    );
  }

  Widget _buildWelcomeCard(String? name) {
    final greeting = _getGreeting();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name ?? 'Athlete',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ready to transform your activities into content?',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectStravaCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFC4C02).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFFC4C02),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.directions_run,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Connect Strava',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sync your activities automatically',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push(AppRoutes.stravaConnect),
            icon: const Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.photo_library_outlined,
            label: 'From Photos',
            color: AppTheme.secondaryColor,
            onTap: () => context.push('${AppRoutes.newProject}?format=reel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.auto_awesome,
            label: 'AI Create',
            color: AppTheme.primaryColor,
            onTap: () => context.push(AppRoutes.newProject),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.folder_outlined,
            label: 'Import',
            color: AppTheme.accentColor,
            onTap: () => context.go(AppRoutes.sources),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: const Text('View All'),
          ),
      ],
    );
  }

  Widget _buildEmptyActivities() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.directions_run_outlined,
            size: 48,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          const Text(
            'No recent activities',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect Strava to sync your activities',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => context.push(AppRoutes.stravaConnect),
            child: const Text('Connect Strava'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyProjects() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.movie_creation_outlined,
            size: 48,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          const Text(
            'No projects yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first video from an activity',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.push(AppRoutes.newProject),
            icon: const Icon(Icons.add),
            label: const Text('Create Project'),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
