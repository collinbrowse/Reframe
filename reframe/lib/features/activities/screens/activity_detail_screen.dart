import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/activity.dart';
import '../../../models/media.dart';

class ActivityDetailScreen extends ConsumerStatefulWidget {
  final String activityId;

  const ActivityDetailScreen({super.key, required this.activityId});

  @override
  ConsumerState<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends ConsumerState<ActivityDetailScreen> {
  List<MediaItem> _matchedMedia = [];
  bool _isLoadingMedia = true;

  @override
  void initState() {
    super.initState();
    _loadMatchedMedia();
  }

  Future<void> _loadMatchedMedia() async {
    final activity = ref.read(activitiesProvider.notifier).getActivity(widget.activityId);
    if (activity == null) return;

    final cameraRoll = ref.read(cameraRollServiceProvider);
    final matcher = ref.read(activityMatcherProvider);

    try {
      final media = await cameraRoll.getMediaForActivity(activity);
      final matched = await matcher.matchMediaToActivity(activity, media);
      
      if (mounted) {
        setState(() {
          _matchedMedia = matched;
          _isLoadingMedia = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMedia = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(activitiesProvider);
    
    return activitiesAsync.when(
      data: (activities) {
        final activity = activities.firstWhere(
          (a) => a.id == widget.activityId,
          orElse: () => throw Exception('Activity not found'),
        );
        return _buildContent(activity);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildContent(Activity activity) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: CustomScrollView(
        slivers: [
          // App Bar with activity hero
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppTheme.surfaceDark,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.8),
                      AppTheme.surfaceDark,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      Text(
                        activity.type.emoji,
                        style: const TextStyle(fontSize: 48),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        activity.type.label,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  // Share activity
                },
              ),
            ],
          ),

          // Activity details
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Title and date
                Text(
                  activity.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDate(activity.startDate),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 24),

                // Stats grid
                _buildStatsGrid(activity),
                const SizedBox(height: 24),

                // Description
                if (activity.description != null && activity.description!.isNotEmpty) ...[
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    activity.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Matched Media
                const Text(
                  'Matched Content',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Photos and videos from during this activity',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 16),
              ]),
            ),
          ),

          // Media grid
          if (_isLoadingMedia)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_matchedMedia.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: _buildEmptyMedia(),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildMediaThumbnail(_matchedMedia[index]),
                  childCount: _matchedMedia.length,
                ),
              ),
            ),

          // Create button
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _matchedMedia.isEmpty
                          ? null
                          : () => _createProject(activity),
                      icon: const Icon(Icons.movie_creation),
                      label: const Text('Create Content'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Activity activity) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.straighten,
                  label: 'Distance',
                  value: activity.formattedDistance,
                ),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.timer,
                  label: 'Duration',
                  value: activity.formattedDuration,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.speed,
                  label: 'Pace',
                  value: activity.formattedPace,
                ),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.terrain,
                  label: 'Elevation',
                  value: activity.totalElevationGain != null
                      ? '${activity.totalElevationGain!.toStringAsFixed(0)} m'
                      : 'N/A',
                ),
              ),
            ],
          ),
          if (activity.averageHeartrate != null || activity.calories != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (activity.averageHeartrate != null)
                  Expanded(
                    child: _StatItem(
                      icon: Icons.favorite,
                      label: 'Avg HR',
                      value: '${activity.averageHeartrate} bpm',
                    ),
                  ),
                if (activity.calories != null)
                  Expanded(
                    child: _StatItem(
                      icon: Icons.local_fire_department,
                      label: 'Calories',
                      value: '${activity.calories} kcal',
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyMedia() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 48,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'No media found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We couldn\'t find any photos or videos from this activity',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMediaThumbnail(MediaItem media) {
    return GestureDetector(
      onTap: () {
        // Preview media
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail placeholder
            Center(
              child: Icon(
                media.isVideo ? Icons.videocam : Icons.image,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            // Video duration badge
            if (media.isVideo && media.duration != null)
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    media.formattedDuration,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _createProject(Activity activity) {
    context.push(
      '${AppRoutes.newProject}?activityId=${activity.id}',
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
