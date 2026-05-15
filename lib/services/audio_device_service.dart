import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';

class AudioDeviceService extends ChangeNotifier {
  static final AudioDeviceService _instance = AudioDeviceService._internal();
  factory AudioDeviceService() => _instance;
  AudioDeviceService._internal();

  StreamSubscription<Set<AudioDevice>>? _devicesSubscription;
  bool _initialized = false;

  bool isSpeakerConnected = false;
  String speakerName = 'No external speaker';

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    await _refresh(session);

    _devicesSubscription = session.devicesStream.listen((devices) {
      _updateFromDevices(devices);
    });
  }

  Future<void> refresh() async {
    final session = await AudioSession.instance;
    await _refresh(session);
  }

  Future<void> _refresh(AudioSession session) async {
    final devices = await session.getDevices();
    _updateFromDevices(devices);
  }

  void _updateFromDevices(Set<AudioDevice> devices) {
    final output = devices.where((device) => device.isOutput).toList();

    final external = output.cast<AudioDevice?>().firstWhere(
      (device) => device != null && _isExternal(device),
      orElse: () => null,
    );

    isSpeakerConnected = external != null;
    speakerName = external?.name ?? 'No external speaker';
    notifyListeners();
  }

  bool _isExternal(AudioDevice device) {
    final type = device.type.toString().toLowerCase();
    return type.contains('bluetooth') ||
        type.contains('headset') ||
        type.contains('headphones') ||
        type.contains('line') ||
        type.contains('usb');
  }

  @override
  void dispose() {
    _devicesSubscription?.cancel();
    super.dispose();
  }
}
