import 'package:audio_session/audio_session.dart';

class AudioDeviceService {

  static Future<bool> isBluetoothConnected() async {
    final session = await AudioSession.instance;

    final devices = await session.getDevices();

    for (var device in devices) {
      if (device.type.toString().contains("bluetooth")) {
        return true;
      }
    }

    return false;
  }
}