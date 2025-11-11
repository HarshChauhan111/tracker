import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Debug screen to verify Firestore data and connectivity
class FirestoreDebugScreen extends StatefulWidget {
  final String currentUserId;
  
  const FirestoreDebugScreen({
    Key? key,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<FirestoreDebugScreen> createState() => _FirestoreDebugScreenState();
}

class _FirestoreDebugScreenState extends State<FirestoreDebugScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String _output = 'Tap "Run Tests" to check Firestore data...';
  bool _isRunning = false;

  Future<void> _runTests() async {
    setState(() {
      _isRunning = true;
      _output = 'Running tests...\n\n';
    });

    try {
      await _testUserDocument();
      await _testLiveLocations();
      await _testLocationsCollection();
      await _testSharedUsers();
      
      setState(() {
        _output += '\n✅ All tests completed!';
        _isRunning = false;
      });
    } catch (e) {
      setState(() {
        _output += '\n❌ Error: $e';
        _isRunning = false;
      });
    }
  }

  Future<void> _testUserDocument() async {
    _addOutput('📄 Testing User Document...');
    
    final userDoc = await _firestore
        .collection('users')
        .doc(widget.currentUserId)
        .get();
    
    if (!userDoc.exists) {
      _addOutput('❌ User document does NOT exist');
      return;
    }
    
    _addOutput('✅ User document exists');
    
    final data = userDoc.data()!;
    _addOutput('Email: ${data['email']}');
    _addOutput('Display Name: ${data['displayName'] ?? 'N/A'}');
    
    final canViewUsers = data['canViewUsers'] as List<dynamic>? ?? [];
    final sharedWithUsers = data['sharedWithUsers'] as List<dynamic>? ?? [];
    
    _addOutput('Can View Users: ${canViewUsers.length}');
    if (canViewUsers.isNotEmpty) {
      for (var uid in canViewUsers) {
        _addOutput('  - $uid');
      }
    }
    
    _addOutput('Shared With Users: ${sharedWithUsers.length}');
    if (sharedWithUsers.isNotEmpty) {
      for (var uid in sharedWithUsers) {
        _addOutput('  - $uid');
      }
    }
    
    _addOutput('');
  }

  Future<void> _testLiveLocations() async {
    _addOutput('📍 Testing Live Locations...');
    
    final liveDoc = await _firestore
        .collection('live_locations')
        .doc(widget.currentUserId)
        .get();
    
    if (!liveDoc.exists) {
      _addOutput('❌ Live location document does NOT exist');
      _addOutput('   → Start tracking to create it');
      _addOutput('');
      return;
    }
    
    _addOutput('✅ Live location document exists');
    
    final data = liveDoc.data()!;
    _addOutput('Latitude: ${data['latitude']}');
    _addOutput('Longitude: ${data['longitude']}');
    
    final timestamp = data['timestamp'] as Timestamp?;
    if (timestamp != null) {
      final age = DateTime.now().difference(timestamp.toDate());
      _addOutput('Timestamp: ${timestamp.toDate()}');
      _addOutput('Age: ${age.inMinutes} minutes, ${age.inSeconds % 60} seconds');
      
      if (age.inMinutes > 5) {
        _addOutput('⚠️ Location is old (> 5 minutes)');
      } else {
        _addOutput('✅ Location is recent');
      }
    }
    
    _addOutput('');
  }

  Future<void> _testLocationsCollection() async {
    _addOutput('📊 Testing Locations Collection (History)...');
    
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    final snapshot = await _firestore
        .collection('locations')
        .where('userId', isEqualTo: widget.currentUserId)
        .where('timestamp', isGreaterThan: Timestamp.fromDate(startOfDay))
        .orderBy('timestamp', descending: true)
        .limit(5)
        .get();
    
    _addOutput('Today\'s locations: ${snapshot.docs.length}');
    
    if (snapshot.docs.isEmpty) {
      _addOutput('❌ No locations found for today');
      _addOutput('   → Start tracking to create location history');
    } else {
      _addOutput('✅ Found locations:');
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp;
        _addOutput('  - ${timestamp.toDate().toString().substring(11, 19)} | '
            'Lat: ${data['latitude']}, Lng: ${data['longitude']}');
      }
    }
    
    _addOutput('');
  }

  Future<void> _testSharedUsers() async {
    _addOutput('👥 Testing Shared Users...');
    
    final userDoc = await _firestore
        .collection('users')
        .doc(widget.currentUserId)
        .get();
    
    if (!userDoc.exists) {
      _addOutput('❌ Cannot test - user document missing');
      return;
    }
    
    final canViewUsers = userDoc.data()!['canViewUsers'] as List<dynamic>? ?? [];
    
    if (canViewUsers.isEmpty) {
      _addOutput('ℹ️ No users granted you access');
      _addOutput('   → Ask someone to grant you access via Shared Locations screen');
      _addOutput('');
      return;
    }
    
    _addOutput('Testing ${canViewUsers.length} shared user(s)...');
    
    for (var uid in canViewUsers) {
      _addOutput('\nChecking user: $uid');
      
      // Check user document
      final sharedUserDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      
      if (!sharedUserDoc.exists) {
        _addOutput('  ❌ User document not found');
        continue;
      }
      
      final userData = sharedUserDoc.data()!;
      _addOutput('  ✅ Email: ${userData['email']}');
      
      // Check live location
      final liveLoc = await _firestore
          .collection('live_locations')
          .doc(uid)
          .get();
      
      if (!liveLoc.exists) {
        _addOutput('  ❌ No live location (user not tracking)');
      } else {
        final locData = liveLoc.data()!;
        final timestamp = locData['timestamp'] as Timestamp;
        final age = DateTime.now().difference(timestamp.toDate());
        
        _addOutput('  ✅ Live location found');
        _addOutput('     Lat: ${locData['latitude']}, Lng: ${locData['longitude']}');
        _addOutput('     Age: ${age.inMinutes}m ${age.inSeconds % 60}s');
        
        if (age.inMinutes > 5) {
          _addOutput('     ⚠️ Location is old');
        }
      }
    }
    
    _addOutput('');
  }

  void _addOutput(String text) {
    setState(() {
      _output += '$text\n';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Debug'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRunning ? null : _runTests,
                    icon: _isRunning
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(_isRunning ? 'Running...' : 'Run Tests'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _output = 'Tap "Run Tests" to check Firestore data...';
                    });
                  },
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear Output',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: SelectableText(
                _output,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Copy output to clipboard would go here
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can select and copy the text above'),
            ),
          );
        },
        icon: const Icon(Icons.copy),
        label: const Text('Copy Output'),
      ),
    );
  }
}
