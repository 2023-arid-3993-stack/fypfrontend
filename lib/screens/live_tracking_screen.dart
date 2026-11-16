import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/voice_service.dart';
import '../widgets/phone_camera_vision_widget.dart';

class LiveTrackingScreen extends StatefulWidget {
  final int missionId;
  final Robot selectedRobot;
  final Function(int) onTabChanged;
  final String pickupName;
  final String dropName;

  const LiveTrackingScreen({
    Key? key,
    required this.missionId,
    required this.selectedRobot,
    required this.onTabChanged,
    required this.pickupName,
    required this.dropName,
  }) : super(key: key);

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  Timer? _pollTimer;
  LiveMissionTelemetry? telemetry;
  final VoiceService _voiceService = VoiceService();

  @override
  void initState() {
    super.initState();
    _fetchLive();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchLive());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLive() async {
    final t = await ApiService.getLiveMission(widget.missionId);
    if (mounted && t != null) {
      setState(() => telemetry = t);
      // Only speak via polling timer when there is an active obstacle alert
      if (_voiceService.isVoiceEnabled && t.recommendedAction != "FORWARD") {
        _voiceService.speak(t.voiceText);
      }
    }
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Live Tracking',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.4),
            ),
            Text(
              '${widget.pickupName} → ${widget.dropName} · autonomous',
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
            const SizedBox(height: 8),

            // Live Navigation Decision Card (LEFT / RIGHT / FORWARD / BACKWARD)
            _buildNavigationDecisionBanner(),
            const SizedBox(height: 10),

            // DETECTED OBSTACLES CARD
            _buildObstacleCard(),
            const SizedBox(height: 12),

            // ROUTE PROGRESS CARD
            _buildRouteProgressCard(),
            const SizedBox(height: 12),

            // CURRENT POSITION CARD
            _buildCurrentPositionCard(),
            const SizedBox(height: 16),
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
            if (telemetry != null) {
              final primary = summary["primary"];
              telemetry = LiveMissionTelemetry(
                missionId: telemetry!.missionId,
                robotId: telemetry!.robotId,
                status: telemetry!.status,
                pickup: telemetry!.pickup,
                drop: telemetry!.drop,
                totalDistanceM: telemetry!.totalDistanceM,
                distanceSoFarM: telemetry!.distanceSoFarM,
                speedMps: telemetry!.speedMps,
                etaSeconds: telemetry!.etaSeconds,
                positionNote: telemetry!.positionNote,
                safetyStatus: summary["safety_status"] ?? telemetry!.safetyStatus,
                closestDistanceM: (summary["closest_distance_m"] as num?)?.toDouble() ?? telemetry!.closestDistanceM,
                primaryObstacleClass: primary != null ? primary["class"] : telemetry!.primaryObstacleClass,
                primaryConfidence: primary != null ? primary["confidence_pct"] : telemetry!.primaryConfidence,
                recommendedAction: summary["recommended_action"] ?? telemetry!.recommendedAction,
                instruction: summary["instruction"] ?? telemetry!.instruction,
                voiceText: summary["voice_text"] ?? telemetry!.voiceText,
              );
            }
          });
        }
      },
    );
  }

  Widget _buildNavigationDecisionBanner() {
    final action = telemetry?.recommendedAction ?? "FORWARD";
    final instruction = telemetry?.instruction ?? "Path is clear. Move Forward.";

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
        _voiceService.speak(telemetry?.voiceText ?? instruction, minIntervalSeconds: 1);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
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
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(actionIcon, color: textColor, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'STEER: $action',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
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
                      fontSize: 11.5,
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

  Widget _buildObstacleCard() {
    final obstacleName = telemetry?.primaryObstacleClass?.toUpperCase() ?? "PERSON";
    final confidence = telemetry?.primaryConfidence ?? 94;
    final dist = telemetry?.closestDistanceM != null ? telemetry!.closestDistanceM!.toStringAsFixed(1) : "2.4";

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  CircleAvatar(radius: 3.5, backgroundColor: Color(0xFFEF4444)),
                  SizedBox(width: 6),
                  Text('DETECTED OBSTACLES', style: TextStyle(fontFamily: 'monospace', fontSize: 8.5, color: Color(0xFF64748B), fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(4)),
                child: const Text('● 1 IN PATH', style: TextStyle(fontFamily: 'monospace', fontSize: 8, color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Obstacle card
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: const Color(0xFFFFEDD5), borderRadius: BorderRadius.circular(10)),
                  child: const Center(child: Text('🚶', style: TextStyle(fontSize: 18))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('$obstacleName ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(3)),
                            child: Text('$confidence% Match', style: const TextStyle(fontFamily: 'monospace', fontSize: 8.5, color: Color(0xFF15803D), fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text('Corridor pathway · Real-time tracking', style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('DISTANCE', style: TextStyle(fontFamily: 'monospace', fontSize: 7, color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
                    Text(
                      '$dist m',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFEF4444)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3 sub metrics: AI MODEL | SAFETY ZONE | AVOIDANCE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI MODEL', style: TextStyle(fontFamily: 'monospace', fontSize: 7.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
                  SizedBox(height: 2),
                  Text('YOLOv8', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('SAFETY ZONE', style: TextStyle(fontFamily: 'monospace', fontSize: 7.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    telemetry?.safetyStatus ?? 'CAUTION (2.4 m)',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFD97706)),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('AVOIDANCE', style: TextStyle(fontFamily: 'monospace', fontSize: 7.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    telemetry?.recommendedAction == 'FORWARD' ? 'AUTO ACTIVE' : 'STEER ${telemetry?.recommendedAction}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteProgressCard() {
    final totalDist = telemetry?.totalDistanceM ?? 70;
    final distSoFar = telemetry?.distanceSoFarM ?? 0;
    final progress = totalDist > 0 ? (distSoFar / totalDist).clamp(0.0, 1.0) : 0.0;
    final etaSec = telemetry?.etaSeconds ?? 0;
    final speed = telemetry?.speedMps ?? 0.6;
    final etaStr = "${etaSec ~/ 60}:${(etaSec % 60).toString().padLeft(2, '0')}";

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.pickupName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              Text(widget.dropName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFEEF2FF),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('DIST $totalDist m', style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
              Text('ETA $etaStr', style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
              Text('${speed.toStringAsFixed(1)} m/s', style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPositionCard() {
    final posNote = telemetry?.positionNote ?? "Main Path · En route to ${widget.dropName}";
    final safety = telemetry?.safetyStatus ?? "CLEAR";
    final isClear = safety == "CLEAR";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CURRENT POSITION',
            style: TextStyle(fontFamily: 'monospace', fontSize: 8, color: Color(0xFF94A3B8), fontWeight: FontWeight.w700, letterSpacing: 0.8),
          ),
          const SizedBox(height: 4),
          Text(
            posNote,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 2),
          Text(
            isClear ? 'Corridor clear · Autonomous tracking active' : 'Safety alert: Obstacle in corridor zone',
            style: TextStyle(fontSize: 10.5, color: isClear ? const Color(0xFF15803D) : const Color(0xFFEF4444), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF15803D), size: 16),
                  label: const Text('Complete Mission', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFBBF7D0)),
                    backgroundColor: const Color(0xFFF0FDF4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    await ApiService.completeMission(widget.missionId, status: "SUCCESS");
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Mission Completed Successfully! Logged in Database.')),
                      );
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.stop_circle_rounded, color: Color(0xFFEF4444), size: 16),
                  label: const Text('Abort Mission', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    backgroundColor: const Color(0xFFFEF2F2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    await ApiService.completeMission(widget.missionId, status: "STOPPED");
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Mission Aborted. Recorded in History.')),
                      );
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ],
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
      onTap: () {
        Navigator.popUntil(context, (r) => r.isFirst);
        widget.onTabChanged(index);
      },
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
