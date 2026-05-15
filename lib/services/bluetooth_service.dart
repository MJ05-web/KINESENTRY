import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class MyBluetoothService extends ChangeNotifier {
  static final MyBluetoothService _instance = MyBluetoothService._internal();
  factory MyBluetoothService() => _instance;
  MyBluetoothService._internal();

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  final List<StreamSubscription<List<int>>> _notifySubscriptions = [];
  BluetoothCharacteristic? _writeCharacteristic;

  final ValueNotifier<List<ScanResult>> scanResults =
      ValueNotifier<List<ScanResult>>([]);

  BluetoothDevice? connectedDevice;
  bool isScanning = false;
  bool isConnecting = false;
  bool isEsp32Connected = false;
  String connectedDeviceName = 'Hub disconnected';

  Future<void> startScan() async {
    await stopScan();
    isScanning = true;
    notifyListeners();

    scanResults.value = [];
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      final filtered = results
          .where(
            (result) =>
                result.device.platformName.isNotEmpty ||
                result.advertisementData.advName.isNotEmpty,
          )
          .toList();
      scanResults.value = filtered;
      notifyListeners();
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));
    isScanning = false;
    notifyListeners();
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    isScanning = false;
    notifyListeners();
  }

  Future<void> connect(BluetoothDevice device) async {
    isConnecting = true;
    notifyListeners();

    try {
      await device.connect(timeout: const Duration(seconds: 15));
    } finally {
      isConnecting = false;
    }

    connectedDevice = device;
    connectedDeviceName = _deviceName(device);
    isEsp32Connected = true;
    notifyListeners();

    await _connectionSubscription?.cancel();
    _connectionSubscription = device.connectionState.listen((state) {
      isEsp32Connected = state == BluetoothConnectionState.connected;
      if (!isEsp32Connected) {
        connectedDevice = null;
        connectedDeviceName = 'Hub disconnected';
      }
      notifyListeners();
    });
  }

  Future<void> disconnect() async {
    await stopScan();
    for (final subscription in _notifySubscriptions) {
      await subscription.cancel();
    }
    _notifySubscriptions.clear();
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;

    final device = connectedDevice;
    if (device != null) {
      await device.disconnect();
    }

    connectedDevice = null;
    connectedDeviceName = 'Hub disconnected';
    isEsp32Connected = false;
    _writeCharacteristic = null;
    notifyListeners();
  }

  Future<void> listenToDevice(
    BluetoothDevice device,
    void Function(String) onDataReceived,
  ) async {
    final services = await device.discoverServices();

    for (final service in services) {
      for (final characteristic in service.characteristics) {
        if (characteristic.properties.notify) {
          await characteristic.setNotifyValue(true);
          final subscription = characteristic.lastValueStream.listen((value) {
            final data = String.fromCharCodes(value);
            onDataReceived(data);
          });
          _notifySubscriptions.add(subscription);
        }

        if (_writeCharacteristic == null &&
            (characteristic.properties.write ||
                characteristic.properties.writeWithoutResponse)) {
          _writeCharacteristic = characteristic;
        }
      }
    }
  }

  Future<void> writeCommand(String command) async {
    final characteristic = _writeCharacteristic;
    if (characteristic == null) return;

    await characteristic.write(
      command.codeUnits,
      withoutResponse: characteristic.properties.writeWithoutResponse,
    );
  }

  String _deviceName(BluetoothDevice device) {
    if (device.platformName.isNotEmpty) return device.platformName;
    if (device.advName.isNotEmpty) return device.advName;
    return 'ESP32 Hub';
  }
}
