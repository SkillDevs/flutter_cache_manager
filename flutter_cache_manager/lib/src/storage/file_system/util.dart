import 'dart:io';

import 'package:file/file.dart';

bool isPathNotFoundException(FileSystemException e) {
  return e is PathNotFoundException ||
      e.osError?.errorCode == ErrorCodes.ENOENT;
}