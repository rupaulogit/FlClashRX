import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceDetails {
  final String? hwid;
  final String? os;
  final String? osVersion;
  final String? model;

  DeviceDetails({this.hwid, this.os, this.osVersion, this.model});
}

class DeviceInfoService {
  Future<DeviceDetails> getDeviceDetails() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return DeviceDetails(
          hwid: androidInfo.id,
          os: 'android',
          osVersion: 'Android ${androidInfo.version.release}',
          model: androidInfo.model,
        );
      }
      return DeviceDetails();
    } catch (e) {
      return DeviceDetails();
    }
  }
}
