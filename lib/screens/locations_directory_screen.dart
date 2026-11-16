import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'location_details_screen.dart';
import 'add_location_screen.dart';

class LocationsDirectoryScreen extends StatefulWidget {
  const LocationsDirectoryScreen({Key? key}) : super(key: key);

  @override
  State<LocationsDirectoryScreen> createState() => _LocationsDirectoryScreenState();
}

class _LocationsDirectoryScreenState extends State<LocationsDirectoryScreen> {
  List<LocationItem> locations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    final list = await ApiService.fetchLocations();
    setState(() {
      locations = list;
      isLoading = false;
    });
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
              'Locations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.4,
              ),
            ),
            Text(
              'Ground Floor · ${locations.length} saved destinations',
              style: const TextStyle(
                fontSize: 10.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Text(
                        'Ground Floor',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                    Text(
                      '${locations.length} locations',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...locations.map((loc) => _buildLocationCard(loc)),
                const SizedBox(height: 70), // clearance for fab
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4F46E5),
        elevation: 4,
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddLocationScreen()),
          );
          if (res == true) {
            _loadLocations();
          }
        },
        child: const Icon(Icons.add_rounded, size: 32, color: Colors.white),
      ),
    );
  }

  Widget _buildLocationCard(LocationItem loc) {
    IconData getIcon() {
      switch (loc.locationType.toUpperCase()) {
        case 'LAB':
          return Icons.science_rounded;
        case 'OFFICE':
          return Icons.business_center_rounded;
        case 'STAIRS':
          return Icons.stairs_rounded;
        case 'GATE':
          return Icons.door_front_door_rounded;
        default:
          return Icons.meeting_room_rounded;
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LocationDetailsScreen(location: loc)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(getIcon(), color: const Color(0xFF4F46E5), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.name,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${loc.floorName} · ${loc.locationType}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 8.5,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text(
                                  'ROOM  ',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 8,
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    loc.adjacentRooms,
                                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Text(
                                  'PATH  ',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 8,
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    loc.adjacentPaths,
                                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Chevron divider
              Container(
                width: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border(left: BorderSide(color: Color(0xFFEEF2F7))),
                ),
                child: const Icon(Icons.chevron_right_rounded, color: Color(0xFF4F46E5), size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
