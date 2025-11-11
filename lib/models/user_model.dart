import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final bool isTrackingEnabled;
  final List<String> sharedWithUsers; // UIDs of users who can see this user's location
  final List<String> canViewUsers; // UIDs of users whose location this user can see
  final DateTime createdAt;
  final DateTime lastUpdated;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.isTrackingEnabled = false,
    this.sharedWithUsers = const [],
    this.canViewUsers = const [],
    DateTime? createdAt,
    DateTime? lastUpdated,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastUpdated = lastUpdated ?? DateTime.now();

  // From Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      isTrackingEnabled: data['isTrackingEnabled'] ?? false,
      sharedWithUsers: List<String>.from(data['sharedWithUsers'] ?? []),
      canViewUsers: List<String>.from(data['canViewUsers'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // To Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'isTrackingEnabled': isTrackingEnabled,
      'sharedWithUsers': sharedWithUsers,
      'canViewUsers': canViewUsers,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  // Copy with
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    bool? isTrackingEnabled,
    List<String>? sharedWithUsers,
    List<String>? canViewUsers,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isTrackingEnabled: isTrackingEnabled ?? this.isTrackingEnabled,
      sharedWithUsers: sharedWithUsers ?? this.sharedWithUsers,
      canViewUsers: canViewUsers ?? this.canViewUsers,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
