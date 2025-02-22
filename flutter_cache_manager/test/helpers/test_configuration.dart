import 'package:file/memory.dart';
import 'package:flutter_cache_manager/src/config/config.dart';
import 'package:flutter_cache_manager/src/storage/file_system/file_system.dart';

import 'mock_cache_info_repository.dart';
import 'mock_file_service.dart';

Config createTestConfig() {
  return Config(
    'test',
    fileSystem: createTestFileSystem(),
    repo: MockCacheInfoRepository(),
    fileService: MockFileService(),
  );
}

IOFileSystem createTestFileSystem() => IOFileSystem(
      Future.value(MemoryFileSystem().systemTempDirectory.createTemp('test')),
      // Memory file system, so we cannot use isolates, as they don't share memory
      useIsolates: false,
      deleteDelay: const Duration(milliseconds: 500),
    );
