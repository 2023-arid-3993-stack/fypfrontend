import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  // Configurable base URL: can be updated dynamically in Settings or via setBaseUrl
  static String baseUrl = "http://192.168.25.140:8000";

  static void setBaseUrl(String url) {
    if (url.endsWith("/")) {
      baseUrl = url.substring(0, url.length - 1);
    } else {
      baseUrl = url;
    }
  }

  static String get liveStreamUrl => "$baseUrl/api/video/feed";

  // --- Screen 01 & 02: Fleet Selection ---
  static Future<List<Robot>> fetchRobots() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/api/robots")).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((e) => Robot.fromJson(e)).toList();
      }
    } catch (e) {
      // Return empty list on network error (no hardcoded mock data)
    }
    return [];
  }

  static Future<bool> releaseRobot(int robotId) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/robots/$robotId/release"),
      ).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> fetchRobotDetails(int robotId) async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/api/robots/$robotId")).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      // Network error
    }
    return null;
  }

  // --- Screen 03 & 04 & 10 & 11: Locations Directory ---
  static Future<List<LocationItem>> fetchLocations() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/api/locations")).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((e) => LocationItem.fromJson(e)).toList();
      }
    } catch (e) {
      // Return empty list on network error (no hardcoded mock data)
    }
    return [];
  }

  static Future<Map<String, dynamic>?> fetchLocationDetail(int locationId) async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/api/locations/$locationId")).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      // Network error
    }
    return null;
  }

  // --- Screen 12: Add Location ---
  static Future<bool> addLocation({
    required String name,
    required int floorId,
    required String type,
    required List<int> adjacentRooms,
    required List<int> adjacentLandmarks,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/locations/add"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "floor_id": floorId,
          "location_type": type,
          "adjacent_rooms": adjacentRooms,
          "adjacent_landmarks": adjacentLandmarks,
        }),
      ).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- Screen 05: Manual Control & D-pad ---
  static Future<bool> sendMoveCommand(int robotId, String direction, double speed) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/control/move"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "robot_id": robotId,
          "direction": direction,
          "speed": speed,
        }),
      ).timeout(const Duration(seconds: 2));
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> triggerEmergencyStop(int robotId) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/control/emergency-stop"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "robot_id": robotId,
          "reason": "Emergency Button Pressed",
        }),
      ).timeout(const Duration(seconds: 2));
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- Screen 06: Autonomous Missions Plan & Start ---
  static Future<Map<String, dynamic>?> planMission(int robotId, int pickupId, int dropId) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/missions/plan"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "robot_id": robotId,
          "pickup_location_id": pickupId,
          "drop_location_id": dropId,
          "mode": "AUTO",
        }),
      ).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      // Network error
    }
    return null;
  }

  static Future<int?> startMission(int robotId, int pickupId, int dropId) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/missions/start"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "robot_id": robotId,
          "pickup_location_id": pickupId,
          "drop_location_id": dropId,
          "mode": "AUTO",
        }),
      ).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data["mission_id"];
      }
    } catch (e) {
      // Return null on network error (no fake fallback ID)
    }
    return null;
  }

  // --- Screen 07: Live Tracking & Mission Telemetry ---
  static Future<LiveMissionTelemetry?> getLiveMission(int missionId) async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/api/missions/$missionId/live")).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        return LiveMissionTelemetry.fromJson(jsonDecode(res.body));
      }
    } catch (e) {
      // Network error
    }
    return null;
  }

  static Future<bool> completeMission(int missionId, {String status = "SUCCESS"}) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/missions/$missionId/complete"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"status": status}),
      ).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- Screen 08: Mission History ---
  static Future<Map<String, dynamic>> fetchHistory() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/api/missions/history")).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      // Return real empty fallback (no fake hardcoded numbers)
    }
    return {
      "summary": {
        "total_missions": 0,
        "total_distance_km": 0.0,
        "success_rate_pct": 100,
      },
      "missions": []
    };
  }

  // --- Screen 09: Settings ---
  static Future<bool> updateRobotSettings(int robotId, Map<String, dynamic> settings) async {
    try {
      final res = await http.put(
        Uri.parse("$baseUrl/api/robots/$robotId/settings"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(settings),
      ).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- Live Detection Guidance & Phone Camera Stream ---
  static Future<NavigationGuidance?> fetchLatestGuidance() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/api/detections/latest")).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        return NavigationGuidance.fromJson(jsonDecode(res.body));
      }
    } catch (e) {
      // Network error
    }
    return null;
  }

  static Future<Map<String, dynamic>?> uploadFrame(Uint8List bytes) async {
    try {
      final uri = Uri.parse("$baseUrl/api/video/upload-frame");
      final request = http.MultipartRequest("POST", uri);
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'frame.jpg',
        ),
      );
      final streamedResponse = await request.send().timeout(const Duration(seconds: 3));
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      // Network error
    }
    return null;
  }
}
