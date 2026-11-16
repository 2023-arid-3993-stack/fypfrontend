import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class DropLocationScreen extends StatefulWidget {
  final int selectedLocationId;
  const DropLocationScreen({Key? key, required this.selectedLocationId}) : super(key: key);

  @override
  State<DropLocationScreen> createState() => _DropLocationScreenState();
}

class _DropLocationScreenState extends State<DropLocationScreen> {
  List<LocationItem> locations = [];
  late int currentSelectedId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    currentSelectedId = widget.selectedLocationId;
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
              'Drop Location',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.4),
            ),
            Text(
              'Select where the robot should go · ${locations.length} locations',
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
                    itemCount: locations.length,
                    itemBuilder: (context, index) {
                      final loc = locations[index];
                      final isSelected = loc.locationId == currentSelectedId;
                      return GestureDetector(
                        onTap: () {
                          setState(() => currentSelectedId = loc.locationId);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.location_on_rounded, color: Color(0xFFEF4444), size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loc.name,
                                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${loc.floorName} · ${loc.locationType}',
                                      style: const TextStyle(fontFamily: 'monospace', fontSize: 8.5, color: Color(0xFF94A3B8)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'ROOM  ${loc.adjacentRooms}',
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF475569)),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        final picked = locations.firstWhere((l) => l.locationId == currentSelectedId, orElse: () => locations.first);
                        Navigator.pop(context, picked);
                      },
                      child: const Text('Confirm Drop', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
