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

  final String platform;
  final String osVersion;
  final String deviceModel;
  final String? cpuArch;
  final int? androidSdkInt;
  final int? totalRamMb;
  final int? availableRamMb;
  final String networkType;
  final int? batteryPercent;
  final bool? isCharging;
  final String locale;
  final String timezone;
  final String screenSize;
  final double pixelRatio;
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
