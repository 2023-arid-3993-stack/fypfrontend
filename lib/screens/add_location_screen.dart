import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AddLocationScreen extends StatefulWidget {
  const AddLocationScreen({Key? key}) : super(key: key);

  @override
  State<AddLocationScreen> createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends State<AddLocationScreen> {
  final _nameController = TextEditingController();
  String _selectedFloor = 'Ground Floor';
  String _selectedType = 'LAB';
  final Set<int> _selectedRooms = {};
  final Set<int> _selectedLandmarks = {};
  bool _isSaving = false;
  bool _isLoadingLocations = true;

  final List<String> _types = ['LAB', 'OFFICE', 'ROOM', 'STAIRS', 'GATE'];
  List<LocationItem> _allLocations = [];

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    final list = await ApiService.fetchLocations();
    if (mounted) {
      setState(() {
        _allLocations = list;
        _isLoadingLocations = false;
      });
    }
  }

  List<LocationItem> get _rooms => _allLocations
      .where((l) => ['LAB', 'ROOM', 'OFFICE'].contains(l.locationType.toUpperCase()))
      .toList();

  List<LocationItem> get _landmarks => _allLocations
      .where((l) => ['PATH', 'GATE', 'STAIRS', 'OFFICE'].contains(l.locationType.toUpperCase()))
      .toList();

  Future<void> _saveLocation() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter location name')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final success = await ApiService.addLocation(
      name: name,
      floorId: 1, // Ground Floor
      type: _selectedType,
      adjacentRooms: _selectedRooms.toList(),
      adjacentLandmarks: _selectedLandmarks.toList(),
    );

    setState(() => _isSaving = false);
    if (success) {
      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save location')),
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Location',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.4,
              ),
            ),
            Text(
              'New indoor destination · Ground Floor',
              style: TextStyle(
                fontSize: 10.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LOCATION NAME
            _sectionLabel('LOCATION NAME'),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g. Lab 8',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFDBE3EE)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFDBE3EE)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // FLOOR DROPDOWN
            _sectionLabel('FLOOR'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDBE3EE)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedFloor,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF64748B)),
                  items: const [
                    DropdownMenuItem(value: 'Ground Floor', child: Text('Ground Floor', style: TextStyle(fontSize: 13))),
                    DropdownMenuItem(value: 'First Floor', child: Text('First Floor', style: TextStyle(fontSize: 13))),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedFloor = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // LOCATION TYPE CHIPS
            _sectionLabel('LOCATION TYPE'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _types.map((type) {
                final isSel = _selectedType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSel,
                  selectedColor: const Color(0xFF4F46E5),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSel ? Colors.white : const Color(0xFF475569),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(99),
                    side: BorderSide(color: isSel ? const Color(0xFF4F46E5) : const Color(0xFFDBE3EE)),
                  ),
                  onSelected: (_) => setState(() => _selectedType = type),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ADJACENT ROOM CHIPS
            _sectionLabel('ADJACENT ROOM'),
            _isLoadingLocations
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5))),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _rooms.map((room) {
                      final id = room.locationId;
                      final isSel = _selectedRooms.contains(id);
                      return FilterChip(
                        label: Text(room.name),
                        selected: isSel,
                        selectedColor: const Color(0xFF4F46E5),
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSel ? Colors.white : const Color(0xFF475569),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(99),
                          side: BorderSide(color: isSel ? const Color(0xFF4F46E5) : const Color(0xFFDBE3EE)),
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedRooms.add(id);
                            } else {
                              _selectedRooms.remove(id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 16),

            // ADJACENT LANDMARK CHIPS
            _sectionLabel('ADJACENT LT / LANDMARK'),
            _isLoadingLocations
                ? const SizedBox.shrink()
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _landmarks.map((lmk) {
                      final id = lmk.locationId;
                      final isSel = _selectedLandmarks.contains(id);
                      return FilterChip(
                        label: Text(lmk.name),
                        selected: isSel,
                        selectedColor: const Color(0xFF4F46E5),
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSel ? Colors.white : const Color(0xFF475569),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(99),
                          side: BorderSide(color: isSel ? const Color(0xFF4F46E5) : const Color(0xFFDBE3EE)),
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedLandmarks.add(id);
                            } else {
                              _selectedLandmarks.remove(id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 28),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _isSaving ? null : _saveLocation,
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text(
                        'Save Location',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7.0),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF94A3B8),
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
