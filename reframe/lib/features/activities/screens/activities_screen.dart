import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/activity.dart';
import '../../../widgets/cards/activity_card.dart';

class ActivitiesScreen extends ConsumerStatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  ConsumerState<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends ConsumerState<ActivitiesScreen> {
  ActivityType? _filterType;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).trackScreen('activities');
  }

  Future<void> _refreshActivities() async {
    setState(() => _isRefreshing = true);
    try {
      await ref.read(activitiesProvider.notifier).syncFromStrava();
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(activitiesProvider);
    final hasStrava = ref.watch(hasStravaConnectionProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Activities',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  if (hasStrava)
                    IconButton(
                      icon: _isRefreshing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      onPressed: _isRefreshing ? null : _refreshActivities,
                    ),
                ],
              ),
            ),

            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: _filterType == null,
                    onTap: () => setState(() => _filterType = null),
                  ),
                  const SizedBox(width: 8),
                  ...ActivityType.values.take(6).map(
                        (type) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FilterChip(
                            label: type.label,
                            emoji: type.emoji,
                            isSelected: _filterType == type,
                            onTap: () => setState(() => _filterType = type),
                          ),
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Activities list
            Expanded(
              child: activitiesAsync.when(
                data: (activities) {
                  final filtered = _filterType == null
                      ? activities
                      : activities.where((a) => a.type == _filterType).toList();

                  if (filtered.isEmpty) {
                    return _buildEmptyState(hasStrava);
                  }

                  return RefreshIndicator(
                    onRefresh: _refreshActivities,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final activity = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ActivityCard(
                            activity: activity,
                            onTap: () => context.push('/activities/${activity.id}'),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppTheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load activities',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => ref.refresh(activitiesProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool hasStrava) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_run_outlined,
              size: 80,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 24),
            Text(
              _filterType != null
                  ? 'No ${_filterType!.label} activities'
                  : 'No activities yet',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasStrava
                  ? 'Pull down to sync from Strava'
                  : 'Connect Strava to import your activities',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (!hasStrava)
              ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.stravaConnect),
                icon: const Icon(Icons.link),
                label: const Text('Connect Strava'),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String? emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
