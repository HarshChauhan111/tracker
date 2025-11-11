class RouteModel {
  final String? id;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final String? name;
  final double totalDistance; // in meters
  final int locationCount;
  final bool isActive;

  RouteModel({
    this.id,
    required this.userId,
    required this.startTime,
    this.endTime,
    this.name,
    this.totalDistance = 0.0,
    this.locationCount = 0,
    this.isActive = true,
  });

  // From SQLite
  factory RouteModel.fromMap(Map<String, dynamic> map) {
    return RouteModel(
      id: map['id']?.toString(),
      userId: map['userId'] as String,
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime'] as String) : null,
      name: map['name'] as String?,
      totalDistance: map['totalDistance'] as double? ?? 0.0,
      locationCount: map['locationCount'] as int? ?? 0,
      isActive: map['isActive'] == 1,
    );
  }

  // To SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'name': name,
      'totalDistance': totalDistance,
      'locationCount': locationCount,
      'isActive': isActive ? 1 : 0,
    };
  }

  // Copy with
  RouteModel copyWith({
    String? id,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    String? name,
    double? totalDistance,
    int? locationCount,
    bool? isActive,
  }) {
    return RouteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      name: name ?? this.name,
      totalDistance: totalDistance ?? this.totalDistance,
      locationCount: locationCount ?? this.locationCount,
      isActive: isActive ?? this.isActive,
    );
  }

  // Get duration
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  // Format distance
  String get formattedDistance {
    if (totalDistance < 1000) {
      return '${totalDistance.toStringAsFixed(0)} m';
    } else {
      return '${(totalDistance / 1000).toStringAsFixed(2)} km';
    }
  }
}
