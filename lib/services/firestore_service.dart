import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/location_model.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  String get _usersCollection => 'users';
  String get _locationsCollection => 'locations';
  String get _liveLocationsCollection => 'live_locations';

  // ========== User Operations ==========

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  Future<UserModel> createUser(User user, {String? displayName}) async {
    final userModel = UserModel(
      uid: user.uid,
      email: user.email!,
      displayName: displayName ?? user.displayName,
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    );

    await _firestore
        .collection(_usersCollection)
        .doc(user.uid)
        .set(userModel.toFirestore());

    return userModel;
  }

  Future<UserModel> getOrCreateUser(User user) async {
    final existingUser = await getUser(user.uid);
    if (existingUser != null) {
      return existingUser;
    }
    return await createUser(user);
  }

  Future<void> updateUser(UserModel user) async {
    await _firestore
        .collection(_usersCollection)
        .doc(user.uid)
        .update(user.toFirestore());
  }

  Future<void> deleteUser(String uid) async {
    // Delete user document
    await _firestore.collection(_usersCollection).doc(uid).delete();

    // Delete all user's locations
    final locationsQuery = await _firestore
        .collection(_locationsCollection)
        .where('userId', isEqualTo: uid)
        .get();

    final batch = _firestore.batch();
    for (var doc in locationsQuery.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ========== Tracking Control ==========

  Future<void> setTrackingEnabled(String uid, bool enabled) async {
    await _firestore.collection(_usersCollection).doc(uid).update({
      'isTrackingEnabled': enabled,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // ========== Location Operations ==========

  // Update live location (single document per user for real-time tracking)
  Future<void> updateLiveLocation(LocationModel location) async {
    try {
      print('Updating live location for user: ${location.userId}');
      print('Location: lat=${location.latitude}, lng=${location.longitude}, time=${location.timestamp}');
      
      await _firestore
          .collection(_liveLocationsCollection)
          .doc(location.userId)
          .set(location.toFirestore(), SetOptions(merge: true));
      
      print('Live location updated successfully for ${location.userId}');
    } catch (e) {
      print('Error updating live location: $e');
      rethrow;
    }
  }

  Future<void> saveLocation(LocationModel location) async {
    // Save to locations collection (history)
    await _firestore
        .collection(_locationsCollection)
        .add(location.toFirestore());
    
    // Also update live location
    await updateLiveLocation(location);
  }

  Future<void> saveLocationsBatch(List<LocationModel> locations) async {
    if (locations.isEmpty) return;

    // Save to locations collection
    final batch = _firestore.batch();
    for (var location in locations) {
      final docRef = _firestore.collection(_locationsCollection).doc();
      batch.set(docRef, location.toFirestore());
    }
    await batch.commit();

    // Update live location with the most recent one
    if (locations.isNotEmpty) {
      final latestLocation = locations.reduce((a, b) => 
        a.timestamp.isAfter(b.timestamp) ? a : b
      );
      await updateLiveLocation(latestLocation);
    }
  }

  Stream<List<LocationModel>> getUserLocationsStream(String uid) {
    return _firestore
        .collection(_locationsCollection)
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LocationModel.fromFirestore(doc))
            .toList());
  }

  Future<LocationModel?> getLastLocation(String uid) async {
    try {
      final snapshot = await _firestore
          .collection(_locationsCollection)
          .where('userId', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return LocationModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Error getting last location: $e');
      return null;
    }
  }

  Stream<LocationModel?> getLastLocationStream(String uid) {
    return _firestore
        .collection(_locationsCollection)
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return LocationModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    });
  }

  // ========== Permission Management ==========

  Future<void> grantAccessToUser(String ownerUid, String targetUid) async {
    final ownerRef = _firestore.collection(_usersCollection).doc(ownerUid);
    final targetRef = _firestore.collection(_usersCollection).doc(targetUid);

    await _firestore.runTransaction((transaction) async {
      // Add targetUid to owner's sharedWithUsers
      transaction.update(ownerRef, {
        'sharedWithUsers': FieldValue.arrayUnion([targetUid]),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Add ownerUid to target's canViewUsers
      transaction.update(targetRef, {
        'canViewUsers': FieldValue.arrayUnion([ownerUid]),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> revokeAccessFromUser(String ownerUid, String targetUid) async {
    final ownerRef = _firestore.collection(_usersCollection).doc(ownerUid);
    final targetRef = _firestore.collection(_usersCollection).doc(targetUid);

    await _firestore.runTransaction((transaction) async {
      // Remove targetUid from owner's sharedWithUsers
      transaction.update(ownerRef, {
        'sharedWithUsers': FieldValue.arrayRemove([targetUid]),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Remove ownerUid from target's canViewUsers
      transaction.update(targetRef, {
        'canViewUsers': FieldValue.arrayRemove([ownerUid]),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    });
  }

  // ========== Search Users ==========

  Future<List<UserModel>> searchUsersByEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .where('email', isGreaterThanOrEqualTo: email)
          .where('email', isLessThanOrEqualTo: '$email\uf8ff')
          .limit(10)
          .get();

      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // ========== Get Shared Users ==========

  Future<List<UserModel>> getSharedUsers(List<String> userIds) async {
    if (userIds.isEmpty) return [];

    try {
      // Firestore 'in' query supports up to 10 items
      List<UserModel> allUsers = [];
      for (int i = 0; i < userIds.length; i += 10) {
        final batch = userIds.skip(i).take(10).toList();
        final snapshot = await _firestore
            .collection(_usersCollection)
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        allUsers.addAll(
          snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList(),
        );
      }
      return allUsers;
    } catch (e) {
      print('Error getting shared users: $e');
      return [];
    }
  }

  Stream<UserModel?> getUserStream(String uid) {
    return _firestore
        .collection(_usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // ========== Shared Location Tracking ==========

  // Get list of users whose locations I can view
  Future<List<UserModel>> getUsersICanView(String myUid) async {
    try {
      print('Getting users I can view for: $myUid');
      final myUser = await getUser(myUid);
      if (myUser == null) {
        print('My user document not found');
        return [];
      }
      
      print('My user canViewUsers: ${myUser.canViewUsers}');
      
      if (myUser.canViewUsers.isEmpty) {
        print('canViewUsers array is empty');
        return [];
      }
      return await getSharedUsers(myUser.canViewUsers);
    } catch (e) {
      print('Error getting users I can view: $e');
      return [];
    }
  }

  // Stream of users whose locations I can view
  Stream<List<UserModel>> getUsersICanViewStream(String myUid) {
    print('Creating stream for users I can view: $myUid');
    return getUserStream(myUid).asyncMap((myUser) async {
      if (myUser == null) {
        print('Stream: My user is null');
        return <UserModel>[];
      }
      
      print('Stream: My user canViewUsers: ${myUser.canViewUsers}');
      
      if (myUser.canViewUsers.isEmpty) {
        print('Stream: canViewUsers is empty');
        return <UserModel>[];
      }
      final users = await getSharedUsers(myUser.canViewUsers);
      print('Stream: Retrieved ${users.length} shared users');
      return users;
    });
  }

  // Get live location for a specific user (from live_locations collection)
  Stream<LocationModel?> getLiveLocationStream(String uid) {
    print('Creating live location stream for user: $uid');
    return _firestore
        .collection(_liveLocationsCollection)
        .doc(uid)
        .snapshots()
        .map((doc) {
      print('Live location snapshot for $uid - exists: ${doc.exists}');
      if (doc.exists && doc.data() != null) {
        try {
          final data = doc.data()!;
          print('Live location data for $uid: $data');
          final location = LocationModel.fromMap(data);
          print('Parsed location for $uid: lat=${location.latitude}, lng=${location.longitude}, time=${location.timestamp}');
          return location;
        } catch (e) {
          print('Error parsing live location for $uid: $e');
          return null;
        }
      }
      print('Live location document does not exist or has no data for $uid');
      return null;
    });
  }

  // Get historical locations for a shared user by date
  Future<List<LocationModel>> getSharedUserLocationsByDate(String uid, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection(_locationsCollection)
          .where('userId', isEqualTo: uid)
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThanOrEqualTo: endOfDay)
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => LocationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting shared user locations: $e');
      return [];
    }
  }
}
