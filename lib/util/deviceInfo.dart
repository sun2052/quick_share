import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quick_share/util/constant.dart';
import 'package:quick_share/util/utils.dart';

class DeviceInfo {
  DeviceInfo._();

  static Map<String, String> infoMap = {};
  static String deviceId = uuid();
  static String deviceName = 'Unknown Device';
  static int deviceType = DEVICE_UNKNOWN;

  static Future<void> init() async {
    await Permission.manageExternalStorage.request();
    return DeviceInfoPlugin().deviceInfo.then((info) {
      infoMap = info.toMap().map((key, value) => MapEntry(key, value.toString()));
      if (Platform.isWindows || Platform.isMacOS) {
        deviceName = infoMap['computerName']!;
        deviceType = DEVICE_DESKTOP;
      } else if (Platform.isLinux) {
        deviceName = infoMap['name']!;
        deviceType = DEVICE_DESKTOP;
      } else if (Platform.isAndroid) {
        deviceName = "${infoMap['manufacturer']} ${infoMap['model']}";
        deviceType = DEVICE_MOBILE;
      } else if (Platform.isIOS) {
        deviceName = infoMap['utsname.machine']!;
        deviceType = DEVICE_MOBILE;
      }
    });
  }
}
