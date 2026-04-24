import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/audio_device_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  final settings = SettingsService();

  bool isSpeakerConnected = false;

  @override
  void initState() {
    super.initState();
    checkSpeaker();
  }

  void checkSpeaker() async {
    bool status = await AudioDeviceService.isBluetoothConnected();
    setState(() {
      isSpeakerConnected = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1C),

      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: const Color(0xFF0A0F1C),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Controls",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // 🔔 NOTIFICATION
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Notification Alerts",
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text("Fall / Low SpO2 alerts",
                  style: TextStyle(color: Colors.white54)),
              value: settings.notificationEnabled,
              onChanged: (val) {
                setState(() => settings.notificationEnabled = val);
              },
            ),

            const Divider(color: Colors.white10),

            // 🔊 VOICE
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Voice Alerts (Phone)",
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text("Gesture voice on phone",
                  style: TextStyle(color: Colors.white54)),
              value: settings.soundEnabled,
              onChanged: (val) {
                setState(() => settings.soundEnabled = val);
              },
            ),

            const Divider(color: Colors.white10),

            // 🔈 SPEAKER
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("External Speaker",
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text("Play sound via Bluetooth device",
                  style: TextStyle(color: Colors.white54)),
              value: settings.speakerEnabled,
              onChanged: (val) {
                setState(() => settings.speakerEnabled = val);
                checkSpeaker(); // 🔥 refresh status
              },
            ),

            // 🔥 SPEAKER STATUS (NEW FEATURE)
            Row(
              children: [
                Icon(
                  isSpeakerConnected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled,
                  color: isSpeakerConnected ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 5),
                Text(
                  isSpeakerConnected
                      ? "Speaker Connected"
                      : "Not Connected",
                  style: TextStyle(
                    color: isSpeakerConnected ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 5),

            // 🔥 SPEAKER NOTE
            const Padding(
              padding: EdgeInsets.only(left: 2, bottom: 10),
              child: Text(
                "Note: Connect Bluetooth speaker from phone settings.",
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),

            const SizedBox(height: 25),

            // 🔥 INFO BOX
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF121A2F),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Tip: Turn OFF voice for silent monitoring mode.\nTurn ON speaker to use external audio device.",
                style: TextStyle(color: Colors.white54),
              ),
            ),

          ],
        ),
      ),
    );
  }
}