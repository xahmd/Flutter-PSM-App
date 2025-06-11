import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'owner_schedule_page.dart';
import 'schedule_management_page.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  Future<String?> _getUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        return userDoc.data()?['role'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user role: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }

        final role = snapshot.data;
        if (role == 'Owner') {
          return const OwnerSchedulePage();
        } else if (role == 'Foremen') {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            return ScheduleManagementPage(foremanId: currentUser.uid);
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Schedule'),
            backgroundColor: Colors.deepOrange,
          ),
          body: const Center(
            child: Text('Unauthorized or unknown role'),
          ),
        );
      },
    );
  }
} 