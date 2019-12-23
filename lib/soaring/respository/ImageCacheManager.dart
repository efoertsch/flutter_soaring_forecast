import 'dart:async';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// From https://github.com/renefloor/flutter_cache_manager
class ImageCacheManager extends BaseCacheManager {
  static const key = "ImageCache";

  static ImageCacheManager _instance;

  factory ImageCacheManager() {
    if (_instance == null) {
      _instance = new ImageCacheManager._();
    }
    return _instance;
  }

  ImageCacheManager._()
      : super(
          key,
          maxAgeCacheObject: Duration(minutes: 15),
          maxNrOfCacheObjects: 25,
        );

  Future<String> getFilePath() async {
    var directory = await _tempImageCachePath;
    return p.join(directory.path, key);
  }
}

Future<Directory> get _tempImageCachePath async {
  final directory = await getTemporaryDirectory();
  return directory;
}
