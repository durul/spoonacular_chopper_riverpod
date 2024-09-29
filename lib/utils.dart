import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

bool isDesktop() {
  if (kIsWeb) {
    return false;
  }
  return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
}

bool isWeb() {
  return kIsWeb;
}

bool isMobile() {
  if (kIsWeb) {
    // Web-specific mobile detection logic here
    // This could be based on screen size or user agent
    return false; // or implement web-based mobile detection
  }
  // For non-web platforms, use the original logic
  return Platform.isAndroid || Platform.isIOS;
}
