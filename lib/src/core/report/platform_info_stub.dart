import 'blackbox_device_info.dart';

Future<BlackBoxDeviceInfo> fetchPlatformDeviceInfo() async {
  return BlackBoxDeviceInfo(
    platform: 'web',
    osVersion: 'Unknown',
    deviceModel: 'Browser',
    networkType: 'unknown',
    locale: 'Unknown',
    timezone: 'Unknown',
    screenSize: 'Unknown',
    pixelRatio: 1.0,
    brightness: 'Unknown',
  );
}
