import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

Future<String> getDeviceId() async {
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  try {
    if (Platform.isAndroid) {
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id ?? 'Unknown Android ID'; // unique ID on Android
    } else if (Platform.isIOS) {
      final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'Unknown iOS ID'; // unique ID on iOS
    } else {
      return 'Unsupported platform';
    }
  } catch (e) {
    return 'Error retrieving device ID: $e';
  }
}
