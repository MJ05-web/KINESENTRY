import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class MyBluetoothService {

  // 🔍 Scan
  Stream<List<ScanResult>> scanDevices() {

    FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 5),
    );

    return FlutterBluePlus.scanResults;
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
  }

  // 🔗 Connect
  Future<void> connect(BluetoothDevice device) async {
    await device.connect();
  }

  // 📡 Listen data
  Future<void> listenToDevice(
      BluetoothDevice device,
      Function(String) onDataReceived) async {

    final services = await device.discoverServices();

    for (var service in services) {
      for (var char in service.characteristics) {

        if (char.properties.notify) {
          await char.setNotifyValue(true);

          char.value.listen((value) {
            final data = String.fromCharCodes(value);
            onDataReceived(data);
          });
        }
      }
    }
  }
}