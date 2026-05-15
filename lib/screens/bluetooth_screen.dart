import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../services/audio_device_service.dart';
import '../services/bluetooth_service.dart';
import '../services/data_service.dart';
import '../services/parser.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen>
    with SingleTickerProviderStateMixin {
  final ble = MyBluetoothService();
  final dataService = DataService();
  final settings = SettingsService();
  final audioDevices = AudioDeviceService();
  late final AnimationController _radarController;
  bool _speakerRequestHandled = false;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    await ble.startScan();
  }

  Future<void> _connect(BluetoothDevice device) async {
    try {
      await ble.connect(device);
      dataService.clearAll();
      dataService.stopDummy();
      dataService.startSession();

      await ble.listenToDevice(device, (raw) {
        final parsed = parseData(raw);
        final speakerRequest = (parsed['speaker_request'] ?? 0).toInt();
        if (speakerRequest == 1 && !_speakerRequestHandled) {
          _speakerRequestHandled = true;
          settings.setSpeakerEnabled(true);
          audioDevices.refresh().then((_) async {
            if (audioDevices.isSpeakerConnected) {
              await ble.writeCommand('SPEAKER_ACK:1');
            } else {
              await ble.writeCommand('SPEAKER_ACK:0');
            }
          });
        } else if (speakerRequest == 0) {
          _speakerRequestHandled = false;
        }
        dataService.updateData(parsed);
      });

      await ble.writeCommand(
        'SLEEP_MODE:${settings.deepSleepEnabled ? 1 : 0}',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ESP32 connection done: ${ble.connectedDeviceName}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection failed: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _disconnect() async {
    await ble.disconnect();
    dataService.stopSession();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ESP32 hub disconnected'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([ble, ble.scanResults]),
      builder: (context, _) {
        final uniqueDevices = {
          for (final result in ble.scanResults.value)
            result.device.remoteId: result,
        }.values.toList()
          ..sort((a, b) {
            final aScore = _deviceScore(a.device);
            final bScore = _deviceScore(b.device);
            return bScore.compareTo(aScore);
          });

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Bluetooth Hub'),
            centerTitle: true,
            foregroundColor: AppThemeColors.textPrimary(context),
          ),
          body: AppChrome(
            padding: const EdgeInsets.all(15),
            safeBottom: true,
            child: Column(
              children: [
                const AccentHeadline(
                  title: 'Hub Pairing',
                  subtitle: 'Scan, connect, and confirm link quality with a calmer Bluetooth workflow.',
                ),
                const SizedBox(height: 18),
                _connectionBanner(),
                const SizedBox(height: 18),
                _radarPanel(),
                const SizedBox(height: 18),
                _scanButton(),
                const SizedBox(height: 18),
                Expanded(
                  child: uniqueDevices.isEmpty
                      ? _emptyState()
                      : ListView.builder(
                          itemCount: uniqueDevices.length,
                          itemBuilder: (context, index) {
                            final device = uniqueDevices[index].device;
                            final name = _deviceName(device);
                            final matchedHub = _deviceScore(device) > 0;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: GlassPanel(
                                padding: const EdgeInsets.all(12),
                                borderColor: matchedHub
                                    ? const Color(0xFF22C55E)
                                    : AppThemeColors.border(context),
                                glowColor: matchedHub
                                    ? const Color(0x3322C55E)
                                    : const Color(0x221E78FF),
                              child: Row(
                                children: [
                                  Icon(
                                    matchedHub ? Icons.hub : Icons.memory,
                                    color: matchedHub
                                        ? const Color(0xFF22C55E)
                                        : Colors.blue,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: TextStyle(
                                            color: AppThemeColors.textPrimary(context),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          matchedHub
                                              ? 'ESP32 hub candidate'
                                              : device.remoteId.toString(),
                                          style: TextStyle(
                                            color: AppThemeColors
                                                .textSecondary(context),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: ble.isConnecting
                                        ? null
                                        : () => _connect(device),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: matchedHub
                                          ? const Color(0xFF16A34A)
                                          : Colors.blue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: ble.isConnecting
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Connect'),
                                  ),
                                ],
                              ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          floatingActionButton: ble.isEsp32Connected
              ? FloatingActionButton(
                  backgroundColor: Colors.red,
                  onPressed: _disconnect,
                  child: const Icon(Icons.link_off),
                )
              : null,
        );
      },
    );
  }

  Widget _connectionBanner() {
    final connected = ble.isEsp32Connected;
    return GlassPanel(
      padding: const EdgeInsets.all(14),
      borderColor: connected
          ? const Color(0xFF22C55E)
          : AppThemeColors.border(context),
      glowColor: connected ? const Color(0x3322C55E) : const Color(0x2206B6D4),
      child: Row(
        children: [
          Icon(
            connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
            color: connected ? const Color(0xFF22C55E) : Colors.grey,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connected ? 'Connected' : 'Disconnected',
                  style: TextStyle(
                    color: connected
                        ? const Color(0xFF22C55E)
                        : AppThemeColors.textSecondary(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  connected
                      ? 'ESP32 connection done with ${ble.connectedDeviceName}'
                      : 'Press scan to search for the ESP32 hub',
                  style: TextStyle(
                    color: AppThemeColors.textSecondary(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _radarPanel() {
    final connected = ble.isEsp32Connected;
    return GlassPanel(
      borderRadius: 28,
      padding: const EdgeInsets.all(8),
      glowColor: const Color(0x3322C55E),
      child: SizedBox(
        width: 180,
        height: 180,
        child: connected
            ? _connectedPanel()
            : AnimatedBuilder(
                animation: _radarController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _GridRadarPainter(progress: _radarController.value),
                    child: const SizedBox.expand(),
                  );
                },
              ),
      ),
    );
  }

  Widget _connectedPanel() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: .18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bluetooth_connected,
              color: Color(0xFF22C55E),
              size: 30,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Connected',
            style: TextStyle(
              color: Color(0xFF22C55E),
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              ble.connectedDeviceName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scanButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: ble.isScanning || ble.isEsp32Connected ? null : _scan,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF121A2F),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
        icon: Icon(
          ble.isScanning ? Icons.radar : Icons.bluetooth_searching_rounded,
        ),
        label: Text(
          ble.isEsp32Connected
              ? 'ESP32 CONNECTED'
              : ble.isScanning
              ? 'SCANNING FOR ESP32...'
              : 'SCAN',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return GlassPanel(
      padding: const EdgeInsets.all(18),
      child: Text(
        'No device listed yet. Press SCAN and bring the hub close to the phone.',
        style: TextStyle(color: AppThemeColors.textSecondary(context)),
      ),
    );
  }

  int _deviceScore(BluetoothDevice device) {
    final name = _deviceName(device).toLowerCase();
    if (name.contains('esp32') ||
        name.contains('hub') ||
        name.contains('kinesentry')) {
      return 2;
    }
    return 0;
  }

  String _deviceName(BluetoothDevice device) {
    if (device.platformName.isNotEmpty) return device.platformName;
    if (device.advName.isNotEmpty) return device.advName;
    return 'Unknown Device';
  }
}

class _GridRadarPainter extends CustomPainter {
  const _GridRadarPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const dotGap = 16.0;
    final dotPaint = Paint()..color = const Color(0xFF14532D);
    final brightDotPaint = Paint()..color = const Color(0xFF22C55E);
    final lineProgress = progress < 0.5 ? progress * 2 : (1 - progress) * 2;
    final lineX = lineProgress * size.width;

    for (double x = 8; x < size.width; x += dotGap) {
      for (double y = 8; y < size.height; y += dotGap) {
        final isNearSweep = (x - lineX).abs() < 22;
        canvas.drawCircle(
          Offset(x, y),
          isNearSweep ? 1.8 : 1.2,
          isNearSweep ? brightDotPaint : dotPaint,
        );
      }
    }

    final sweepRect = Rect.fromLTWH(lineX - 14, 0, 28, size.height);
    final sweepPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0x0022C55E),
          const Color(0xAA22C55E),
          const Color(0x0022C55E),
        ],
      ).createShader(sweepRect);

    canvas.drawRect(sweepRect, sweepPaint);
    canvas.drawLine(
      Offset(lineX, 0),
      Offset(lineX, size.height),
      Paint()
        ..color = const Color(0xFF4ADE80)
        ..strokeWidth = 2.2,
    );

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFF166534),
    );
  }

  @override
  bool shouldRepaint(covariant _GridRadarPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
