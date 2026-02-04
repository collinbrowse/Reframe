import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import '../core/constants/app_constants.dart';

part 'media.g.dart';

/// Media item model (photo or video from any source)
@JsonSerializable()
class MediaItem extends Equatable {
  final String id;
  final String localPath;
  final String? remotePath;
  final MediaType type;
  final ContentSource source;
  final DateTime createdAt;
  final DateTime? modifiedAt;
  final Duration? duration; // For videos
  final int? width;
  final int? height;
  final int? fileSize; // in bytes
  final String? thumbnailPath;
  final MediaMetadata? metadata;
  final List<String>? aiLabels; // AI-detected content labels
  final String? activityId; // Linked activity ID
  final bool isSelected; // For editor selection
  final int? orderIndex; // Order in project

  const MediaItem({
    required this.id,
    required this.localPath,
    this.remotePath,
    required this.type,
    required this.source,
    required this.createdAt,
    this.modifiedAt,
    this.duration,
    this.width,
    this.height,
    this.fileSize,
    this.thumbnailPath,
    this.metadata,
    this.aiLabels,
    this.activityId,
    this.isSelected = false,
    this.orderIndex,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) => _$MediaItemFromJson(json);
  Map<String, dynamic> toJson() => _$MediaItemToJson(this);

  MediaItem copyWith({
    String? id,
    String? localPath,
    String? remotePath,
    MediaType? type,
    ContentSource? source,
    DateTime? createdAt,
    DateTime? modifiedAt,
    Duration? duration,
    int? width,
    int? height,
    int? fileSize,
    String? thumbnailPath,
    MediaMetadata? metadata,
    List<String>? aiLabels,
    String? activityId,
    bool? isSelected,
    int? orderIndex,
  }) {
    return MediaItem(
      id: id ?? this.id,
      localPath: localPath ?? this.localPath,
      remotePath: remotePath ?? this.remotePath,
      type: type ?? this.type,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      duration: duration ?? this.duration,
      width: width ?? this.width,
      height: height ?? this.height,
      fileSize: fileSize ?? this.fileSize,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      metadata: metadata ?? this.metadata,
      aiLabels: aiLabels ?? this.aiLabels,
      activityId: activityId ?? this.activityId,
      isSelected: isSelected ?? this.isSelected,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  bool get isVideo => type == MediaType.video;
  bool get isPhoto => type == MediaType.photo;
  bool get hasLocation => metadata?.latitude != null && metadata?.longitude != null;
  
  String get formattedDuration {
    if (duration == null) return '';
    final minutes = duration!.inMinutes;
    final seconds = duration!.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedFileSize {
    if (fileSize == null) return 'Unknown';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    if (fileSize! < 1024 * 1024 * 1024) {
      return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(fileSize! / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get aspectRatioString {
    if (width == null || height == null) return 'Unknown';
    final ratio = width! / height!;
    if ((ratio - 16/9).abs() < 0.1) return '16:9';
    if ((ratio - 9/16).abs() < 0.1) return '9:16';
    if ((ratio - 4/3).abs() < 0.1) return '4:3';
    if ((ratio - 3/4).abs() < 0.1) return '3:4';
    if ((ratio - 1).abs() < 0.1) return '1:1';
    return '${width}x$height';
  }

  @override
  List<Object?> get props => [
        id,
        localPath,
        remotePath,
        type,
        source,
        createdAt,
        modifiedAt,
        duration,
        width,
        height,
        fileSize,
        thumbnailPath,
        metadata,
        aiLabels,
        activityId,
        isSelected,
        orderIndex,
      ];
}

/// Media type enum
enum MediaType {
  photo,
  video,
  audio;

  String get label {
    switch (this) {
      case MediaType.photo:
        return 'Photo';
      case MediaType.video:
        return 'Video';
      case MediaType.audio:
        return 'Audio';
    }
  }
}

/// Metadata extracted from media files
@JsonSerializable()
class MediaMetadata extends Equatable {
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final String? locationName;
  final String? cameraModel;
  final String? lensModel;
  final double? focalLength;
  final double? aperture;
  final String? shutterSpeed;
  final int? iso;
  final bool? hasFlash;
  final String? orientation;

  const MediaMetadata({
    this.latitude,
    this.longitude,
    this.altitude,
    this.locationName,
    this.cameraModel,
    this.lensModel,
    this.focalLength,
    this.aperture,
    this.shutterSpeed,
    this.iso,
    this.hasFlash,
    this.orientation,
  });

  factory MediaMetadata.fromJson(Map<String, dynamic> json) =>
      _$MediaMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$MediaMetadataToJson(this);

  bool get hasGpsData => latitude != null && longitude != null;

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        altitude,
        locationName,
        cameraModel,
        lensModel,
        focalLength,
        aperture,
        shutterSpeed,
        iso,
        hasFlash,
        orientation,
      ];
}

/// Media collection for an activity
@JsonSerializable()
class ActivityMedia extends Equatable {
  final String activityId;
  final List<MediaItem> photos;
  final List<MediaItem> videos;
  final DateTime? lastUpdated;

  const ActivityMedia({
    required this.activityId,
    this.photos = const [],
    this.videos = const [],
    this.lastUpdated,
  });

  factory ActivityMedia.fromJson(Map<String, dynamic> json) =>
      _$ActivityMediaFromJson(json);
  Map<String, dynamic> toJson() => _$ActivityMediaToJson(this);

  List<MediaItem> get allMedia => [...photos, ...videos];
  int get totalCount => photos.length + videos.length;
  bool get isEmpty => photos.isEmpty && videos.isEmpty;

  Duration get totalVideoDuration {
    return videos.fold(
      Duration.zero,
      (total, video) => total + (video.duration ?? Duration.zero),
    );
  }

  ActivityMedia copyWith({
    String? activityId,
    List<MediaItem>? photos,
    List<MediaItem>? videos,
    DateTime? lastUpdated,
  }) {
    return ActivityMedia(
      activityId: activityId ?? this.activityId,
      photos: photos ?? this.photos,
      videos: videos ?? this.videos,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [activityId, photos, videos, lastUpdated];
}

/// Import result from a content source
class MediaImportResult {
  final List<MediaItem> importedMedia;
  final int skippedCount;
  final List<String> errors;
  final Duration importDuration;

  const MediaImportResult({
    required this.importedMedia,
    this.skippedCount = 0,
    this.errors = const [],
    required this.importDuration,
  });

  bool get hasErrors => errors.isNotEmpty;
  int get successCount => importedMedia.length;
  int get totalProcessed => successCount + skippedCount + errors.length;
}
