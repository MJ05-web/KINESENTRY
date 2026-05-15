import 'package:flutter/material.dart';

import '../services/audio_device_service.dart';
import '../services/bluetooth_service.dart';
import '../services/data_service.dart';
import '../services/notification_service.dart';
import '../services/session_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/app_footer.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final settings = SettingsService();
  final audioDevices = AudioDeviceService();
  final ble = MyBluetoothService();
  final dataService = DataService();

  bool isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    audioDevices.refresh();
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      await NotificationService().initialize();
    }
    await settings.setNotificationEnabled(value);
  }

  Future<void> _toggleVoice(bool value) async {
    await settings.setSoundEnabled(value);
  }

  Future<void> _toggleSpeaker(bool value) async {
    await settings.setSpeakerEnabled(value);
    await audioDevices.refresh();
  }

  Future<void> _toggleDeepSleep(bool value) async {
    await settings.setDeepSleepEnabled(value);
    if (ble.isEsp32Connected) {
      await ble.writeCommand('SLEEP_MODE:${value ? 1 : 0}');
    }
  }

  Future<void> _toggleTheme(bool value) async {
    await settings.setDarkThemeEnabled(value);
  }

  Future<void> _toggleDummyData(bool value) async {
    await settings.setDummyDataEnabled(value);
    if (value) {
      if (ble.isEsp32Connected) {
        await ble.disconnect();
      }
      dataService.clearAll();
      dataService.startDummyData();
    } else {
      dataService.clearAll();
    }
  }

  Future<void> _logout() async {
    if (isLoggingOut) return;
    setState(() => isLoggingOut = true);
    await SessionService.logout(context);
    if (mounted) {
      setState(() => isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        foregroundColor: AppThemeColors.textPrimary(context),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([settings, audioDevices, dataService]),
        builder: (context, _) {
          return AppChrome(
            padding: const EdgeInsets.all(15),
            safeBottom: true,
            child: ListView(
              children: [
                const AccentHeadline(
                  title: 'System Settings',
                  subtitle: 'Fine-tune visuals, alerts, audio routing, power mode, and test data behavior.',
                ),
                const SizedBox(height: 12),
                GlassPanel(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _settingTile(
                        title: 'Notification Alerts',
                        subtitle: 'Fall-only lock screen and background alert',
                        value: settings.notificationEnabled,
                        onChanged: _toggleNotifications,
                      ),
                      Divider(color: AppThemeColors.border(context)),
                      _settingTile(
                        title: 'Voice Alerts',
                        subtitle: 'Gesture, battery, and fall audio feedback',
                        value: settings.soundEnabled,
                        onChanged: _toggleVoice,
                      ),
                      Divider(color: AppThemeColors.border(context)),
                      _settingTile(
                        title: 'External Speaker',
                        subtitle: audioDevices.isSpeakerConnected
                            ? audioDevices.speakerName
                            : 'Route alerts to connected speaker when available',
                        value: settings.speakerEnabled,
                        onChanged: _toggleSpeaker,
                      ),
                      Divider(color: AppThemeColors.border(context)),
                      _settingTile(
                        title: 'Deep Sleep Mode',
                        subtitle: 'Power saver for glove and hub when the system is idle',
                        value: settings.deepSleepEnabled,
                        onChanged: _toggleDeepSleep,
                      ),
                      Divider(color: AppThemeColors.border(context)),
                      _settingTile(
                        title: 'Dummy Data Stream',
                        subtitle: settings.dummyDataEnabled
                            ? 'Enabled. Real device stream is paused and app uses sample data.'
                            : 'Disabled. App stays blank until real hub data arrives.',
                        value: settings.dummyDataEnabled,
                        onChanged: _toggleDummyData,
                      ),
                      Divider(color: AppThemeColors.border(context)),
                      _settingTile(
                        title: 'Dark Theme',
                        subtitle: 'Switch the full app between dark and light mode',
                        value: settings.darkThemeEnabled,
                        onChanged: _toggleTheme,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                GlassPanel(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        audioDevices.isSpeakerConnected
                            ? Icons.speaker_group
                            : Icons.speaker_group_outlined,
                        color: audioDevices.isSpeakerConnected
                            ? AppThemeColors.success(context)
                            : Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          audioDevices.isSpeakerConnected
                              ? 'Connected: ${audioDevices.speakerName}'
                              : 'No external speaker connected',
                          style: TextStyle(
                            color: audioDevices.isSpeakerConnected
                                ? AppThemeColors.success(context)
                                : AppThemeColors.textTertiary(context),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlassPanel(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Alert feedback now surfaces immediately in-app, then continues with sound, voice, and notifications based on your toggles. External speaker output uses the current connected audio route. Dummy data remains isolated from real hub sessions.',
                    style: TextStyle(
                      color: AppThemeColors.textSecondary(context),
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/team'),
                    icon: const Icon(Icons.groups_2_outlined),
                    label: const Text('Team'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppThemeColors.textPrimary(context),
                      side: BorderSide(color: AppThemeColors.border(context)),
                      backgroundColor: AppThemeColors.panel(context),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: isLoggingOut ? null : _logout,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemeColors.panel(context),
                      foregroundColor: AppThemeColors.textPrimary(context),
                    ),
                  ),
                ),
                const AppFooter(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _settingTile({
    required String title,
    required String subtitle,
    required bool value,
    required Future<void> Function(bool) onChanged,
  }) {
    return SwitchListTile(
      activeColor: AppThemeColors.accent(context),
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(color: AppThemeColors.textPrimary(context)),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppThemeColors.textSecondary(context)),
      ),
      value: value,
      onChanged: (next) => onChanged(next),
    );
  }
}
