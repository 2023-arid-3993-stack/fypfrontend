import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/mjpeg_viewer.dart';
import 'pickup_location_screen.dart';
import 'drop_location_screen.dart';
import 'live_tracking_screen.dart';

class AutonomousSetupScreen extends StatefulWidget {
  final Robot selectedRobot;
  final Function(int) onTabChanged;

  const AutonomousSetupScreen({
    Key? key,
    required this.selectedRobot,
    required this.onTabChanged,
  }) : super(key: key);

  @override
  State<AutonomousSetupScreen> createState() => _AutonomousSetupScreenState();
}

class _AutonomousSetupScreenState extends State<AutonomousSetupScreen> {
  LocationItem? pickupLocation;
  LocationItem? dropLocation;
  bool isStarting = false;
  bool isLoadingLocations = true;

  @override
  void initState() {
    super.initState();
    _loadInitialLocations();
  }

  Future<void> _loadInitialLocations() async {
    final list = await ApiService.fetchLocations();
    if (mounted) {
      setState(() {
        if (list.isNotEmpty) {
          pickupLocation = list[0];
          dropLocation = list.length > 1 ? list[1] : list[0];
        }
        isLoadingLocations = false;
      });
    }
  }

  void _startMission() async {
    if (pickupLocation == null || dropLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select valid pickup and drop locations')),
      );
      return;
    }

    setState(() => isStarting = true);
    final missionId = await ApiService.startMission(
      widget.selectedRobot.robotId,
      pickupLocation!.locationId,
      dropLocation!.locationId,
    );
    setState(() => isStarting = false);

    if (mounted) {
      if (missionId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LiveTrackingScreen(
              missionId: missionId,
              selectedRobot: widget.selectedRobot,
              onTabChanged: widget.onTabChanged,
              pickupName: pickupLocation!.name,
              dropName: dropLocation!.name,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start mission. Check backend server connection.')),
        );
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
              'Robot Control',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.4),
            ),
            Text(
              '${widget.selectedRobot.name} · Autonomous Setup',
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18.0),
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
            Container(
              width: double.infinity,
              height: 190,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: MjpegViewer(
                  streamUrl: ApiService.liveStreamUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Detected banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Text('● DETECTED: ', style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
                  Text('Person ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                  Text('94%', style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: Color(0xFF15803D), fontWeight: FontWeight.w700)),
                  Spacer(),
                  Text('2.4 m', style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFEF4444))),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Segmented mode switch: Manual | Auto (Auto active)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.pop(context),
                      child: const Center(
                        child: Text(
                          'Manual',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                        ),
                      ),
                    ),
                  ),
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
                          'Auto',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // PICKUP LOCATION Card
            _buildLocationPickerCard(
              title: 'PICKUP LOCATION',
              locationName: pickupLocation != null ? '${pickupLocation!.name} · ${pickupLocation!.floorName}' : 'Loading pickup destinations...',
              dotColor: const Color(0xFF22C55E),
              onTap: () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PickupLocationScreen(selectedLocationId: pickupLocation?.locationId ?? 1),
                  ),
                );
                if (res != null && res is LocationItem) {
                  setState(() => pickupLocation = res);
                }
              },
            ),
            const SizedBox(height: 10),

            // DROP LOCATION Card
            _buildLocationPickerCard(
              title: 'DROP LOCATION',
              locationName: dropLocation != null ? '${dropLocation!.name} · ${dropLocation!.floorName}' : 'Loading drop destinations...',
              dotColor: const Color(0xFFEF4444),
              onTap: () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DropLocationScreen(selectedLocationId: dropLocation?.locationId ?? 2),
                  ),
                );
                if (res != null && res is LocationItem) {
                  setState(() => dropLocation = res);
                }
              },
            ),
            const SizedBox(height: 24),

            // Start Mission Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: isStarting ? null : _startMission,
                child: isStarting
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Start Mission',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
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

  Widget _buildLocationPickerCard({
    required String title,
    required String locationName,
    required Color dotColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.9,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    locationName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFC7D2FE), size: 22),
          ],
        ),
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
