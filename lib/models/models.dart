class Robot {
  final int robotId;
  final String name;
  final String? deviceAddress;
  final String hardware;
  final String firmwareVersion;
  final String status; // AVAILABLE, BUSY, OFFLINE
  final int batteryPct;
  final int? currentLocationId;
  final String currentLocationName;

  Robot({
    required this.robotId,
    required this.name,
    this.deviceAddress,
    required this.hardware,
    required this.firmwareVersion,
    required this.status,
    required this.batteryPct,
    this.currentLocationId,
    required this.currentLocationName,
  });

  factory Robot.fromJson(Map<String, dynamic> json) {
    return Robot(
      robotId: json['robot_id'] ?? 1,
      name: json['name'] ?? 'VisionBot',
      deviceAddress: json['device_address'],
      hardware: json['hardware'] ?? 'ESP32-CAM',
      firmwareVersion: json['firmware_version'] ?? '2.4.1',
      status: json['status'] ?? 'OFFLINE',
      batteryPct: json['battery_pct'] ?? 100,
      currentLocationId: json['current_location_id'],
      currentLocationName: json['current_location_name'] ?? 'Unknown',
    );
  }
}

class LocationItem {
  final int locationId;
  final int floorId;
  final String floorName;
  final String name;
  final String locationType;
  final String adjacentRooms;
  final String adjacentPaths;

  LocationItem({
    required this.locationId,
    required this.floorId,
    required this.floorName,
    required this.name,
    required this.locationType,
    required this.adjacentRooms,
    required this.adjacentPaths,
  });

  factory LocationItem.fromJson(Map<String, dynamic> json) {
    return LocationItem(
      locationId: json['location_id'] ?? 0,
      floorId: json['floor_id'] ?? 0,
      floorName: json['floor_name'] ?? 'Ground Floor',
      name: json['name'] ?? '',
      locationType: json['location_type'] ?? 'ROOM',
      adjacentRooms: json['adjacent_rooms'] ?? 'None',
      adjacentPaths: json['adjacent_paths'] ?? 'Main Corridor',
    );
  }
}

class MissionItem {
  final int missionId;
  final String pickup;
  final String drop;
  final String status;
  final int distanceM;
  final String duration;
  final String timeAgo;
  final String note;

  MissionItem({
    required this.missionId,
    required this.pickup,
    required this.drop,
    required this.status,
    required this.distanceM,
    required this.duration,
    required this.timeAgo,
    required this.note,
  });

  factory MissionItem.fromJson(Map<String, dynamic> json) {
    return MissionItem(
      missionId: json['mission_id'] ?? 0,
      pickup: json['pickup'] ?? 'Lab 7',
      drop: json['drop'] ?? 'Lab 3',
      status: json['status'] ?? 'SUCCESS',
      distanceM: json['distance_m'] ?? 100,
      duration: json['duration'] ?? '4m 00s',
      timeAgo: json['time_ago'] ?? 'Today',
      note: json['note'] ?? 'corridor',
    );
  }
}

class LiveMissionTelemetry {
  final int missionId;
  final int robotId;
  final String status;
  final String pickup;
  final String drop;
  final int totalDistanceM;
  final int distanceSoFarM;
  final double speedMps;
  final int etaSeconds;
  final String positionNote;
  final String safetyStatus;
  final double? closestDistanceM;
  final String? primaryObstacleClass;
  final int? primaryConfidence;
  final String recommendedAction;
  final String instruction;
  final String voiceText;

  LiveMissionTelemetry({
    required this.missionId,
    required this.robotId,
    required this.status,
    required this.pickup,
    required this.drop,
    required this.totalDistanceM,
    required this.distanceSoFarM,
    required this.speedMps,
    required this.etaSeconds,
    required this.positionNote,
    required this.safetyStatus,
    this.closestDistanceM,
    this.primaryObstacleClass,
    this.primaryConfidence,
    this.recommendedAction = "FORWARD",
    this.instruction = "Path clear. Move Forward.",
    this.voiceText = "Path clear. Move forward.",
  });

  factory LiveMissionTelemetry.fromJson(Map<String, dynamic> json) {
    final det = json['latest_detection'] ?? {};
    final primary = det['primary'];

    return LiveMissionTelemetry(
      missionId: json['mission_id'] ?? 0,
      robotId: json['robot_id'] ?? 1,
      status: json['status'] ?? 'IN_PROGRESS',
      pickup: json['pickup'] ?? 'Lab 7',
      drop: json['drop'] ?? 'Lab 3',
      totalDistanceM: json['total_distance_m'] ?? 70,
      distanceSoFarM: json['distance_so_far_m'] ?? 0,
      speedMps: (json['speed_mps'] ?? 0.6).toDouble(),
      etaSeconds: json['eta_seconds'] ?? 116,
      positionNote: json['position_note'] ?? 'In transit',
      safetyStatus: det['safety_status'] ?? 'CLEAR',
      closestDistanceM: det['closest_distance_m'] != null ? (det['closest_distance_m']).toDouble() : null,
      primaryObstacleClass: primary != null ? primary['class'] : null,
      primaryConfidence: primary != null ? primary['confidence_pct'] : null,
      recommendedAction: det['recommended_action'] ?? "FORWARD",
      instruction: det['instruction'] ?? "Path clear. Move Forward.",
      voiceText: det['voice_text'] ?? "Path clear. Move forward.",
    );
  }
}

class NavigationGuidance {
  final int totalObstacles;
  final String? objectClass;
  final int? confidencePct;
  final double? distanceM;
  final String safetyStatus;
  final String recommendedAction; // FORWARD, TURN LEFT, TURN RIGHT, BACKWARD
  final String instruction;
  final String voiceText;
  final String arrow;

  NavigationGuidance({
    required this.totalObstacles,
    this.objectClass,
    this.confidencePct,
    this.distanceM,
    required this.safetyStatus,
    required this.recommendedAction,
    required this.instruction,
    required this.voiceText,
    required this.arrow,
  });

  factory NavigationGuidance.fromJson(Map<String, dynamic> json) {
    final primary = json['primary'];
    return NavigationGuidance(
      totalObstacles: json['total_obstacles'] ?? 0,
      objectClass: primary != null ? primary['class'] : null,
      confidencePct: primary != null ? primary['confidence_pct'] : null,
      distanceM: primary != null && primary['distance_m'] != null
          ? (primary['distance_m']).toDouble()
          : null,
      safetyStatus: json['safety_status'] ?? 'CLEAR',
      recommendedAction: json['recommended_action'] ?? 'FORWARD',
      instruction: json['instruction'] ?? 'Path is clear. Move Forward.',
      voiceText: json['voice_text'] ?? 'Path clear. Move forward.',
      arrow: json['arrow'] ?? '^ FORWARD ^',
    );
  }
}
