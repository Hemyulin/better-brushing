import 'dart:async';

import 'package:flutter/services.dart';

class VolumeButtonService {
  VolumeButtonService._() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  static final VolumeButtonService instance = VolumeButtonService._();
  static const MethodChannel _channel = MethodChannel(
    'better_brushing/volume_buttons',
  );

  final StreamController<void> _presses = StreamController<void>.broadcast();

  Stream<void> get presses => _presses.stream;

  Future<void> setEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod<void>('setEnabled', enabled);
    } on MissingPluginException {
      // Desktop/web builds do not expose Android volume keys.
    }
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'volumeButtonPressed') {
      _presses.add(null);
    }
  }
}
