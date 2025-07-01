import 'dart:async';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

mixin CacheInfoRepositoryHelperMethods on CacheInfoRepository {
  Completer<bool>? openCompleter;
  bool hasOpened = false;

  bool shouldOpenOnNewConnection() {
    if (openCompleter == null) {
      // print("CacheInfoRepositoryHelperMethods: Creating new completer");
      openCompleter = Completer<bool>();
      return true;
    } else {
      return false;
    }
  }

  bool opened() {
    openCompleter!.complete(true);
    hasOpened = true;
    return true;
  }

  bool shouldClose() {
    hasOpened = false;
    if (openCompleter != null && !openCompleter!.isCompleted) {
      openCompleter?.completeError(Exception('CacheInfoRepository closed while opening'));
    }
    openCompleter = null;

    return true;
  }
}
