import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import '../core/constants/app_constants.dart';
import 'media.dart';
import 'activity.dart';

part 'project.g.dart';

/// Video project model for editing and export
@JsonSerializable()
class Project extends Equatable {
  final String id;
  final String name;
  final OutputFormat outputFormat;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final String? activityId;
  final Activity? activity;
  final List<ProjectClip> clips;
  final ProjectSettings settings;
  final MusicTrack? musicTrack;
  final List<TextOverlay> textOverlays;
  final String? aiPrompt;
  final ProjectStatus status;
  final String? exportPath;
  final String? thumbnailPath;

  const Project({
    required this.id,
    required this.name,
    required this.outputFormat,
    required this.createdAt,
    required this.modifiedAt,
    this.activityId,
    this.activity,
    this.clips = const [],
    required this.settings,
    this.musicTrack,
    this.textOverlays = const [],
    this.aiPrompt,
    this.status = ProjectStatus.draft,
    this.exportPath,
    this.thumbnailPath,
  });

  factory Project.fromJson(Map<String, dynamic> json) => _$ProjectFromJson(json);
  Map<String, dynamic> toJson() => _$ProjectToJson(this);

  factory Project.create({
    required String name,
    required OutputFormat format,
    String? activityId,
    Activity? activity,
    String? aiPrompt,
  }) {
    final now = DateTime.now();
    return Project(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      outputFormat: format,
      createdAt: now,
      modifiedAt: now,
      activityId: activityId,
      activity: activity,
      settings: ProjectSettings.forFormat(format),
      aiPrompt: aiPrompt,
    );
  }

  Project copyWith({
    String? id,
    String? name,
    OutputFormat? outputFormat,
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? activityId,
    Activity? activity,
    List<ProjectClip>? clips,
    ProjectSettings? settings,
    MusicTrack? musicTrack,
    List<TextOverlay>? textOverlays,
    String? aiPrompt,
    ProjectStatus? status,
    String? exportPath,
    String? thumbnailPath,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      outputFormat: outputFormat ?? this.outputFormat,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      activityId: activityId ?? this.activityId,
      activity: activity ?? this.activity,
      clips: clips ?? this.clips,
      settings: settings ?? this.settings,
      musicTrack: musicTrack ?? this.musicTrack,
      textOverlays: textOverlays ?? this.textOverlays,
      aiPrompt: aiPrompt ?? this.aiPrompt,
      status: status ?? this.status,
      exportPath: exportPath ?? this.exportPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }

  Duration get totalDuration {
    return clips.fold(
      Duration.zero,
      (total, clip) => total + clip.duration,
    );
  }

  bool get isEmpty => clips.isEmpty;
  bool get isExported => exportPath != null;
  bool get canExport => clips.isNotEmpty && status != ProjectStatus.exporting;

  @override
  List<Object?> get props => [
        id,
        name,
        outputFormat,
        createdAt,
        modifiedAt,
        activityId,
        activity,
        clips,
        settings,
        musicTrack,
        textOverlays,
        aiPrompt,
        status,
        exportPath,
        thumbnailPath,
      ];
}

/// Individual clip in a project
@JsonSerializable()
class ProjectClip extends Equatable {
  final String id;
  final MediaItem media;
  final int orderIndex;
  final Duration startTime; // Start time in source media
  final Duration endTime; // End time in source media
  final Duration clipDuration; // Actual clip duration
  final ClipTransition? transitionIn;
  final ClipTransition? transitionOut;
  final List<ClipFilter> filters;
  final double volume;
  final double speed;
  final bool isMuted;
  final CropRect? crop;

  const ProjectClip({
    required this.id,
    required this.media,
    required this.orderIndex,
    required this.startTime,
    required this.endTime,
    required this.clipDuration,
    this.transitionIn,
    this.transitionOut,
    this.filters = const [],
    this.volume = 1.0,
    this.speed = 1.0,
    this.isMuted = false,
    this.crop,
  });

  factory ProjectClip.fromJson(Map<String, dynamic> json) => _$ProjectClipFromJson(json);
  Map<String, dynamic> toJson() => _$ProjectClipToJson(this);

  factory ProjectClip.fromMedia(MediaItem media, int orderIndex) {
    final duration = media.duration ?? const Duration(seconds: 5);
    return ProjectClip(
      id: '${media.id}_$orderIndex',
      media: media,
      orderIndex: orderIndex,
      startTime: Duration.zero,
      endTime: duration,
      clipDuration: duration,
    );
  }

  Duration get duration => Duration(
        milliseconds: (clipDuration.inMilliseconds / speed).round(),
      );

  ProjectClip copyWith({
    String? id,
    MediaItem? media,
    int? orderIndex,
    Duration? startTime,
    Duration? endTime,
    Duration? clipDuration,
    ClipTransition? transitionIn,
    ClipTransition? transitionOut,
    List<ClipFilter>? filters,
    double? volume,
    double? speed,
    bool? isMuted,
    CropRect? crop,
  }) {
    return ProjectClip(
      id: id ?? this.id,
      media: media ?? this.media,
      orderIndex: orderIndex ?? this.orderIndex,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      clipDuration: clipDuration ?? this.clipDuration,
      transitionIn: transitionIn ?? this.transitionIn,
      transitionOut: transitionOut ?? this.transitionOut,
      filters: filters ?? this.filters,
      volume: volume ?? this.volume,
      speed: speed ?? this.speed,
      isMuted: isMuted ?? this.isMuted,
      crop: crop ?? this.crop,
    );
  }

  @override
  List<Object?> get props => [
        id,
        media,
        orderIndex,
        startTime,
        endTime,
        clipDuration,
        transitionIn,
        transitionOut,
        filters,
        volume,
        speed,
        isMuted,
        crop,
      ];
}

/// Project settings
@JsonSerializable()
class ProjectSettings extends Equatable {
  final int width;
  final int height;
  final int frameRate;
  final int bitrate;
  final String aspectRatio;
  final int targetDuration; // in seconds, 0 = no limit
  final String colorGrade;
  final bool enableStabilization;
  final bool enableAutoEnhance;

  const ProjectSettings({
    required this.width,
    required this.height,
    this.frameRate = 30,
    this.bitrate = 8000000,
    required this.aspectRatio,
    this.targetDuration = 0,
    this.colorGrade = 'none',
    this.enableStabilization = true,
    this.enableAutoEnhance = true,
  });

  factory ProjectSettings.fromJson(Map<String, dynamic> json) =>
      _$ProjectSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$ProjectSettingsToJson(this);

  factory ProjectSettings.forFormat(OutputFormat format) {
    switch (format) {
      case OutputFormat.reel:
        return const ProjectSettings(
          width: 1080,
          height: 1920,
          aspectRatio: '9:16',
          targetDuration: 90,
        );
      case OutputFormat.vlog:
        return const ProjectSettings(
          width: 1920,
          height: 1080,
          aspectRatio: '16:9',
          targetDuration: 0,
        );
      case OutputFormat.story:
        return const ProjectSettings(
          width: 1080,
          height: 1920,
          aspectRatio: '9:16',
          targetDuration: 15,
        );
    }
  }

  ProjectSettings copyWith({
    int? width,
    int? height,
    int? frameRate,
    int? bitrate,
    String? aspectRatio,
    int? targetDuration,
    String? colorGrade,
    bool? enableStabilization,
    bool? enableAutoEnhance,
  }) {
    return ProjectSettings(
      width: width ?? this.width,
      height: height ?? this.height,
      frameRate: frameRate ?? this.frameRate,
      bitrate: bitrate ?? this.bitrate,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      targetDuration: targetDuration ?? this.targetDuration,
      colorGrade: colorGrade ?? this.colorGrade,
      enableStabilization: enableStabilization ?? this.enableStabilization,
      enableAutoEnhance: enableAutoEnhance ?? this.enableAutoEnhance,
    );
  }

  @override
  List<Object?> get props => [
        width,
        height,
        frameRate,
        bitrate,
        aspectRatio,
        targetDuration,
        colorGrade,
        enableStabilization,
        enableAutoEnhance,
      ];
}

/// Music track for project
@JsonSerializable()
class MusicTrack extends Equatable {
  final String id;
  final String title;
  final String? artist;
  final String filePath;
  final Duration duration;
  final MusicSource source;
  final double volume;
  final Duration startOffset;
  final bool fadeIn;
  final bool fadeOut;

  const MusicTrack({
    required this.id,
    required this.title,
    this.artist,
    required this.filePath,
    required this.duration,
    required this.source,
    this.volume = 0.7,
    this.startOffset = Duration.zero,
    this.fadeIn = true,
    this.fadeOut = true,
  });

  factory MusicTrack.fromJson(Map<String, dynamic> json) => _$MusicTrackFromJson(json);
  Map<String, dynamic> toJson() => _$MusicTrackToJson(this);

  @override
  List<Object?> get props => [
        id,
        title,
        artist,
        filePath,
        duration,
        source,
        volume,
        startOffset,
        fadeIn,
        fadeOut,
      ];
}

/// Music source type
enum MusicSource {
  userLibrary,
  royaltyFree,
  aiGenerated,
}

/// Text overlay
@JsonSerializable()
class TextOverlay extends Equatable {
  final String id;
  final String text;
  final Duration startTime;
  final Duration endTime;
  final TextPosition position;
  final TextStyle style;
  final TextAnimation? animation;

  const TextOverlay({
    required this.id,
    required this.text,
    required this.startTime,
    required this.endTime,
    this.position = TextPosition.center,
    this.style = const TextStyle(),
    this.animation,
  });

  factory TextOverlay.fromJson(Map<String, dynamic> json) =>
      _$TextOverlayFromJson(json);
  Map<String, dynamic> toJson() => _$TextOverlayToJson(this);

  @override
  List<Object?> get props => [id, text, startTime, endTime, position, style, animation];
}

/// Text style for overlays
@JsonSerializable()
class TextStyle extends Equatable {
  final String fontFamily;
  final double fontSize;
  final String color;
  final String? backgroundColor;
  final bool bold;
  final bool italic;
  final String alignment;

  const TextStyle({
    this.fontFamily = 'Inter',
    this.fontSize = 24,
    this.color = '#FFFFFF',
    this.backgroundColor,
    this.bold = false,
    this.italic = false,
    this.alignment = 'center',
  });

  factory TextStyle.fromJson(Map<String, dynamic> json) => _$TextStyleFromJson(json);
  Map<String, dynamic> toJson() => _$TextStyleToJson(this);

  @override
  List<Object?> get props => [
        fontFamily,
        fontSize,
        color,
        backgroundColor,
        bold,
        italic,
        alignment,
      ];
}

/// Text position enum
enum TextPosition {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  center,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

/// Text animation type
enum TextAnimation {
  none,
  fadeIn,
  slideIn,
  typewriter,
  bounce,
  scale,
}

/// Clip transition types
enum ClipTransition {
  none,
  fade,
  dissolve,
  wipeLeft,
  wipeRight,
  wipeUp,
  wipeDown,
  zoom,
  blur,
  slide,
}

/// Clip filter types
@JsonSerializable()
class ClipFilter extends Equatable {
  final FilterType type;
  final double intensity;
  final Map<String, dynamic>? parameters;

  const ClipFilter({
    required this.type,
    this.intensity = 1.0,
    this.parameters,
  });

  factory ClipFilter.fromJson(Map<String, dynamic> json) => _$ClipFilterFromJson(json);
  Map<String, dynamic> toJson() => _$ClipFilterToJson(this);

  @override
  List<Object?> get props => [type, intensity, parameters];
}

/// Filter type enum
enum FilterType {
  brightness,
  contrast,
  saturation,
  warmth,
  vignette,
  blur,
  sharpen,
  vintage,
  blackAndWhite,
  sepia,
  vivid,
  muted,
  dramatic,
}

/// Crop rectangle
@JsonSerializable()
class CropRect extends Equatable {
  final double left;
  final double top;
  final double right;
  final double bottom;

  const CropRect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  factory CropRect.fromJson(Map<String, dynamic> json) => _$CropRectFromJson(json);
  Map<String, dynamic> toJson() => _$CropRectToJson(this);

  @override
  List<Object?> get props => [left, top, right, bottom];
}

/// Project status
enum ProjectStatus {
  draft,
  editing,
  rendering,
  exporting,
  exported,
  failed,
}
