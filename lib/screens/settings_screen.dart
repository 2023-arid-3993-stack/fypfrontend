import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'fleet_selection_screen.dart';

class SettingsScreen extends StatefulWidget {
  final Robot selectedRobot;
  final Function(int) onTabChanged;

  const SettingsScreen({
    Key? key,
    required this.selectedRobot,
    required this.onTabChanged,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool objectDetection = true;
  bool autoObstacleAvoidance = true;
  bool doorLabelReading = true;
  double maxSpeed = 1.2;
  late TextEditingController _serverIpController;

  @override
  void initState() {
    super.initState();
    _serverIpController = TextEditingController(text: ApiService.baseUrl);
    _loadRobotSettings();
  }

  Future<void> _loadRobotSettings() async {
    final details = await ApiService.fetchRobotDetails(widget.selectedRobot.robotId);
    if (details != null && details['settings'] != null) {
      final s = details['settings'];
      if (mounted) {
        setState(() {
          if (s['max_speed_mps'] != null) {
            maxSpeed = (s['max_speed_mps'] as num).toDouble();
          }
          if (s['object_detection_enabled'] != null) {
            objectDetection = s['object_detection_enabled'] as bool;
          }
          if (s['obstacle_avoidance_enabled'] != null) {
            autoObstacleAvoidance = s['obstacle_avoidance_enabled'] as bool;
          }
          if (s['door_label_reading_enabled'] != null) {
            doorLabelReading = s['door_label_reading_enabled'] as bool;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _serverIpController.dispose();
    super.dispose();
  }

  void _updateSettings() {
    ApiService.updateRobotSettings(widget.selectedRobot.robotId, {
      "max_speed_mps": maxSpeed,
      "object_detection_enabled": objectDetection,
      "obstacle_avoidance_enabled": autoObstacleAvoidance,
      "door_label_reading_enabled": doorLabelReading,
    });
  }

  void _showServerIpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Server / Backend URL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the backend URL (e.g. http://192.168.25.140:8000):',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _serverIpController,
              decoration: InputDecoration(
                hintText: 'http://192.168.x.x:8000',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.wifi_rounded, color: Color(0xFF4F46E5)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final newUrl = _serverIpController.text.trim();
              if (newUrl.isNotEmpty) {
                ApiService.setBaseUrl(newUrl);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Connected URL updated to: $newUrl')),
                );
              }
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Save URL'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
            ),
            Text(
              'firmware ${widget.selectedRobot.firmwareVersion}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ROBOT SECTION
            _sectionHeader('ROBOT'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _settingTile(
                    icon: Icons.smart_toy_rounded,
                    title: 'Robot name',
                    subtitle: 'Currently connected device',
                    trailing: Text(
                      widget.selectedRobot.name,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _settingTile(
                    icon: Icons.bolt_rounded,
                    title: 'Max speed',
                    subtitle: 'Movement limit',
                    trailing: Text(
                      '${maxSpeed.toStringAsFixed(1)} m/s',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const FleetSelectionScreen()),
                      );
                    },
                    child: _settingTile(
                      icon: Icons.swap_horiz_rounded,
                      title: 'Switch robot',
                      subtitle: 'Choose another available device',
                      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 22),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // VISION & NAVIGATION SECTION
            _sectionHeader('VISION & NAVIGATION'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _switchTile(
                    icon: Icons.remove_red_eye_rounded,
                    title: 'Object detection',
                    subtitle: 'YOLOv8 + Distance estimation',
                    value: objectDetection,
                    onChanged: (v) {
                      setState(() => objectDetection = v);
                      _updateSettings();
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _switchTile(
                    icon: Icons.construction_rounded,
                    title: 'Auto obstacle avoidance',
                    subtitle: 'Reroute when blocked',
                    value: autoObstacleAvoidance,
                    onChanged: (v) {
                      setState(() => autoObstacleAvoidance = v);
                      _updateSettings();
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _switchTile(
                    icon: Icons.door_front_door_rounded,
                    title: 'Door label reading',
                    subtitle: 'Recognise room signs',
                    value: doorLabelReading,
                    onChanged: (v) {
                      setState(() => doorLabelReading = v);
                      _updateSettings();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SERVER & NETWORK SECTION
            _sectionHeader('SERVER & NETWORK CONFIGURATION'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _showServerIpDialog,
                    child: _settingTile(
                      icon: Icons.router_rounded,
                      title: 'Backend API URL',
                      subtitle: 'Tap to configure Wi-Fi server host',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            ApiService.baseUrl.replaceFirst('http://', ''),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4F46E5),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit_rounded, color: Color(0xFF4F46E5), size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF94A3B8),
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF4F46E5), size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF4F46E5), size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: const Color(0xFF4F46E5),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(0, Icons.home_rounded, 'Home'),
          _navItem(1, Icons.videocam_rounded, 'Live'),
          _navItem(2, Icons.settings_rounded, 'Settings'),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onTabChanged(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: index == 2 ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8), size: 22),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: index == 2 ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
