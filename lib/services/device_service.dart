import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceService {
  static final DeviceService _instance = DeviceService._internal();

  factory DeviceService() => _instance;

  DeviceService._internal();

  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  Future<String?> getDeviceId() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfoPlugin.androidInfo;
      return androidInfo.id; // Unique Android device ID
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfoPlugin.iosInfo;
      return iosInfo.identifierForVendor; // Unique iOS device ID
    } else if (Platform.isMacOS) {
      final macOsInfo = await _deviceInfoPlugin.macOsInfo;
      return macOsInfo.systemGUID; // macOS version as unique ID
    }

    return null;
  }
}
