import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

class SharedLocationsScreen extends StatefulWidget {
  const SharedLocationsScreen({super.key});

  @override
  State<SharedLocationsScreen> createState() => _SharedLocationsScreenState();
}

class _SharedLocationsScreenState extends State<SharedLocationsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers() async {
    final email = _searchController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isSearching = true);
    try {
      final results = await _firestoreService.searchUsersByEmail(email);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching users: $e')),
        );
      }
    }
  }

  Future<void> _grantAccess(String targetUid) async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.firebaseUser == null) return;

    try {
      await _firestoreService.grantAccessToUser(
        authProvider.firebaseUser!.uid,
        targetUid,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Access granted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error granting access: $e')),
        );
      }
    }
  }

  Future<void> _revokeAccess(String targetUid) async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.firebaseUser == null) return;

    try {
      await _firestoreService.revokeAccessFromUser(
        authProvider.firebaseUser!.uid,
        targetUid,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Access revoked successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error revoking access: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final locationProvider = context.watch<LocationProvider>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Shared Locations'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.visibility), text: 'I Can View'),
              Tab(icon: Icon(Icons.share), text: 'Sharing With'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Users I Can View
            _buildUsersICanView(locationProvider),
            // Tab 2: Users Sharing With Me (Grant/Revoke)
            _buildSharingManagement(authProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersICanView(LocationProvider locationProvider) {
    final sharedUsers = locationProvider.sharedUsers.values.toList();

    if (sharedUsers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No users sharing their location with you',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: sharedUsers.length,
      itemBuilder: (context, index) {
        final user = sharedUsers[index];
        final location = locationProvider.sharedUsersLocations[user.uid];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                (user.displayName ?? user.email)[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(user.displayName ?? user.email),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email),
                const SizedBox(height: 4),
                if (location != null)
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        'Last seen: ${_formatTime(location.timestamp)}',
                        style: const TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ],
                  )
                else
                  const Row(
                    children: [
                      Icon(Icons.location_off, size: 14, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        'Location unavailable',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
              ],
            ),
            trailing: location != null
                ? const Icon(Icons.circle, color: Colors.green, size: 12)
                : const Icon(Icons.circle, color: Colors.grey, size: 12),
          ),
        );
      },
    );
  }

  Widget _buildSharingManagement(AuthProvider authProvider) {
    if (authProvider.firebaseUser == null) {
      return const Center(child: Text('Not authenticated'));
    }

    return Column(
      children: [
        // Search section
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Grant Access to Users',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search by email',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _searchUsers(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSearching ? null : _searchUsers,
                    child: _isSearching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Search'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Search results
        if (_searchResults.isNotEmpty)
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                final isMe = user.uid == authProvider.firebaseUser!.uid;

                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      (user.displayName ?? user.email)[0].toUpperCase(),
                    ),
                  ),
                  title: Text(user.displayName ?? user.email),
                  subtitle: Text(user.email),
                  trailing: isMe
                      ? const Chip(label: Text('You'))
                      : ElevatedButton(
                          onPressed: () => _grantAccess(user.uid),
                          child: const Text('Grant Access'),
                        ),
                );
              },
            ),
          ),

        // Currently sharing with
        const Divider(),
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Currently Sharing With',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: StreamBuilder<UserModel?>(
            stream: _firestoreService.getUserStream(authProvider.firebaseUser!.uid),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final currentUser = snapshot.data!;
              if (currentUser.sharedWithUsers.isEmpty) {
                return const Center(
                  child: Text('Not sharing with anyone yet'),
                );
              }

              return FutureBuilder<List<UserModel>>(
                future: _firestoreService.getSharedUsers(currentUser.sharedWithUsers),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final users = userSnapshot.data!;
                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Text(
                            (user.displayName ?? user.email)[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(user.displayName ?? user.email),
                        subtitle: Text(user.email),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => _showRevokeDialog(user),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showRevokeDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Access'),
        content: Text(
          'Are you sure you want to revoke access for ${user.displayName ?? user.email}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _revokeAccess(user.uid);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
