import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/project.dart';
import '../../../models/media.dart';
import '../../../models/activity.dart';

class EditorScreen extends ConsumerStatefulWidget {
  final String? projectId;
  final String? activityId;
  final String? initialFormat;

  const EditorScreen({
    super.key,
    this.projectId,
    this.activityId,
    this.initialFormat,
  });

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  late Project _project;
  List<MediaItem> _availableMedia = [];
  bool _isLoading = true;
  OutputFormat _selectedFormat = OutputFormat.reel;
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeProject();
  }

  @override
  void dispose() {
    _promptController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _initializeProject() async {
    if (widget.projectId != null) {
      // Load existing project
      final project = ref.read(projectsProvider.notifier).getProject(widget.projectId!);
      if (project != null) {
        setState(() {
          _project = project;
          _selectedFormat = project.outputFormat;
          _nameController.text = project.name;
          _promptController.text = project.aiPrompt ?? '';
          _isLoading = false;
        });
        return;
      }
    }

    // Create new project
    final format = widget.initialFormat != null
        ? OutputFormat.values.firstWhere(
            (f) => f.name == widget.initialFormat,
            orElse: () => OutputFormat.reel,
          )
        : OutputFormat.reel;

    Activity? activity;
    if (widget.activityId != null) {
      activity = ref.read(activitiesProvider.notifier).getActivity(widget.activityId!);
    }

    final project = Project.create(
      name: activity?.name ?? 'New Project',
      format: format,
      activityId: widget.activityId,
      activity: activity,
    );

    _nameController.text = project.name;

    setState(() {
      _project = project;
      _selectedFormat = format;
    });

    // Load media for activity
    if (activity != null) {
      await _loadMediaForActivity(activity);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadMediaForActivity(Activity activity) async {
    final cameraRoll = ref.read(cameraRollServiceProvider);
    final matcher = ref.read(activityMatcherProvider);

    try {
      final media = await cameraRoll.getMediaForActivity(activity);
      final matched = await matcher.matchMediaToActivity(activity, media);
      
      if (mounted) {
        setState(() {
          _availableMedia = matched;
        });

        // Auto-add clips
        final clips = matched.asMap().entries.map((entry) {
          return ProjectClip.fromMedia(entry.value, entry.key);
        }).toList();

        setState(() {
          _project = _project.copyWith(clips: clips);
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: GestureDetector(
          onTap: _editProjectName,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _project.name,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.edit, size: 16),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _project.clips.isEmpty ? null : _preview,
            child: const Text('Preview'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Format selector
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.surfaceDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Output Format',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: OutputFormat.values.map((format) {
                    final isSelected = _selectedFormat == format;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _FormatButton(
                          format: format,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              _selectedFormat = format;
                              _project = _project.copyWith(
                                outputFormat: format,
                                settings: ProjectSettings.forFormat(format),
                              );
                            });
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // AI Prompt input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundDark,
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 18, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    const Text(
                      'AI Prompt',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _applyAiEdit,
                      child: const Text('Apply'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _promptController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Describe the style you want (e.g., "energetic with fast cuts" or "cinematic and smooth")',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceDark,
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),

          // Timeline/Clips
          Expanded(
            child: _project.clips.isEmpty
                ? _buildEmptyClips()
                : _buildTimeline(),
          ),

          // Bottom toolbar
          _buildBottomToolbar(),
        ],
      ),
    );
  }

  Widget _buildEmptyClips() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 64,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          const Text(
            'No clips added yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add photos and videos to create your content',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addMedia,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Add Media'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Column(
      children: [
        // Preview area
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    size: 64,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_project.clips.length} clips',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    _formatDuration(_project.totalDuration),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Timeline
        Expanded(
          flex: 1,
          child: Container(
            color: AppTheme.surfaceDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      const Text(
                        'Timeline',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        onPressed: _addMedia,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _project.clips.length,
                    onReorder: _reorderClips,
                    itemBuilder: (context, index) {
                      final clip = _project.clips[index];
                      return _ClipThumbnail(
                        key: ValueKey(clip.id),
                        clip: clip,
                        onTap: () => _editClip(index),
                        onDelete: () => _deleteClip(index),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomToolbar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _addMusic,
              icon: const Icon(Icons.music_note, size: 18),
              label: Text(_project.musicTrack != null ? 'Change Music' : 'Add Music'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _project.clips.isEmpty ? null : _export,
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Export'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editProjectName() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Project Name'),
        content: TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter project name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _project = _project.copyWith(name: _nameController.text);
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _applyAiEdit() {
    if (_promptController.text.isEmpty) return;
    
    setState(() {
      _project = _project.copyWith(aiPrompt: _promptController.text);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('AI style will be applied during export'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addMedia() {
    // TODO: Show media picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Media picker coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _reorderClips(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final clips = List<ProjectClip>.from(_project.clips);
      final clip = clips.removeAt(oldIndex);
      clips.insert(newIndex, clip);
      
      // Update order indices
      final updatedClips = clips.asMap().entries.map((entry) {
        return entry.value.copyWith(orderIndex: entry.key);
      }).toList();
      
      _project = _project.copyWith(clips: updatedClips);
    });
  }

  void _editClip(int index) {
    // TODO: Open clip editor
  }

  void _deleteClip(int index) {
    setState(() {
      final clips = List<ProjectClip>.from(_project.clips);
      clips.removeAt(index);
      _project = _project.copyWith(clips: clips);
    });
  }

  void _addMusic() {
    // TODO: Show music picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Music library coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _preview() {
    _saveProject();
    context.push('/preview/${_project.id}');
  }

  void _export() async {
    await _saveProject();
    if (mounted) {
      context.push('/export/${_project.id}');
    }
  }

  Future<void> _saveProject() async {
    await ref.read(projectsProvider.notifier).createProject(_project);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _FormatButton extends StatelessWidget {
  final OutputFormat format;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormatButton({
    required this.format,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.white24,
          ),
        ),
        child: Column(
          children: [
            Text(
              format.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              format.aspectRatio,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.white70 : Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClipThumbnail extends StatelessWidget {
  final ProjectClip clip;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ClipThumbnail({
    super.key,
    required this.clip,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: AppTheme.backgroundDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                clip.media.isVideo ? Icons.videocam : Icons.image,
                color: Colors.white38,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              bottom: 4,
              left: 4,
              right: 4,
              child: Text(
                _formatDuration(clip.duration),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final seconds = duration.inSeconds;
    if (seconds < 60) return '${seconds}s';
    return '${duration.inMinutes}:${(seconds % 60).toString().padLeft(2, '0')}';
  }
}
