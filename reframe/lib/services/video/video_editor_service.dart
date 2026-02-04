import 'dart:io';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/statistics.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/project.dart';
import '../../models/media.dart';

/// Service for video editing and processing using FFmpeg
class VideoEditorService {
  /// Export progress callback
  Function(double progress, String status)? onProgress;

  /// Get temporary directory for processing
  Future<Directory> get _tempDir async {
    final dir = await getTemporaryDirectory();
    final processingDir = Directory('${dir.path}/reframe_processing');
    if (!await processingDir.exists()) {
      await processingDir.create(recursive: true);
    }
    return processingDir;
  }

  /// Get output directory for exports
  Future<Directory> get _outputDir async {
    final dir = await getApplicationDocumentsDirectory();
    final outputDir = Directory('${dir.path}/reframe_exports');
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }
    return outputDir;
  }

  /// Export project to video file
  Future<ExportResult> exportProject(Project project) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      onProgress?.call(0, 'Preparing export...');

      if (project.clips.isEmpty) {
        throw VideoEditorException('Project has no clips');
      }

      final tempDir = await _tempDir;
      final outputDir = await _outputDir;
      final outputPath = '${outputDir.path}/${project.name}_${DateTime.now().millisecondsSinceEpoch}.mp4';

      // Create concat file for FFmpeg
      onProgress?.call(0.1, 'Processing clips...');
      final concatFilePath = await _createConcatFile(project.clips, tempDir);

      // Build FFmpeg command
      final command = await _buildExportCommand(
        project,
        concatFilePath,
        outputPath,
      );

      onProgress?.call(0.2, 'Rendering video...');

      // Execute FFmpeg
      final session = await FFmpegKit.executeAsync(
        command,
        (session) async {
          final returnCode = await session.getReturnCode();
          if (ReturnCode.isSuccess(returnCode)) {
            onProgress?.call(1.0, 'Export complete!');
          }
        },
        (log) {
          // Log callback
        },
        (statistics) {
          _handleStatistics(statistics, project.totalDuration);
        },
      );

      final returnCode = await session.getReturnCode();

      if (!ReturnCode.isSuccess(returnCode)) {
        final logs = await session.getAllLogsAsString();
        throw VideoEditorException('Export failed: $logs');
      }

      // Generate thumbnail
      onProgress?.call(0.95, 'Generating thumbnail...');
      final thumbnailPath = await _generateThumbnail(outputPath, tempDir);

      stopwatch.stop();

      return ExportResult(
        success: true,
        outputPath: outputPath,
        thumbnailPath: thumbnailPath,
        duration: stopwatch.elapsed,
        fileSize: await File(outputPath).length(),
      );
    } catch (e) {
      stopwatch.stop();
      return ExportResult(
        success: false,
        error: e.toString(),
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Create concat file for joining clips
  Future<String> _createConcatFile(
    List<ProjectClip> clips,
    Directory tempDir,
  ) async {
    final concatFile = File('${tempDir.path}/concat.txt');
    final buffer = StringBuffer();

    for (final clip in clips) {
      // Escape single quotes in path
      final escapedPath = clip.media.localPath.replaceAll("'", "'\\''");
      buffer.writeln("file '$escapedPath'");
      
      // Add in/out points if trimmed
      if (clip.startTime != Duration.zero) {
        buffer.writeln('inpoint ${clip.startTime.inMilliseconds / 1000}');
      }
      if (clip.endTime != clip.clipDuration) {
        buffer.writeln('outpoint ${clip.endTime.inMilliseconds / 1000}');
      }
    }

    await concatFile.writeAsString(buffer.toString());
    return concatFile.path;
  }

  /// Build FFmpeg export command
  Future<String> _buildExportCommand(
    Project project,
    String concatFilePath,
    String outputPath,
  ) async {
    final settings = project.settings;
    final filters = <String>[];

    // Scale filter for resolution
    filters.add('scale=${settings.width}:${settings.height}:force_original_aspect_ratio=decrease');
    filters.add('pad=${settings.width}:${settings.height}:(ow-iw)/2:(oh-ih)/2');

    // Add color grading filter if specified
    if (settings.colorGrade != 'none') {
      filters.add(_getColorGradeFilter(settings.colorGrade));
    }

    // Build complex filter
    final filterComplex = filters.join(',');

    // Audio handling
    String audioOptions = '';
    if (project.musicTrack != null) {
      audioOptions = '-i "${project.musicTrack!.filePath}" -filter_complex "[0:a][1:a]amix=inputs=2:duration=first" ';
      if (project.musicTrack!.fadeIn) {
        audioOptions += '-af "afade=t=in:st=0:d=2" ';
      }
    }

    return '''
-f concat -safe 0 -i "$concatFilePath" $audioOptions-vf "$filterComplex" -c:v ${AppConstants.videoCodec} -preset medium -crf 23 -c:a ${AppConstants.audioCodec} -b:a 128k -r ${settings.frameRate} -y "$outputPath"
''';
  }

  /// Handle FFmpeg statistics for progress
  void _handleStatistics(Statistics statistics, Duration totalDuration) {
    final time = statistics.getTime();
    if (time > 0 && totalDuration.inMilliseconds > 0) {
      final progress = (time / totalDuration.inMilliseconds).clamp(0.2, 0.9);
      onProgress?.call(progress, 'Rendering: ${(progress * 100).toInt()}%');
    }
  }

  /// Generate thumbnail from video
  Future<String?> _generateThumbnail(
    String videoPath,
    Directory tempDir,
  ) async {
    final thumbnailPath = '${tempDir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    final command = '-i "$videoPath" -ss 00:00:01 -vframes 1 -vf "scale=480:-1" -y "$thumbnailPath"';
    
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      return thumbnailPath;
    }
    return null;
  }

  /// Get color grade filter string
  String _getColorGradeFilter(String grade) {
    switch (grade) {
      case 'vintage':
        return 'colorbalance=rs=0.1:gs=-0.1:bs=-0.1,curves=vintage';
      case 'vivid':
        return 'eq=saturation=1.3:contrast=1.1';
      case 'muted':
        return 'eq=saturation=0.7:contrast=0.95';
      case 'dramatic':
        return 'eq=contrast=1.2:brightness=-0.05,curves=darker';
      case 'warm':
        return 'colorbalance=rs=0.1:gs=0.05:bs=-0.1';
      case 'cool':
        return 'colorbalance=rs=-0.1:gs=0:bs=0.1';
      case 'blackAndWhite':
        return 'hue=s=0';
      case 'sepia':
        return 'colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131';
      default:
        return '';
    }
  }

  /// Trim a single clip
  Future<String> trimClip(
    MediaItem media,
    Duration start,
    Duration end,
  ) async {
    final tempDir = await _tempDir;
    final outputPath = '${tempDir.path}/trimmed_${media.id}_${DateTime.now().millisecondsSinceEpoch}.mp4';

    final startSeconds = start.inMilliseconds / 1000;
    final durationSeconds = (end - start).inMilliseconds / 1000;

    final command = '-i "${media.localPath}" -ss $startSeconds -t $durationSeconds -c copy -y "$outputPath"';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      throw VideoEditorException('Failed to trim clip');
    }

    return outputPath;
  }

  /// Apply filter to a clip
  Future<String> applyFilter(
    MediaItem media,
    ClipFilter filter,
  ) async {
    final tempDir = await _tempDir;
    final outputPath = '${tempDir.path}/filtered_${media.id}_${DateTime.now().millisecondsSinceEpoch}.mp4';

    final filterString = _buildFilterString(filter);
    final command = '-i "${media.localPath}" -vf "$filterString" -c:a copy -y "$outputPath"';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      throw VideoEditorException('Failed to apply filter');
    }

    return outputPath;
  }

  /// Build filter string from ClipFilter
  String _buildFilterString(ClipFilter filter) {
    final intensity = filter.intensity;
    
    switch (filter.type) {
      case FilterType.brightness:
        return 'eq=brightness=${(intensity - 0.5) * 2}';
      case FilterType.contrast:
        return 'eq=contrast=${0.5 + intensity}';
      case FilterType.saturation:
        return 'eq=saturation=${intensity * 2}';
      case FilterType.warmth:
        final warmth = (intensity - 0.5) * 0.2;
        return 'colorbalance=rs=$warmth:gs=${warmth/2}:bs=${-warmth}';
      case FilterType.vignette:
        return 'vignette=PI/${2 + (1 - intensity) * 4}';
      case FilterType.blur:
        return 'boxblur=${(intensity * 10).round()}:1';
      case FilterType.sharpen:
        return 'unsharp=5:5:${intensity * 2}:5:5:0';
      case FilterType.vintage:
        return 'curves=vintage,eq=saturation=${0.7 + intensity * 0.3}';
      case FilterType.blackAndWhite:
        return 'hue=s=0';
      case FilterType.sepia:
        return 'colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131';
      case FilterType.vivid:
        return 'eq=saturation=${1.2 + intensity * 0.3}:contrast=${1.05 + intensity * 0.1}';
      case FilterType.muted:
        return 'eq=saturation=${1 - intensity * 0.5}';
      case FilterType.dramatic:
        return 'eq=contrast=${1.1 + intensity * 0.2}:brightness=${-intensity * 0.1}';
    }
  }

  /// Add transition between two clips
  Future<String> addTransition(
    String clip1Path,
    String clip2Path,
    ClipTransition transition,
    Duration transitionDuration,
  ) async {
    final tempDir = await _tempDir;
    final outputPath = '${tempDir.path}/transition_${DateTime.now().millisecondsSinceEpoch}.mp4';

    final transitionFilter = _getTransitionFilter(transition, transitionDuration);
    
    final command = '''
-i "$clip1Path" -i "$clip2Path" -filter_complex "$transitionFilter" -y "$outputPath"
''';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      throw VideoEditorException('Failed to add transition');
    }

    return outputPath;
  }

  /// Get transition filter for FFmpeg
  String _getTransitionFilter(ClipTransition transition, Duration duration) {
    final durationSec = duration.inMilliseconds / 1000;
    
    switch (transition) {
      case ClipTransition.fade:
        return '[0:v]fade=t=out:st=0:d=$durationSec[v0];[1:v]fade=t=in:st=0:d=$durationSec[v1];[v0][v1]concat=n=2:v=1:a=0';
      case ClipTransition.dissolve:
        return '[0:v][1:v]xfade=transition=dissolve:duration=$durationSec:offset=0';
      case ClipTransition.wipeLeft:
        return '[0:v][1:v]xfade=transition=wipeleft:duration=$durationSec:offset=0';
      case ClipTransition.wipeRight:
        return '[0:v][1:v]xfade=transition=wiperight:duration=$durationSec:offset=0';
      case ClipTransition.wipeUp:
        return '[0:v][1:v]xfade=transition=wipeup:duration=$durationSec:offset=0';
      case ClipTransition.wipeDown:
        return '[0:v][1:v]xfade=transition=wipedown:duration=$durationSec:offset=0';
      case ClipTransition.zoom:
        return '[0:v][1:v]xfade=transition=zoomin:duration=$durationSec:offset=0';
      case ClipTransition.blur:
        return '[0:v][1:v]xfade=transition=fadeblack:duration=$durationSec:offset=0';
      case ClipTransition.slide:
        return '[0:v][1:v]xfade=transition=slideleft:duration=$durationSec:offset=0';
      case ClipTransition.none:
      default:
        return '[0:v][1:v]concat=n=2:v=1:a=0';
    }
  }

  /// Add text overlay to video
  Future<String> addTextOverlay(
    String videoPath,
    TextOverlay overlay,
  ) async {
    final tempDir = await _tempDir;
    final outputPath = '${tempDir.path}/text_${DateTime.now().millisecondsSinceEpoch}.mp4';

    final position = _getTextPosition(overlay.position);
    final startSec = overlay.startTime.inMilliseconds / 1000;
    final endSec = overlay.endTime.inMilliseconds / 1000;
    
    final textFilter = "drawtext=text='${overlay.text}':fontsize=${overlay.style.fontSize}:fontcolor=${overlay.style.color.replaceAll('#', '0x')}:$position:enable='between(t,$startSec,$endSec)'";

    final command = '-i "$videoPath" -vf "$textFilter" -c:a copy -y "$outputPath"';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      throw VideoEditorException('Failed to add text overlay');
    }

    return outputPath;
  }

  /// Get text position string for FFmpeg
  String _getTextPosition(TextPosition position) {
    switch (position) {
      case TextPosition.topLeft:
        return 'x=20:y=20';
      case TextPosition.topCenter:
        return 'x=(w-text_w)/2:y=20';
      case TextPosition.topRight:
        return 'x=w-text_w-20:y=20';
      case TextPosition.centerLeft:
        return 'x=20:y=(h-text_h)/2';
      case TextPosition.center:
        return 'x=(w-text_w)/2:y=(h-text_h)/2';
      case TextPosition.centerRight:
        return 'x=w-text_w-20:y=(h-text_h)/2';
      case TextPosition.bottomLeft:
        return 'x=20:y=h-text_h-20';
      case TextPosition.bottomCenter:
        return 'x=(w-text_w)/2:y=h-text_h-20';
      case TextPosition.bottomRight:
        return 'x=w-text_w-20:y=h-text_h-20';
    }
  }

  /// Add audio/music to video
  Future<String> addAudio(
    String videoPath,
    MusicTrack music,
    {bool keepOriginalAudio = true}
  ) async {
    final tempDir = await _tempDir;
    final outputPath = '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.mp4';

    String filterComplex;
    if (keepOriginalAudio) {
      filterComplex = '[0:a]volume=1[a0];[1:a]volume=${music.volume}[a1];[a0][a1]amix=inputs=2:duration=first[a]';
    } else {
      filterComplex = '[1:a]volume=${music.volume}[a]';
    }

    String fadeFilter = '';
    if (music.fadeIn) {
      fadeFilter += 'afade=t=in:st=0:d=2,';
    }
    if (music.fadeOut) {
      fadeFilter += 'afade=t=out:st=${music.duration.inSeconds - 2}:d=2';
    }

    final command = '''
-i "$videoPath" -i "${music.filePath}" -filter_complex "$filterComplex${fadeFilter.isNotEmpty ? ',$fadeFilter' : ''}" -map 0:v -map "[a]" -c:v copy -c:a aac -y "$outputPath"
''';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      throw VideoEditorException('Failed to add audio');
    }

    return outputPath;
  }

  /// Change video speed
  Future<String> changeSpeed(
    String videoPath,
    double speed,
  ) async {
    final tempDir = await _tempDir;
    final outputPath = '${tempDir.path}/speed_${DateTime.now().millisecondsSinceEpoch}.mp4';

    final videoFilter = 'setpts=${1/speed}*PTS';
    final audioFilter = 'atempo=$speed';

    final command = '-i "$videoPath" -filter:v "$videoFilter" -filter:a "$audioFilter" -y "$outputPath"';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      throw VideoEditorException('Failed to change speed');
    }

    return outputPath;
  }

  /// Get video metadata
  Future<VideoMetadata> getVideoMetadata(String path) async {
    final session = await FFmpegKit.execute('-i "$path" -f null -');
    final output = await session.getAllLogsAsString();
    
    // Parse metadata from FFmpeg output
    final durationMatch = RegExp(r'Duration: (\d{2}):(\d{2}):(\d{2})\.(\d{2})').firstMatch(output ?? '');
    final sizeMatch = RegExp(r'(\d+)x(\d+)').firstMatch(output ?? '');
    
    Duration? duration;
    if (durationMatch != null) {
      final hours = int.parse(durationMatch.group(1)!);
      final minutes = int.parse(durationMatch.group(2)!);
      final seconds = int.parse(durationMatch.group(3)!);
      final centiseconds = int.parse(durationMatch.group(4)!);
      duration = Duration(
        hours: hours,
        minutes: minutes,
        seconds: seconds,
        milliseconds: centiseconds * 10,
      );
    }

    int? width, height;
    if (sizeMatch != null) {
      width = int.parse(sizeMatch.group(1)!);
      height = int.parse(sizeMatch.group(2)!);
    }

    return VideoMetadata(
      path: path,
      duration: duration,
      width: width,
      height: height,
    );
  }

  /// Clean up temporary files
  Future<void> cleanupTempFiles() async {
    final tempDir = await _tempDir;
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  }
}

/// Video metadata
class VideoMetadata {
  final String path;
  final Duration? duration;
  final int? width;
  final int? height;

  const VideoMetadata({
    required this.path,
    this.duration,
    this.width,
    this.height,
  });

  String get aspectRatio {
    if (width == null || height == null) return 'Unknown';
    final ratio = width! / height!;
    if ((ratio - 16/9).abs() < 0.1) return '16:9';
    if ((ratio - 9/16).abs() < 0.1) return '9:16';
    if ((ratio - 4/3).abs() < 0.1) return '4:3';
    if ((ratio - 1).abs() < 0.1) return '1:1';
    return '${width}x$height';
  }
}

/// Export result
class ExportResult {
  final bool success;
  final String? outputPath;
  final String? thumbnailPath;
  final String? error;
  final Duration duration;
  final int? fileSize;

  const ExportResult({
    required this.success,
    this.outputPath,
    this.thumbnailPath,
    this.error,
    required this.duration,
    this.fileSize,
  });

  String get formattedFileSize {
    if (fileSize == null) return 'Unknown';
    if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Video editor exception
class VideoEditorException implements Exception {
  final String message;
  VideoEditorException(this.message);

  @override
  String toString() => 'VideoEditorException: $message';
}
