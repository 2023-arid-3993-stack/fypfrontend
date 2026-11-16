import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class FleetSelectionScreen extends StatefulWidget {
  const FleetSelectionScreen({Key? key}) : super(key: key);

  @override
  State<FleetSelectionScreen> createState() => _FleetSelectionScreenState();
}

class _FleetSelectionScreenState extends State<FleetSelectionScreen> {
  List<Robot> robots = [];
  int selectedRobotId = 1;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRobots();
  }

  Future<void> _loadRobots() async {
    final list = await ApiService.fetchRobots();
    setState(() {
      robots = list;
      isLoading = false;
      if (robots.isNotEmpty) {
        final firstAvail = robots.firstWhere(
          (r) => r.status == 'AVAILABLE',
          orElse: () => robots.first,
        );
        selectedRobotId = firstAvail.robotId;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedRobot = robots.firstWhere(
      (r) => r.robotId == selectedRobotId,
      orElse: () => Robot(robotId: 1, name: "Alpha", hardware: "ESP32-CAM", firmwareVersion: "2.4.1", status: "AVAILABLE", batteryPct: 82, currentLocationName: "Lab 7"),
    );

    final availableRobots = robots.where((r) => r.status == 'AVAILABLE').toList();
    final busyOfflineRobots = robots.where((r) => r.status != 'AVAILABLE').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Available Robots',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${robots.length} devices detected · ${availableRobots.length} available',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
                    : robots.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.wifi_off_rounded, size: 54, color: Color(0xFF94A3B8)),
                                const SizedBox(height: 12),
                                const Text(
                                  'No Robots Connected',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Make sure backend is running at:\n${ApiService.baseUrl}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4F46E5),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () {
                                    setState(() => isLoading = true);
                                    _loadRobots();
                                  },
                                  icon: const Icon(Icons.refresh_rounded, size: 18),
                                  label: const Text('Retry Connection'),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            children: [
                              if (availableRobots.isNotEmpty) ...[
                                const Text(
                                  'AVAILABLE NOW',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF94A3B8),
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ...availableRobots.map((robot) => _buildRobotCard(robot, isAvailable: true)),
                              ],
                              const SizedBox(height: 20),
                              if (busyOfflineRobots.isNotEmpty) ...[
                                const Text(
                                  'BUSY / OFFLINE',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF94A3B8),
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ...busyOfflineRobots.map((robot) => _buildRobotCard(robot, isAvailable: false)),
                              ],
                            ],
                          ),
              ),

              // Connect Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedRobot.status == 'AVAILABLE'
                        ? const Color(0xFF4F46E5)
                        : (selectedRobot.status == 'BUSY' ? const Color(0xFFD97706) : const Color(0xFF94A3B8)),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: selectedRobot.status == 'OFFLINE'
                      ? null
                      : () async {
                          final nav = Navigator.of(context);
                          if (selectedRobot.status == 'BUSY') {
                            await ApiService.releaseRobot(selectedRobot.robotId);
                          }
                          if (mounted) {
                            nav.pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => HomeScreen(selectedRobot: selectedRobot),
                              ),
                            );
                          }
                        },
                  child: Text(
                    selectedRobot.status == 'OFFLINE'
                        ? '${selectedRobot.name.replaceAll("VisionBot · ", "").replaceAll("VisionBot ", "")} is Offline'
                        : (selectedRobot.status == 'BUSY'
                            ? 'Release & Connect to ${selectedRobot.name.replaceAll("VisionBot · ", "").replaceAll("VisionBot ", "")}'
                            : 'Connect to ${selectedRobot.name.replaceAll("VisionBot · ", "").replaceAll("VisionBot ", "")}'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'SELECT A ROBOT TO CONTINUE',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 8.5,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRobotCard(Robot robot, {required bool isAvailable}) {
    final isSelected = selectedRobotId == robot.robotId;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRobotId = robot.robotId;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? const Color(0xFF4F46E5).withOpacity(0.08) : Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isAvailable ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  robot.name.contains("Alpha") ? Icons.smart_toy_rounded : Icons.directions_car_rounded,
                  color: isAvailable ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    robot.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isAvailable ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${robot.currentLocationName} · ${robot.hardware}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: robot.status == 'AVAILABLE'
                          ? const Color(0xFFDCFCE7)
                          : (robot.status == 'BUSY' ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      '● ${robot.status} · ${robot.batteryPct}%',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                        color: robot.status == 'AVAILABLE'
                            ? const Color(0xFF15803D)
                            : (robot.status == 'BUSY' ? const Color(0xFFB45309) : const Color(0xFF64748B)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Trailing icon
            if (isAvailable)
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
                size: 22,
              )
            else
              const Icon(
                Icons.lock_rounded,
                color: Color(0xFFCBD5E1),
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
