import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/bluetooth_service.dart';
import '../services/data_service.dart';
import '../services/parser.dart';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {

  final MyBluetoothService ble = MyBluetoothService();
  final DataService dataService = DataService();

  late Stream<List<ScanResult>> scanStream;
  bool isConnecting = false;
  BluetoothDevice? connectedDevice;
  

  @override
  void initState() {
    super.initState();
    scanStream = ble.scanDevices();
  }

  @override
  void dispose() {
    ble.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1C),

      appBar: AppBar(
        title: const Text("Bluetooth Devices"),
        backgroundColor: const Color(0xFF0A0F1C),
      ),

      body: StreamBuilder<List<ScanResult>>(
        stream: scanStream,
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final devices = snapshot.data!;

          // 🔥 REMOVE DUPLICATES
          final uniqueDevices = {
            for (var d in devices) d.device.id: d
          }.values.toList();

          if (uniqueDevices.isEmpty) {
            return const Center(
              child: Text("No Devices Found",
                  style: TextStyle(color: Colors.white)),
            );
          }

          return ListView.builder(
            itemCount: uniqueDevices.length,
            itemBuilder: (context, index) {

              final device = uniqueDevices[index].device;

              return Card(
                color: const Color(0xFF121A2F),
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(
                    device.name.isNotEmpty
                        ? device.name
                        : "Unknown Device",
                    style: const TextStyle(color: Colors.white),
                  ),

                  subtitle: Text(
                    device.id.toString(),
                    style: const TextStyle(color: Colors.white54),
                  ),

                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: isConnecting
                        ? const SizedBox(
                            height: 15,
                            width: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Connect"),

                    onPressed: isConnecting ? null : () async {

                      setState(() => isConnecting = true);

                      try {
                        await ble.connect(device);

                        // ✅ SAVE DEVICE
                        connectedDevice = device;

                        // 🔥 START SESSION (IMPORTANT)
                        dataService.startSession();

                        // 🔥 LISTEN DATA
                        ble.listenToDevice(device, (data) {

                          print("RAW DATA: $data");

                          final parsed = parseData(data);

                         dataService.updateData(parsed, context);

                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Connected")),
                        );

                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error: $e")),
                        );
                      }

                      setState(() => isConnecting = false);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),

      // 🔥 DISCONNECT BUTTON (NEW FEATURE)
      floatingActionButton: connectedDevice != null
          ? FloatingActionButton(
              backgroundColor: Colors.red,
              child: const Icon(Icons.close),
              onPressed: () async {

                try {
                  await connectedDevice!.disconnect();

                  // 🔥 STOP SESSION
                  dataService.stopSession();

                  connectedDevice = null;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Disconnected")),
                  );

                  setState(() {});
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e")),
                  );
                }
              },
            )
          : null,
    );
  }
}