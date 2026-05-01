import 'package:package_info_plus/package_info_plus.dart';

Future<Map<String, String>?> getPackageInfo() async {
  try {
    final info = await PackageInfo.fromPlatform();
    return {
      'appName': info.appName,
      'packageName': info.packageName,
      'version': info.version,
      'buildNumber': info.buildNumber,
    };
  } catch (_) {
    return {'error': 'Failed to fetch package info'};
  }
}
