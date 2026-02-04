import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_constants.dart';
import '../../models/media.dart';
import '../../models/activity.dart';

/// Service for accessing device Camera Roll / Photo Library
class CameraRollService {
  bool _hasPermission = false;

  /// Check and request photo library permissions
  Future<bool> requestPermission() async {
    final permission = await PhotoManager.requestPermissionExtend();
    _hasPermission = permission.isAuth;
    return _hasPermission;
  }

  /// Check current permission status
  Future<bool> checkPermission() async {
    final permission = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: RequestType.common,
          mediaLocation: true,
        ),
      ),
    );
    _hasPermission = permission.isAuth;
    return _hasPermission;
  }

  /// Get all albums
  Future<List<AssetPathEntity>> getAlbums({
    RequestType type = RequestType.common,
  }) async {
    if (!_hasPermission) {
      await requestPermission();
    }
    
    return await PhotoManager.getAssetPathList(
      type: type,
      filterOption: FilterOptionGroup(
        videoOption: const FilterOption(
          needTitle: true,
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
        imageOption: const FilterOption(
          needTitle: true,
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );
  }

  /// Get media from a specific album
  Future<List<AssetEntity>> getMediaFromAlbum(
    AssetPathEntity album, {
    int page = 0,
    int pageSize = 50,
  }) async {
    return await album.getAssetListPaged(
      page: page,
      size: pageSize,
    );
  }

  /// Get all media from device within date range
  Future<List<MediaItem>> getMediaInDateRange(
    DateTime start,
    DateTime end, {
    RequestType type = RequestType.common,
  }) async {
    if (!_hasPermission) {
      final granted = await requestPermission();
      if (!granted) return [];
    }

    final filterOption = FilterOptionGroup(
      createTimeCond: DateTimeCond(
        min: start,
        max: end,
      ),
      videoOption: const FilterOption(
        needTitle: true,
        sizeConstraint: SizeConstraint(ignoreSize: true),
      ),
      imageOption: const FilterOption(
        needTitle: true,
        sizeConstraint: SizeConstraint(ignoreSize: true),
      ),
      orders: [
        const OrderOption(type: OrderOptionType.createDate, asc: true),
      ],
    );

    final albums = await PhotoManager.getAssetPathList(
      type: type,
      filterOption: filterOption,
    );

    if (albums.isEmpty) return [];

    // Get all assets from the first (All Photos) album
    final allPhotosAlbum = albums.first;
    final count = await allPhotosAlbum.assetCountAsync;
    final assets = await allPhotosAlbum.getAssetListRange(start: 0, end: count);

    return await _convertAssetsToMediaItems(assets);
  }

  /// Get media matching an activity's time window
  Future<List<MediaItem>> getMediaForActivity(
    Activity activity, {
    int bufferMinutes = 30,
  }) async {
    final window = activity.getMatchingWindow(bufferMinutes: bufferMinutes);
    return await getMediaInDateRange(window.start, window.end);
  }

  /// Get recent media (last N days)
  Future<List<MediaItem>> getRecentMedia({
    int days = 30,
    int limit = 100,
  }) async {
    if (!_hasPermission) {
      final granted = await requestPermission();
      if (!granted) return [];
    }

    final filterOption = FilterOptionGroup(
      createTimeCond: DateTimeCond(
        min: DateTime.now().subtract(Duration(days: days)),
        max: DateTime.now(),
      ),
      orders: [
        const OrderOption(type: OrderOptionType.createDate, asc: false),
      ],
    );

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      filterOption: filterOption,
    );

    if (albums.isEmpty) return [];

    final allPhotosAlbum = albums.first;
    final assets = await allPhotosAlbum.getAssetListPaged(page: 0, size: limit);

    return await _convertAssetsToMediaItems(assets);
  }

  /// Convert AssetEntity list to MediaItem list
  Future<List<MediaItem>> _convertAssetsToMediaItems(
    List<AssetEntity> assets,
  ) async {
    final mediaItems = <MediaItem>[];

    for (final asset in assets) {
      try {
        final mediaItem = await _assetToMediaItem(asset);
        if (mediaItem != null) {
          mediaItems.add(mediaItem);
        }
      } catch (e) {
        // Skip assets that can't be processed
        continue;
      }
    }

    return mediaItems;
  }

  /// Convert single AssetEntity to MediaItem
  Future<MediaItem?> _assetToMediaItem(AssetEntity asset) async {
    final file = await asset.file;
    if (file == null) return null;

    final thumbnailData = await asset.thumbnailDataWithSize(
      const ThumbnailSize(300, 300),
      quality: 80,
    );

    MediaMetadata? metadata;
    if (asset.latitude != null && asset.longitude != null) {
      metadata = MediaMetadata(
        latitude: asset.latitude,
        longitude: asset.longitude,
      );
    }

    return MediaItem(
      id: asset.id,
      localPath: file.path,
      type: asset.type == AssetType.video ? MediaType.video : MediaType.photo,
      source: ContentSource.cameraRoll,
      createdAt: asset.createDateTime,
      modifiedAt: asset.modifiedDateTime,
      duration: asset.type == AssetType.video
          ? Duration(seconds: asset.duration)
          : null,
      width: asset.width,
      height: asset.height,
      fileSize: await file.length(),
      thumbnailPath: null, // Thumbnail stored separately if needed
      metadata: metadata,
    );
  }

  /// Get thumbnail for an asset
  Future<File?> getThumbnail(
    String assetId, {
    int width = 300,
    int height = 300,
    int quality = 80,
  }) async {
    final asset = await AssetEntity.fromId(assetId);
    if (asset == null) return null;
    
    return await asset.thumbnailDataWithSize(
      ThumbnailSize(width, height),
      quality: quality,
    ).then((data) async {
      if (data == null) return null;
      // In a real app, you'd save this to a cache directory
      return null;
    });
  }

  /// Get full resolution file for an asset
  Future<File?> getFile(String assetId) async {
    final asset = await AssetEntity.fromId(assetId);
    if (asset == null) return null;
    return await asset.file;
  }

  /// Get original file (for videos this returns the original quality)
  Future<File?> getOriginalFile(String assetId) async {
    final asset = await AssetEntity.fromId(assetId);
    if (asset == null) return null;
    return await asset.originFile;
  }

  /// Search media by date, type, and optional location
  Future<List<MediaItem>> searchMedia({
    DateTime? startDate,
    DateTime? endDate,
    MediaType? type,
    double? latitude,
    double? longitude,
    double radiusInMeters = 500,
  }) async {
    if (!_hasPermission) {
      final granted = await requestPermission();
      if (!granted) return [];
    }

    RequestType requestType = RequestType.common;
    if (type == MediaType.photo) {
      requestType = RequestType.image;
    } else if (type == MediaType.video) {
      requestType = RequestType.video;
    }

    final filterOption = FilterOptionGroup(
      createTimeCond: DateTimeCond(
        min: startDate ?? DateTime(2000),
        max: endDate ?? DateTime.now(),
      ),
      orders: [
        const OrderOption(type: OrderOptionType.createDate, asc: false),
      ],
    );

    final albums = await PhotoManager.getAssetPathList(
      type: requestType,
      filterOption: filterOption,
    );

    if (albums.isEmpty) return [];

    final allPhotosAlbum = albums.first;
    final count = await allPhotosAlbum.assetCountAsync;
    final assets = await allPhotosAlbum.getAssetListRange(start: 0, end: count);

    // Convert and filter by location if specified
    var mediaItems = await _convertAssetsToMediaItems(assets);

    if (latitude != null && longitude != null) {
      mediaItems = mediaItems.where((item) {
        if (!item.hasLocation) return false;
        final distance = _calculateDistance(
          latitude,
          longitude,
          item.metadata!.latitude!,
          item.metadata!.longitude!,
        );
        return distance <= radiusInMeters;
      }).toList();
    }

    return mediaItems;
  }

  /// Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000.0; // meters
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat1)) *
            _cos(_toRadians(lat2)) *
            _sin(dLon / 2) *
            _sin(dLon / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * 3.141592653589793 / 180;
  double _sin(double x) => _customSin(x);
  double _cos(double x) => _customCos(x);
  double _sqrt(double x) => _customSqrt(x);
  double _atan2(double y, double x) => _customAtan2(y, x);

  // Simple math implementations (in production, use dart:math)
  double _customSin(double x) {
    // Taylor series approximation
    double result = 0;
    double term = x;
    for (int i = 1; i <= 10; i++) {
      result += term;
      term *= -x * x / ((2 * i) * (2 * i + 1));
    }
    return result;
  }

  double _customCos(double x) {
    return _customSin(x + 1.5707963267948966);
  }

  double _customSqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  double _customAtan2(double y, double x) {
    // Simplified atan2
    if (x > 0) return _customAtan(y / x);
    if (x < 0 && y >= 0) return _customAtan(y / x) + 3.141592653589793;
    if (x < 0 && y < 0) return _customAtan(y / x) - 3.141592653589793;
    if (x == 0 && y > 0) return 1.5707963267948966;
    if (x == 0 && y < 0) return -1.5707963267948966;
    return 0;
  }

  double _customAtan(double x) {
    // Taylor series for small x
    if (x.abs() > 1) {
      return (x > 0 ? 1 : -1) * 1.5707963267948966 - _customAtan(1 / x);
    }
    double result = 0;
    double term = x;
    for (int i = 0; i < 20; i++) {
      result += term / (2 * i + 1);
      term *= -x * x;
    }
    return result;
  }
}
