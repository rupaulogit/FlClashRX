import 'dart:async';

class AutoLaunch {
  factory AutoLaunch() {
    _instance ??= AutoLaunch._internal();
    return _instance!;
  }

  AutoLaunch._internal();
  static AutoLaunch? _instance;

  Future<bool> get isEnable async => false;

  Future<bool> enable() async => false;

  Future<bool> disable() async => false;

  Future<void> updateStatus(bool isAutoLaunch) async {}
}

final autoLaunch = AutoLaunch();
