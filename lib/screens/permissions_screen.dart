import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  List<UserModel> _sharedWithUsers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSharedUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSharedUsers() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.userModel != null) {
      setState(() => _isLoading = true);
      
      final users = await _firestoreService.getSharedUsers(
        authProvider.userModel!.sharedWithUsers,
      );
      
      setState(() {
        _sharedWithUsers = users;
        _isLoading = false;
      });
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);
    
    final results = await _firestoreService.searchUsersByEmail(query);
    final authProvider = context.read<AuthProvider>();
    
    // Filter out current user
    final filtered = results
        .where((user) => user.uid != authProvider.firebaseUser?.uid)
        .toList();
    
    setState(() {
      _searchResults = filtered;
      _isLoading = false;
    });
  }

  Future<void> _grantAccess(UserModel user) async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.firebaseUser == null) return;

    try {
      await _firestoreService.grantAccessToUser(
        authProvider.firebaseUser!.uid,
        user.uid,
      );
      
      await _loadSharedUsers();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.email} can now see your location'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _revokeAccess(UserModel user) async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.firebaseUser == null) return;

    try {
      await _firestoreService.revokeAccessFromUser(
        authProvider.firebaseUser!.uid,
        user.uid,
      );
      
      await _loadSharedUsers();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.email} can no longer see your location'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Permissions'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users by email',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _searchUsers,
            ),
          ),
          
          // Search Results
          if (_searchResults.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Search Results',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                final hasAccess = _sharedWithUsers
                    .any((u) => u.uid == user.uid);
                
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      user.email.substring(0, 1).toUpperCase(),
                    ),
                  ),
                  title: Text(user.displayName ?? user.email),
                  subtitle: Text(user.email),
                  trailing: hasAccess
                      ? IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          onPressed: () => _revokeAccess(user),
                        )
                      : IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => _grantAccess(user),
                        ),
                );
              },
            ),
            const Divider(),
          ],
          
          // Shared With Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _sharedWithUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No users have access',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Search for users above to grant access',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Users with Access',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _sharedWithUsers.length,
                              itemBuilder: (context, index) {
                                final user = _sharedWithUsers[index];
                                
                                return ListTile(
                                  leading: CircleAvatar(
                                    child: Text(
                                      user.email.substring(0, 1).toUpperCase(),
                                    ),
                                  ),
                                  title: Text(user.displayName ?? user.email),
                                  subtitle: Text(user.email),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _showRevokeDialog(user),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  void _showRevokeDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Access'),
        content: Text(
          'Remove ${user.email}\'s access to your location?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _revokeAccess(user);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
  }
}
