import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/project.dart';
import '../../../services/video/video_editor_service.dart';

class ExportScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ExportScreen({super.key, required this.projectId});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  ExportState _state = ExportState.ready;
  double _progress = 0;
  String _statusMessage = 'Ready to export';
  ExportResult? _result;

  @override
  Widget build(BuildContext context) {
    final project = ref.read(projectsProvider.notifier).getProject(widget.projectId);

    if (project == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: AppBar(title: const Text('Export')),
        body: const Center(child: Text('Project not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Export'),
        leading: _state == ExportState.exporting
            ? const SizedBox.shrink()
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => context.pop(),
              ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Project info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.movie_creation,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${project.outputFormat.label} • ${project.clips.length} clips',
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
            const SizedBox(height: 24),

            // Export settings
            if (_state == ExportState.ready) ...[
              _buildExportSettings(project),
            ],

            // Export progress
            if (_state == ExportState.exporting) ...[
              _buildExportProgress(),
            ],

            // Export complete
            if (_state == ExportState.complete) ...[
              _buildExportComplete(project),
            ],

            // Export failed
            if (_state == ExportState.failed) ...[
              _buildExportFailed(),
            ],

            const Spacer(),

            // Action buttons
            _buildActionButtons(project),
          ],
        ),
      ),
    );
  }

  Widget _buildExportSettings(Project project) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Export Settings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _SettingRow(
            icon: Icons.aspect_ratio,
            label: 'Resolution',
            value: '${project.settings.width}x${project.settings.height}',
          ),
          const Divider(height: 24, color: Colors.white12),
          _SettingRow(
            icon: Icons.speed,
            label: 'Frame Rate',
            value: '${project.settings.frameRate} fps',
          ),
          const Divider(height: 24, color: Colors.white12),
          _SettingRow(
            icon: Icons.high_quality,
            label: 'Quality',
            value: 'Standard (1080p)',
          ),
          const Divider(height: 24, color: Colors.white12),
          _SettingRow(
            icon: Icons.timer,
            label: 'Duration',
            value: _formatDuration(project.totalDuration),
          ),
        ],
      ),
    );
  }

  Widget _buildExportProgress() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 8,
                    backgroundColor: AppTheme.surfaceDark,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor,
                    ),
                  ),
                ),
                Text(
                  '${(_progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            _statusMessage,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please keep the app open',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportComplete(Project project) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 50,
              color: AppTheme.success,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Export Complete!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          if (_result != null)
            Text(
              'Size: ${_result!.formattedFileSize}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          const SizedBox(height: 32),
          
          // Share options
          const Text(
            'Share to',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ShareButton(
                icon: Icons.camera_alt,
                label: 'Instagram',
                color: const Color(0xFFE4405F),
                onTap: () => _shareToApp('instagram'),
              ),
              const SizedBox(width: 16),
              _ShareButton(
                icon: Icons.music_note,
                label: 'TikTok',
                color: const Color(0xFF000000),
                onTap: () => _shareToApp('tiktok'),
              ),
              const SizedBox(width: 16),
              _ShareButton(
                icon: Icons.play_arrow,
                label: 'YouTube',
                color: const Color(0xFFFF0000),
                onTap: () => _shareToApp('youtube'),
              ),
              const SizedBox(width: 16),
              _ShareButton(
                icon: Icons.more_horiz,
                label: 'More',
                color: AppTheme.surfaceDark,
                onTap: _shareGeneric,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExportFailed() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              size: 50,
              color: AppTheme.error,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Export Failed',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _result?.error ?? 'An error occurred during export',
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

  Widget _buildActionButtons(Project project) {
    if (_state == ExportState.exporting) {
      return const SizedBox.shrink();
    }

    if (_state == ExportState.complete) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Back to Home'),
            ),
          ),
        ],
      );
    }

    if (_state == ExportState.failed) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => _startExport(project),
              child: const Text('Try Again'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('Cancel'),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () => _startExport(project),
        icon: const Icon(Icons.download),
        label: const Text('Start Export'),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Future<void> _startExport(Project project) async {
    setState(() {
      _state = ExportState.exporting;
      _progress = 0;
      _statusMessage = 'Preparing...';
    });

    final videoEditor = ref.read(videoEditorProvider);
    videoEditor.onProgress = (progress, status) {
      if (mounted) {
        setState(() {
          _progress = progress;
          _statusMessage = status;
        });
      }
    };

    try {
      final result = await videoEditor.exportProject(project);
      
      if (mounted) {
        setState(() {
          _result = result;
          _state = result.success ? ExportState.complete : ExportState.failed;
        });

        if (result.success) {
          // Update project with export path
          final updatedProject = project.copyWith(
            exportPath: result.outputPath,
            thumbnailPath: result.thumbnailPath,
            status: ProjectStatus.exported,
          );
          await ref.read(projectsProvider.notifier).updateProject(updatedProject);
          
          ref.read(analyticsProvider).trackExportCompleted(
            projectId: project.id,
            fileSizeBytes: result.fileSize ?? 0,
            processingTimeMs: result.duration.inMilliseconds,
          );
        } else {
          ref.read(analyticsProvider).trackExportFailed(
            projectId: project.id,
            error: result.error ?? 'Unknown error',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = ExportState.failed;
          _result = ExportResult(
            success: false,
            error: e.toString(),
            duration: Duration.zero,
          );
        });
      }
    }
  }

  void _shareToApp(String app) {
    if (_result?.outputPath == null) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening $app...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    // Share to specific app
    Share.shareXFiles(
      [XFile(_result!.outputPath!)],
      text: 'Check out my activity!',
    );
  }

  void _shareGeneric() {
    if (_result?.outputPath == null) return;
    
    Share.shareXFiles(
      [XFile(_result!.outputPath!)],
      text: 'Check out my activity!',
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

enum ExportState {
  ready,
  exporting,
  complete,
  failed,
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SettingRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _ShareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
