import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/activity.dart';

class ActivityCard extends StatelessWidget {
  final Activity activity;
  final VoidCallback? onTap;

  const ActivityCard({
    super.key,
    required this.activity,
    this.onTap,
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
        ),
        child: Row(
          children: [
            // Activity type icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  activity.type.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Activity info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(activity.startDate),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Stats row
                  Row(
                    children: [
                      _StatBadge(
                        icon: Icons.straighten,
                        value: activity.formattedDistance,
                      ),
                      const SizedBox(width: 12),
                      _StatBadge(
                        icon: Icons.timer,
                        value: activity.formattedDuration,
                      ),
                      if (activity.matchedMediaIds.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        _StatBadge(
                          icon: Icons.photo_library,
                          value: '${activity.matchedMediaIds.length}',
                          highlight: true,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // Arrow
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.white.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}';
    }
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool highlight;

  const _StatBadge({
    required this.icon,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlight
            ? AppTheme.primaryColor.withOpacity(0.2)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: highlight ? AppTheme.primaryColor : Colors.white54,
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: highlight ? AppTheme.primaryColor : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
