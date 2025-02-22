import 'dart:async';
import 'dart:io' show PathNotFoundException;
import 'dart:isolate';

import 'package:file/file.dart' hide FileSystem;
import 'package:file/local.dart';
import 'package:flutter_cache_manager/src/storage/file_system/file_system.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class IOFileSystem implements FileSystem {
  final Future<Directory> _fileDir;
  final bool _useIsolates;

  IOFileSystem(Future<Directory> dir, {bool useIsolates = true})
      : _useIsolates = useIsolates,
        _fileDir = dir.then((value) => _createDir(value));

  factory IOFileSystem.fromCacheKey(String cacheKey) =>
      IOFileSystem(_getDirFoCacherKey(cacheKey));

  static Future<Directory> _getDirFoCacherKey(String key) async {
    final baseDir = await getTemporaryDirectory();
    final path = p.join(baseDir.path, key);

    const fs = LocalFileSystem();
    final directory = fs.directory(path);
    return directory;
  }

  static Future<Directory> _createDir(Directory d) async {
    await d.create(recursive: true);
    return d;
  }

  @override
  Future<File> createFile(String name) async {
    final directory = await _fileDir;
    if (!(await directory.exists())) {
      await _createDir(directory);
    }
    return directory.childFile(name);
  }

  @override
  Future<void> deleteCacheDir() async {
    final directory = await _fileDir;

    if (await directory.exists()) {
      Future<void> handleDelete() async {
        try {
          final dirToDelete =
              await directory.rename('${directory.path}.remove');
          await dirToDelete.delete(recursive: true);
        } on PathNotFoundException catch (_) {
          // Avoid race conditions where the file might already be deleted by the OS
        }
      }

      // It can take a while to delete the directory, so we rename it first
      // and let it delete in the background.
      unawaited(_useIsolates ? Isolate.run(handleDelete) : handleDelete());
    }
  }

  @override
  Future<void> deleteDanglingCache() async {
    final directory = await _fileDir;

    const fs = LocalFileSystem();
    final dirToDelete = fs.directory('${directory.path}.remove');

    if (await dirToDelete.exists()) {
      Future<void> handleDelete() async {
        try {
          // print("Deleting cache dir: $dirToDelete");
          await dirToDelete.delete(recursive: true);
        } on PathNotFoundException catch (_) {
          // Avoid race conditions where the file might already be deleted by the OS
        }
      }

      unawaited(_useIsolates ? Isolate.run(handleDelete) : handleDelete());
    }
  }
}
