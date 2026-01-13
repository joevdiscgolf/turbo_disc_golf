import 'dart:io';

class PlatformHelpers {
  static bool get isIOS => Platform.isIOS;
  static bool get isAndroid => Platform.isAndroid;

  /// Returns the appropriate store URL based on the current platform.
  /// Returns iOS URL on iOS devices, Android URL on Android devices, or null otherwise.
  static String? getStoreUrl(String? iosUrl, String? androidUrl) {
    if (isIOS) return iosUrl;
    if (isAndroid) return androidUrl;
    return null;
  }
}
