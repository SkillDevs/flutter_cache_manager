import 'dart:async';
import 'dart:io' show PathNotFoundException;

import 'package:file/file.dart' hide FileSystem;
import 'package:file/local.dart';
import 'package:flutter_cache_manager/src/storage/file_system/file_system.dart';
import 'package:flutter_cache_manager/src/storage/file_system/util.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class IOFileSystem implements FileSystem {
  final Future<Directory> _fileDir;

  /// Useful for testing, to mock slow deletes of big cache directories;
  final Duration? _deleteDelay;

  IOFileSystem(
    Future<Directory> dir, {
    Duration? deleteDelay,
  })  : _deleteDelay = deleteDelay,
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
      // It can take a while to delete the directory, so we rename it first
      // and let it delete in the background.

      Directory? dirToDelete;
      try {
        final dirToDeletePath = '${directory.path}.${const Uuid().v1()}.remove';
        dirToDelete = await directory.rename(dirToDeletePath);
      } on FileSystemException catch (e) {
        // Avoid race conditions where the file might already be deleted by the OS
        if (!isPathNotFoundException(e)) {
          rethrow;
        }
      }

      if (dirToDelete != null) {
        unawaited(() async {
          try {
            if (_deleteDelay != null) {
              await Future.delayed(_deleteDelay!);
            }
            await dirToDelete?.delete(recursive: true);
          } on FileSystemException catch (e) {
            // Avoid race conditions where the file might already be deleted by the OS
            if (!isPathNotFoundException(e)) {
              rethrow;
            }
          }
        }());
      }
    }
  }

  @override
  Future<void> deleteDanglingCache() async {
    final directory = await _fileDir;

    final dirsToDelete = await directory.parent
        .list()
        .where((d) => d.path.endsWith('.remove'))
        .toList();

    if (dirsToDelete.isNotEmpty) {
      final futures = <Future<void>>[];
      for (final dirToDelete in dirsToDelete) {
        futures.add(() async {
          if (await dirToDelete.exists()) {
            try {
              // print("Deleting dangling cache dir: $dirToDelete");
              if (_deleteDelay != null) {
                await Future.delayed(_deleteDelay!);
              }
              await dirToDelete.delete(recursive: true);
            } on FileSystemException catch (e) {
              // Avoid race conditions where the file might already be deleted by the OS
              if (!isPathNotFoundException(e)) {
                rethrow;
              }
            }
          }
        }());
      }

      await Future.wait(futures);
    }
  }
}


