import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rating.dart';
import '../services/rating_service.dart';
import 'create_rating_screen.dart';
import 'all_ratings_screen.dart';

class OwnerRatingView extends StatefulWidget {
  const OwnerRatingView({Key? key}) : super(key: key);

  @override
  State<OwnerRatingView> createState() => _OwnerRatingViewState();
}

class _OwnerRatingViewState extends State<OwnerRatingView>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final RatingService _ratingService = RatingService();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2C3E50),
            Color(0xFF3498DB),
            Color(0xFF9B59B6),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 50),
                _buildStatsCards(),
                const SizedBox(height: 40),
                Expanded(child: _buildForemenCards()),
                const SizedBox(height: 20),
                _buildQuickActions(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final user = FirebaseAuth.instance.currentUser;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: const Icon(
            Icons.business,
            size: 50,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Owner Dashboard',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Welcome, ${user?.displayName ?? user?.email ?? 'Owner'}',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return StreamBuilder<List<Rating>>(
      stream: _ratingService.getAllRatings(),
      builder: (context, snapshot) {
        final ratings = snapshot.data ?? [];
        final totalRatings = ratings.length;
        final avgRating = ratings.isEmpty
            ? 0.0
            : ratings
                    .map((r) => r.averageRating)
                    .reduce((a, b) => a + b) /
                totalRatings;
        final uniqueForemen = ratings.map((r) => r.foremanId).toSet().length;

        return Row(
          children: [
            Expanded(
                child: _buildStatCard(
                    'Total Ratings', totalRatings.toString(), Icons.rate_review)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildStatCard(
                    'Foremen', uniqueForemen.toString(), Icons.engineering)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildStatCard(
                    'Avg Rating', avgRating.toStringAsFixed(1), Icons.star)),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildForemenCards() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _ratingService.getForemen(),
      builder: (context, snapshot) {
        print('🔥🔥🔥 OWNER VIEW: Loading foremen list...');
        print('🔥 Connection state: ${snapshot.connectionState}');
        print('🔥 Has data: ${snapshot.hasData}');
        print('🔥 Data: ${snapshot.data}');
        
        final foremen = snapshot.data ?? [];
        print('🔥 Number of foremen found: ${foremen.length}');

        if (foremen.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 80,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(height: 20),
                Text(
                  'No foremen found',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                // Add test button to manually create foreman users
                ElevatedButton(
                  onPressed: () async {
                    print('🔥🔥🔥 CREATING TEST FOREMEN 🔥🔥🔥');
                    try {
                      // Create test foreman users
                      await FirebaseFirestore.instance.collection('users').doc('test-foreman-1').set({
                        'role': 'foreman',
                        'name': 'John Smith',
                        'email': 'john@example.com',
                        'createdAt': DateTime.now().toIso8601String(),
                      });
                      
                      await FirebaseFirestore.instance.collection('users').doc('test-foreman-2').set({
                        'role': 'foreman',
                        'name': 'Mike Johnson',
                        'email': 'mike@example.com',
                        'createdAt': DateTime.now().toIso8601String(),
                      });
                      
                      print('🔥 Test foremen created successfully!');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Test foremen created! Refresh to see them.')),
                      );
                    } catch (e) {
                      print('🔥 Error creating test foremen: $e');
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('Create Test Foremen'),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 16),
              child: Text(
                'Your Foremen',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: foremen.length,
                itemBuilder: (context, index) {
                  final foreman = foremen[index];
                  return _buildForemanCard(foreman);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildForemanCard(Map<String, dynamic> foreman) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToRating(foreman['id'], foreman['name']),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE67E22), Color(0xFFD35400)],
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      foreman['name'][0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        foreman['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.email,
                            size: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              foreman['email'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'View All Ratings',
            Icons.list,
            const Color(0xFF4CAF50),
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AllRatingsScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            'Analytics',
            Icons.analytics,
            const Color(0xFF2196F3),
            () => _showAnalytics(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToRating(String foremanId, String foremanName) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            CreateRatingScreen(
          foremanId: foremanId,
          foremanName: foremanName,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end)
              .chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  void _showAnalytics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.analytics, color: Colors.blue),
            SizedBox(width: 8),
            Text('Analytics'),
          ],
        ),
        content: const Text('Detailed analytics and performance insights coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
