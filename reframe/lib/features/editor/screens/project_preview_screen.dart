import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/project.dart';

class ProjectPreviewScreen extends ConsumerWidget {
  final String projectId;

  const ProjectPreviewScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.read(projectsProvider.notifier).getProject(projectId);

    if (project == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: AppBar(title: const Text('Preview')),
        body: const Center(child: Text('Project not found')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(project.name),
        actions: [
          TextButton(
            onPressed: () => context.push('/export/$projectId'),
            child: const Text('Export'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Video preview area
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: project.outputFormat == OutputFormat.vlog 
                    ? 16 / 9 
                    : 9 / 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Placeholder content
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.play_circle_filled,
                            size: 80,
                            color: Colors.white54,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${project.clips.length} clips',
                            style: const TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            _formatDuration(project.totalDuration),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Playback controls
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Progress bar
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: AppTheme.primaryColor,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: AppTheme.primaryColor,
                    overlayColor: AppTheme.primaryColor.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: 0,
                    onChanged: (value) {},
                  ),
                ),
                const SizedBox(height: 8),

                // Time display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '0:00',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    Text(
                      _formatDuration(project.totalDuration),
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Playback buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      iconSize: 36,
                      color: Colors.white,
                      onPressed: () {},
                    ),
                    const SizedBox(width: 24),
                    Container(
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.play_arrow),
                        iconSize: 48,
                        color: Colors.white,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Video preview coming soon'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      iconSize: 36,
                      color: Colors.white,
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
