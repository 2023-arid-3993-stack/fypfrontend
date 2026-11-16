import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/voice_service.dart';
import '../widgets/phone_camera_vision_widget.dart';
import 'autonomous_setup_screen.dart';

class ManualControlScreen extends StatefulWidget {
  final Robot selectedRobot;
  final Function(int) onTabChanged;

  const ManualControlScreen({
    Key? key,
    required this.selectedRobot,
    required this.onTabChanged,
  }) : super(key: key);

  @override
  State<ManualControlScreen> createState() => _ManualControlScreenState();
}

class _ManualControlScreenState extends State<ManualControlScreen> {
  double currentSpeed = 0.6;
  bool isEmergencyStop = false;
  String currentMode = 'Manual';

  NavigationGuidance? guidance;
  Timer? _pollTimer;
  final VoiceService _voiceService = VoiceService();

  @override
  void initState() {
    super.initState();
    _fetchGuidance();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) => _fetchGuidance());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchGuidance() async {
    final g = await ApiService.fetchLatestGuidance();
    if (mounted && g != null) {
      setState(() => guidance = g);
      // Only speak via timer if there is an active obstacle alert
      if (_voiceService.isVoiceEnabled && g.recommendedAction != "FORWARD") {
        _voiceService.speak(g.voiceText);
      }
    }
  }

  void _sendDirection(String dir) {
    if (isEmergencyStop) return;
    ApiService.sendMoveCommand(widget.selectedRobot.robotId, dir, currentSpeed);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Drive: $dir ($currentSpeed m/s)'), duration: const Duration(milliseconds: 500)),
    );
  }

  void _triggerEStop() {
    setState(() => isEmergencyStop = true);
    ApiService.triggerEmergencyStop(widget.selectedRobot.robotId);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('EMERGENCY STOP', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        content: const Text('Motor power has been cut. Robot drive system halted immediately.'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => isEmergencyStop = false);
              Navigator.pop(ctx);
            },
            child: const Text('Reset & Resume'),
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
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF0F172A), size: 30),
          onPressed: () => widget.onTabChanged(0), // return to home
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Robot Control',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.4),
            ),
            Text(
              '${widget.selectedRobot.name} · ${widget.selectedRobot.hardware}',
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _voiceService.isVoiceEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: _voiceService.isVoiceEnabled ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
            ),
            tooltip: _voiceService.isVoiceEnabled ? "Mute Voice Guidance" : "Enable Voice Guidance",
            onPressed: () {
              setState(() {
                _voiceService.isVoiceEnabled = !_voiceService.isVoiceEnabled;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_voiceService.isVoiceEnabled ? "Voice Guidance Enabled" : "Voice Guidance Muted"),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '● LIVE',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 6.0),
        child: Column(
          children: [
            // Live Video Feed Container
            _buildLiveVideoView(),
            const SizedBox(height: 6),

            // Live Navigation Decision Card (LEFT / RIGHT / FORWARD / BACKWARD)
            _buildNavigationDecisionBanner(),
            const SizedBox(height: 6),

            // Detected obstacle & distance banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Text('● DETECTED: ', style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
                  Text(
                    '${guidance?.objectClass?.toUpperCase() ?? "PERSON"} ',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${guidance?.confidencePct ?? 94}%',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: Color(0xFF15803D), fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${guidance?.distanceM != null ? guidance!.distanceM!.toStringAsFixed(1) : "2.4"} m',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFEF4444)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Segmented mode switch: Manual | Auto
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Manual',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5)),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AutonomousSetupScreen(selectedRobot: widget.selectedRobot, onTabChanged: widget.onTabChanged),
                          ),
                        );
                      },
                      child: const Center(
                        child: Text(
                          'Auto',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Controls & Telemetry Layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // D-Pad
                _buildDPad(),
                const SizedBox(width: 16),
                // Sliders & Telemetry Tiles
                Expanded(
                  child: Column(
                    children: [
                      // Speed Slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('SPEED', style: TextStyle(fontFamily: 'monospace', fontSize: 8.5, color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
                          Text('${currentSpeed.toStringAsFixed(1)} m/s', style: const TextStyle(fontFamily: 'monospace', fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFF4F46E5),
                          inactiveTrackColor: const Color(0xFFE0E7FF),
                          thumbColor: const Color(0xFF4F46E5),
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                          trackHeight: 5,
                        ),
                        child: Slider(
                          value: currentSpeed,
                          min: 0.2,
                          max: 1.2,
                          divisions: 10,
                          onChanged: (v) => setState(() => currentSpeed = v),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Telemetry Cards
                      Row(
                        children: [
                          Expanded(
                            child: _telemetryTile(
                              title: 'WI-FI',
                              value: '92%',
                              sub: '5GHz',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _telemetryTile(
                              title: 'BOARD',
                              value: widget.selectedRobot.hardware.split('-')[0],
                              sub: 'CAM HD',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Emergency Stop Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE2E2),
                  elevation: 0,
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _triggerEStop,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.stop_rounded, color: Color(0xFFEF4444), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Emergency Stop',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFEF4444)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildLiveVideoView() {
    return PhoneCameraVisionWidget(
      isVoiceEnabled: _voiceService.isVoiceEnabled,
      onGuidanceUpdated: (summary, detections) {
        if (mounted) {
          setState(() {
            final primary = summary["primary"];
            guidance = NavigationGuidance(
              totalObstacles: detections.length,
              objectClass: primary != null ? primary["class"] : null,
              confidencePct: primary != null ? primary["confidence_pct"] : null,
              distanceM: primary != null && primary["distance_m"] != null
                  ? (primary["distance_m"] as num).toDouble()
                  : null,
              safetyStatus: summary["safety_status"] ?? "CLEAR",
              recommendedAction: summary["recommended_action"] ?? "FORWARD",
              instruction: summary["instruction"] ?? "Path is clear. Move Forward.",
              voiceText: summary["voice_text"] ?? "Path clear. Move forward.",
              arrow: summary["arrow"] ?? "^ FORWARD ^",
            );
          });
        }
      },
    );
  }

  Widget _buildNavigationDecisionBanner() {
    final action = guidance?.recommendedAction ?? "FORWARD";
    final instruction = guidance?.instruction ?? "Path is clear. Move Forward.";

    Color bgColor = const Color(0xFFF0FDF4);
    Color borderColor = const Color(0xFFBBF7D0);
    Color textColor = const Color(0xFF15803D);
    IconData actionIcon = Icons.arrow_upward_rounded;

    if (action == "TURN LEFT") {
      bgColor = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFFDE68A);
      textColor = const Color(0xFFB45309);
      actionIcon = Icons.turn_left_rounded;
    } else if (action == "TURN RIGHT") {
      bgColor = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFFDE68A);
      textColor = const Color(0xFFB45309);
      actionIcon = Icons.turn_right_rounded;
    } else if (action == "BACKWARD") {
      bgColor = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFFECACA);
      textColor = const Color(0xFFB91C1C);
      actionIcon = Icons.arrow_downward_rounded;
    }

    return GestureDetector(
      onTap: () {
        _voiceService.speak(guidance?.voiceText ?? instruction, minIntervalSeconds: 1);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: textColor.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(actionIcon, color: textColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'ACTION: $action',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.volume_up_rounded, size: 14, color: textColor),
                      const SizedBox(width: 3),
                      Text(
                        'SPEAK',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    instruction,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: textColor.withValues(alpha: 0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDPad() {
    return SizedBox(
      width: 145,
      height: 145,
      child: Stack(
        children: [
          // UP
          Align(
            alignment: Alignment.topCenter,
            child: _dPadBtn(Icons.arrow_drop_up_rounded, () => _sendDirection('FORWARD')),
          ),
          // LEFT
          Align(
            alignment: Alignment.centerLeft,
            child: _dPadBtn(Icons.arrow_left_rounded, () => _sendDirection('LEFT')),
          ),
          // CENTER STOP
          Align(
            alignment: Alignment.center,
            child: _dPadBtn(Icons.stop_rounded, () => _sendDirection('STOP'), isCenter: true),
          ),
          // RIGHT
          Align(
            alignment: Alignment.centerRight,
            child: _dPadBtn(Icons.arrow_right_rounded, () => _sendDirection('RIGHT')),
          ),
          // DOWN
          Align(
            alignment: Alignment.bottomCenter,
            child: _dPadBtn(Icons.arrow_drop_down_rounded, () => _sendDirection('BACKWARD')),
          ),
        ],
      ),
    );
  }

  Widget _dPadBtn(IconData icon, VoidCallback onTap, {bool isCenter = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isCenter ? const Color(0xFFF1F5F9) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Center(
          child: Icon(icon, color: isCenter ? const Color(0xFF0F172A) : const Color(0xFF475569), size: isCenter ? 18 : 28),
        ),
      ),
    );
  }

  Widget _telemetryTile({required String title, required String value, required String sub}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontFamily: 'monospace', fontSize: 7.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          Text(sub, style: const TextStyle(fontFamily: 'monospace', fontSize: 7.5, color: Color(0xFF64748B))),
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
          Icon(icon, color: index == 1 ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8), size: 22),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: index == 1 ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
