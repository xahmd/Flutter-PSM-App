import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'owner/owner_ratings_dashboard.dart';
import 'foreman/foreman_ratings_view.dart';

class RatingSystemMain extends StatefulWidget {
  const RatingSystemMain({Key? key}) : super(key: key);

  @override
  State<RatingSystemMain> createState() => _RatingSystemMainState();
}

class _RatingSystemMainState extends State<RatingSystemMain> {
  String? userRole;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          setState(() {
            userRole = doc.data()?['role'] ?? 'foreman';
            isLoading = false;
          });
        } else {
          // Default role if user document doesn't exist
          setState(() {
            userRole = 'foreman';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        userRole = 'foreman';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Role-based navigation
    switch (userRole) {
      case 'owner':
        return OwnerRatingsDashboard();
      case 'foreman':
      default:
        return ForemanRatingsView();
    }
  }
}

// Helper widget for role selection (for testing purposes)
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Role'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Choose your role to access the appropriate rating interface:',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            _buildRoleCard(
              context,
              'Owner',
              'Create and manage ratings for all foremen',
              Icons.business,
              Colors.blue,
              () => _setRoleAndNavigate(context, 'owner'),
            ),
            const SizedBox(height: 20),
            _buildRoleCard(
              context,
              'Foreman',
              'View your personal ratings and feedback',
              Icons.construction,
              Colors.green,
              () => _setRoleAndNavigate(context, 'foreman'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, String title, String description, 
      IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(description, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setRoleAndNavigate(BuildContext context, String role) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({'role': role}, SetOptions(merge: true));
      }

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RatingSystemMain()),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error setting role: $e')),
        );
      }
    }
  }
}
