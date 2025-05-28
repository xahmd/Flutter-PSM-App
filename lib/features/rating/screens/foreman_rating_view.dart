import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rating.dart';
import '../services/rating_service.dart';

class ForemanRatingView extends StatefulWidget {
  const ForemanRatingView({Key? key}) : super(key: key);

  @override
  State<ForemanRatingView> createState() => _ForemanRatingViewState();
}

class _ForemanRatingViewState extends State<ForemanRatingView>
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view your ratings')),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B4332),
            Color(0xFF2D6A4F),
            Color(0xFF40916C),
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
                _buildStatsCards(user.uid),
                const SizedBox(height: 40),
                Expanded(child: _buildRatingsHistory(user.uid)),
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
            Icons.engineering,
            size: 50,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Foreman Dashboard',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Welcome, ${user?.displayName ?? user?.email ?? 'Foreman'}',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards(String foremanId) {
    return StreamBuilder<List<Rating>>(
      stream: _ratingService.getForemanRatings(foremanId),
      builder: (context, snapshot) {
        final ratings = snapshot.data ?? [];
        final totalRatings = ratings.length;
        final avgRating = ratings.isEmpty
            ? 0.0
            : ratings
                    .map((r) => r.averageRating)
                    .reduce((a, b) => a + b) /
                totalRatings;
        final recentRatings = ratings
            .where((r) => DateTime.now().difference(r.createdAt).inDays <= 30)
            .length;

        return Row(
          children: [
            Expanded(
                child: _buildStatCard(
                    'Total Ratings', totalRatings.toString(), Icons.rate_review)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildStatCard(
                    'Avg Rating', avgRating.toStringAsFixed(1), Icons.star)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildStatCard(
                    'This Month', recentRatings.toString(), Icons.calendar_month)),
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

  Widget _buildRatingsHistory(String foremanId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ratings')
          .where('foremanId', isEqualTo: foremanId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 80,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(height: 20),
                Text(
                  'No ratings yet',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your ratings will appear here when owners rate your work',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Debug info
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Debug: Found ${docs.length} ratings for foreman ID: $foremanId',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 16),
              child: Text(
                'Your Ratings History (${docs.length})',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final docId = docs[index].id;
                  
                  return Card(
                    color: Colors.white.withOpacity(0.1),
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Debug info for each rating
                          Container(
                            padding: const EdgeInsets.all(4),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Doc ID: $docId | Created: ${data['createdAt']}',
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ),
                          Text(
                            'Project: ${data['projectName'] ?? 'Unknown'}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'From: ${data['ownerName'] ?? 'Unknown'}',
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Overall Rating: ', style: TextStyle(color: Colors.white70)),
                              ...List.generate(5, (i) => Icon(
                                Icons.star,
                                size: 16,
                                color: i < (data['overallRating'] ?? 0) ? Colors.amber : Colors.grey,
                              )),
                              Text(' ${data['overallRating']}/5', style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (data['comments'] != null && data['comments'].toString().isNotEmpty)
                            Text(
                              'Comments: ${data['comments']}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createTestRating(BuildContext context, String foremanId) async {
    try {
      print('🔥🔥🔥 CREATING TEST RATING FOR FOREMAN: $foremanId');
      
      await FirebaseFirestore.instance.collection('ratings').add({
        'id': 'foreman-test-${DateTime.now().millisecondsSinceEpoch}',
        'foremanId': foremanId,
        'foremanName': 'Test Foreman',
        'ownerId': 'test-owner-123',
        'ownerName': 'Test Owner',
        'overallRating': 4,
        'qualityRating': 4,
        'timelinessRating': 5,
        'communicationRating': 3,
        'safetyRating': 5,
        'comments': 'This is a test rating created from foreman dashboard',
        'createdAt': DateTime.now().toIso8601String(),
        'projectName': 'Test Project from Foreman View',
        'averageRating': 4.2,
      });
      
      print('🔥 Test rating created successfully for foreman: $foremanId');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Test rating created! It should appear above now.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('🔥 Error creating test rating: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to create test rating: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildRatingCard(Rating rating) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rating.projectName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rated by: ${rating.ownerName}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getRatingColor(rating.averageRating),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          rating.averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildRatingBreakdown(rating),
              if (rating.comments.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Comments:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rating.comments,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Rated on: ${_formatDate(rating.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingBreakdown(Rating rating) {
    final categories = [
      {'label': 'Overall', 'value': rating.overallRating},
      {'label': 'Quality', 'value': rating.qualityRating},
      {'label': 'Timeliness', 'value': rating.timelinessRating},
      {'label': 'Communication', 'value': rating.communicationRating},
      {'label': 'Safety', 'value': rating.safetyRating},
    ];

    return Column(
      children: categories.map((category) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  category['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      Icons.star,
                      size: 16,
                      color: index < (category['value'] as int)
                          ? Colors.amber
                          : Colors.white.withOpacity(0.3),
                    );
                  }),
                ),
              ),
              Text(
                '${category['value']}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.0) return Colors.green;
    if (rating >= 3.0) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
