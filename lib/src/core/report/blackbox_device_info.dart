/// Technical snapshot of the device hardware and software environment.
class BlackBoxDeviceInfo {
  BlackBoxDeviceInfo({
    required this.platform,
    required this.osVersion,
    required this.deviceModel,
    this.cpuArch,
    this.androidSdkInt,
    this.totalRamMb,
    this.availableRamMb,
    required this.networkType,
    this.batteryPercent,
    this.isCharging,
    required this.locale,
    required this.timezone,
    required this.screenSize,
    required this.pixelRatio,
    required this.brightness,
  });

  /// Operating system name (e.g., 'android', 'ios').
  final String platform;

  /// OS version number or build string.
  final String osVersion;

  /// Marketing name or model number of the device.
  final String deviceModel;

  /// Processor architecture (e.g., 'arm64', 'x86_64').
  final String? cpuArch;

  /// Android API level (null on other platforms).
  final int? androidSdkInt;

  /// Total system RAM in Megabytes.
  final int? totalRamMb;

  /// Currently unused RAM in Megabytes.
  final int? availableRamMb;

  /// Connectivity status (e.g., 'wifi', 'mobile').
  final String networkType;

  /// Current battery level from 0 to 100.
  final int? batteryPercent;

  /// Whether the device is currently plugged in.
  final bool? isCharging;

  /// Active BCP47 locale code (e.g., 'en_US').
  final String locale;

  /// Canonical timezone identifier (e.g., 'America/New_York').
  final String timezone;

  /// Display dimensions in logical pixels (e.g., '390x844').
  final String screenSize;

  /// Number of physical pixels per logical pixel.
  final double pixelRatio;

  /// System appearance setting ('dark' or 'light').
  final String brightness;

  Map<String, String> toJson() {
    return {
      'platform': platform,
      'osVersion': osVersion,
      'deviceModel': deviceModel,
      if (cpuArch != null) 'cpuArch': cpuArch!,
      if (androidSdkInt != null) 'androidSdkInt': androidSdkInt.toString(),
      if (totalRamMb != null) 'totalRamMb': totalRamMb.toString(),
      if (availableRamMb != null) 'availableRamMb': availableRamMb.toString(),
      'networkType': networkType,
      if (batteryPercent != null) 'batteryPercent': batteryPercent.toString(),
      if (isCharging != null) 'isCharging': isCharging.toString(),
      'locale': locale,
      'timezone': timezone,
      'screenSize': screenSize,
      'pixelRatio': pixelRatio.toString(),
      'brightness': brightness,
    };
  }
}
