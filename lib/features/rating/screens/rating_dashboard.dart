import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../firebase_options.dart';
import '../services/rating_service.dart';
import '../models/rating.dart';
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
        print('🔥🔥🔥 DASHBOARD: Checking role for user: ${user.email}');
        final role = await _ratingService.getUserRole(user.uid);
        print('🔥🔥🔥 DASHBOARD: Got role: $role');
        setState(() {
          _userRole = role;
          _isLoading = false;
        });
        print(
          '🔥🔥🔥 DASHBOARD: Will show ${role == 'owner' ? 'OWNER' : 'FOREMAN'} dashboard',
        );
      } else {
        print('🔥🔥🔥 DASHBOARD: No user logged in');
        setState(() {
          _userRole = 'foreman';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('🔥🔥🔥 DASHBOARD: Error checking role: $e');
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
            colors: [Color(0xFF2C3E50), Color(0xFF34495E)],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    print('🔥🔥🔥 DASHBOARD: Building dashboard for role: $_userRole');

    return _userRole == 'owner'
        ? const OwnerRatingView()
        : const ForemanRatingView();
  }

  void _createSampleRatings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Create sample ratings for different foremen
    final sampleRatings = [
      {
        'projectName': 'Office Building Construction',
        'foremanName': 'John Smith',
        'foremanId': 'foreman-1',
        'overallRating': 5,
        'qualityRating': 5,
        'timelinessRating': 4,
        'communicationRating': 5,
        'safetyRating': 5,
        'comments':
            'Excellent work! Project completed ahead of schedule with outstanding quality.',
      },
      {
        'projectName': 'Residential Complex Phase 1',
        'foremanName': 'Sarah Wilson',
        'foremanId': 'foreman-2',
        'overallRating': 4,
        'qualityRating': 4,
        'timelinessRating': 4,
        'communicationRating': 3,
        'safetyRating': 5,
        'comments':
            'Good work overall. Safety protocols were followed excellently.',
      },
      {
        'projectName': 'Shopping Mall Renovation',
        'foremanName': 'Mike Johnson',
        'foremanId': 'foreman-3',
        'overallRating': 3,
        'qualityRating': 3,
        'timelinessRating': 2,
        'communicationRating': 4,
        'safetyRating': 4,
        'comments':
            'Project was delayed but quality was acceptable. Need better time management.',
      },
    ];

    try {
      for (int i = 0; i < sampleRatings.length; i++) {
        final ratingData = sampleRatings[i];
        final rating = Rating(
          id: 'sample-${DateTime.now().millisecondsSinceEpoch}-$i',
          foremanId: ratingData['foremanId'] as String,
          foremanName: ratingData['foremanName'] as String,
          ownerId: user.uid,
          ownerName: user.displayName ?? user.email ?? 'Owner',
          overallRating: ratingData['overallRating'] as int,
          qualityRating: ratingData['qualityRating'] as int,
          timelinessRating: ratingData['timelinessRating'] as int,
          communicationRating: ratingData['communicationRating'] as int,
          safetyRating: ratingData['safetyRating'] as int,
          comments: ratingData['comments'] as String,
          createdAt: DateTime.now().subtract(
            Duration(days: i * 5),
          ), // Spread dates
          projectName: ratingData['projectName'] as String,
        );

        await _ratingService.createRating(rating);
        await Future.delayed(const Duration(milliseconds: 100)); // Small delay
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✅ Sample ratings created! Check "View All Ratings" to see them.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error creating sample ratings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
