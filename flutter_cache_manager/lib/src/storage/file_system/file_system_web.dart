import 'package:file/file.dart' show File;
import 'package:file/memory.dart';
import 'package:flutter_cache_manager/src/storage/file_system/file_system.dart';

class MemoryCacheSystem implements FileSystem {
  final directory = MemoryFileSystem().systemTempDirectory.createTemp('cache');

  @override
  Future<File> createFile(String name) async {
    return (await directory).childFile(name);
  }

  @override
  Future<void> deleteCacheDir() async {
    final dir = await directory;
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
