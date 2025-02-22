export 'file_system.dart';
export 'file_system_io.dart';
export 'file_system_web.dart';

import 'package:file/file.dart';

/// FileSystem works in the context of a directory where filenames are stored.
abstract class FileSystem {
  Future<File> createFile(String name);

  /// Deletes the directory that contains all the cached filed in the current context.
  /// Big directories might take a while to delete, so they are marked for deletion renaming them first.
  /// This method should return quickly, but the original directory will be deleted in the background.
  Future<void> deleteCacheDir();

  /// Delete any directories that have been marked for deletion
  Future<void> deleteDanglingDeletedCacheDirs();
}
