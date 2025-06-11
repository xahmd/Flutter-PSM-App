import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/rating_service.dart';
import 'owner_rating_view.dart';
import 'foreman_rating_view.dart';

class RatingDashboard extends StatefulWidget {
  const RatingDashboard({Key? key}) : super(key: key);

  @override
  State<RatingDashboard> createState() => _RatingDashboardState();
}

class _RatingDashboardState extends State<RatingDashboard> {
  final RatingService _ratingService =
      RatingService(); // This will now use the singleton
  String? _userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print(' DASHBOARD: Checking role for user: ${user.email}');
        final role = await _ratingService.getUserRole(user.uid);
        print(' DASHBOARD: Got role: $role');
        setState(() {
          _userRole = role;
          _isLoading = false;
        });
        print(
          ' DASHBOARD: Will show ${role == 'owner' ? 'OWNER' : 'FOREMAN'} dashboard',
        );
      } else {
        print('ASHBOARD: No user logged in');
        setState(() {
          _userRole = 'foreman';
          _isLoading = false;
        });
      }
    } catch (e) {
      print(' DASHBOARD: Error checking role: $e');
      setState(() {
        _userRole = 'foreman';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFFF8F65)],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    print(' DASHBOARD: Building dashboard for role: $_userRole');

    return _userRole == 'owner'
        ? const OwnerRatingView()
        : const ForemanRatingView();
  }
}
