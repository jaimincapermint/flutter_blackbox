import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;

import 'blackbox_device_info.dart';

Future<BlackBoxDeviceInfo> fetchPlatformDeviceInfo() async {
  final deviceInfo = DeviceInfoPlugin();
  final connectivity = Connectivity();

  String osVersion = 'Unknown';
  String deviceModel = 'Unknown';
  String? cpuArch;
  int? androidSdkInt;
  int? totalRamMb;

  try {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidInfo = await deviceInfo.androidInfo;
      osVersion =
          'Android ${androidInfo.version.release} (API ${androidInfo.version.sdkInt})';
      deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
      cpuArch = androidInfo.supportedAbis.isNotEmpty
          ? androidInfo.supportedAbis.first
          : null;
      androidSdkInt = androidInfo.version.sdkInt;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosInfo = await deviceInfo.iosInfo;
      osVersion = 'iOS ${iosInfo.systemVersion}';
      deviceModel = iosInfo.name;
    }
  } catch (_) {}

  String netType = 'unknown';
  try {
    final connectivityResult = await connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.wifi)) {
      netType = 'wifi';
    } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
      netType = 'mobile';
    } else if (connectivityResult.contains(ConnectivityResult.ethernet)) {
      netType = 'ethernet';
    } else if (connectivityResult.contains(ConnectivityResult.none)) {
      netType = 'none';
    } else if (connectivityResult.isNotEmpty) {
      netType = connectivityResult.first.name;
    }
  } catch (_) {}

  final views = ui.PlatformDispatcher.instance.views;
  final window = views.isNotEmpty ? views.first : null;
  final size = window != null
      ? window.physicalSize / window.devicePixelRatio
      : const ui.Size(0, 0);
  final pixelRatio = window?.devicePixelRatio ?? 1.0;

  return BlackBoxDeviceInfo(
    platform: defaultTargetPlatform.name,
    osVersion: osVersion,
    deviceModel: deviceModel,
    cpuArch: cpuArch,
    androidSdkInt: androidSdkInt,
    totalRamMb: totalRamMb,
    availableRamMb: null,
    networkType: netType,
    batteryPercent: null,
    isCharging: null,
    locale: ui.PlatformDispatcher.instance.locale.toString(),
    timezone: DateTime.now().timeZoneName,
    screenSize:
        '${size.width.toStringAsFixed(0)}x${size.height.toStringAsFixed(0)} dp',
    pixelRatio: pixelRatio,
    brightness: ui.PlatformDispatcher.instance.platformBrightness.name,
  );
}
