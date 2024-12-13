import 'dart:async';

import 'package:file/file.dart' hide FileSystem;
import 'package:file/local.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/src/storage/file_system/file_system.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class IOFileSystem implements FileSystem {
  final Future<Directory> _fileDir;
  final String _cacheKey;

  IOFileSystem(this._cacheKey) : _fileDir = createDirectory(_cacheKey);

  static Future<Directory> createDirectory(String key) async {
    final baseDir = await getTemporaryDirectory();
    final path = p.join(baseDir.path, key);

    const fs = LocalFileSystem();
    final directory = fs.directory(path);
    await directory.create(recursive: true);
    return directory;
  }

  @override
  Future<File> createFile(String name) async {
    final directory = await _fileDir;
    if (!(await directory.exists())) {
      await createDirectory(_cacheKey);
    }
    return directory.childFile(name);
  }

  @override
  Future<void> deleteCacheDir() async {
    final directory = await _fileDir;

    if (await directory.exists()) {
      // It can take a while to delete the directory, so we rename it first
      // and let it delete in the background.
      final dirToDelete = await directory.rename('${directory.path}.remove');
      
      unawaited(compute((_) async {
        // print("Deleting cache dir: $dirToDelete");
        await dirToDelete.delete(recursive: true);
      }, null));
    }
  }
}
