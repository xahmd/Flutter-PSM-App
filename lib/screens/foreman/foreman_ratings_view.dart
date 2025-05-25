import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/rating.dart';
import '../../services/rating_service.dart';

class ForemanRatingsView extends StatelessWidget {
  final RatingService _ratingService = RatingService();

  ForemanRatingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view ratings')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Ratings'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Rating>>(
        stream: _ratingService.getForemanRatings(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final ratings = snapshot.data ?? [];

          if (ratings.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No ratings yet', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          return Column(
            children: [
              _buildPersonalSummary(ratings),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: ratings.length,
                  itemBuilder: (context, index) {
                    final rating = ratings[index];
                    return _buildPersonalRatingCard(rating);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPersonalSummary(List<Rating> ratings) {
    final totalRatings = ratings.length;
    final averageRating = ratings.isEmpty ? 0.0 : 
        ratings.map((r) => r.averageRating).reduce((a, b) => a + b) / totalRatings;
    final recentRatings = ratings.where((r) => 
        DateTime.now().difference(r.createdAt).inDays <= 30).length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.green.shade50,
      child: Column(
        children: [
          const Text('Your Performance Summary', 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSummaryItem('Total Ratings', totalRatings.toString(), Icons.assessment),
              _buildSummaryItem('Average Score', averageRating.toStringAsFixed(1), Icons.star),
              _buildSummaryItem('This Month', recentRatings.toString(), Icons.calendar_month),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.green),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildPersonalRatingCard(Rating rating) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  rating.projectName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRatingColor(rating.averageRating),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        rating.averageRating.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Rated by: ${rating.ownerName}'),
            Text('Date: ${rating.createdAt.toString().split(' ')[0]}'),
            const SizedBox(height: 12),
            const Text('Detailed Ratings:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildDetailedRatings(rating),
            if (rating.comments.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Comments:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(rating.comments),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedRatings(Rating rating) {
    final categories = [
      ('Overall', rating.overallRating),
      ('Quality', rating.qualityRating),
      ('Timeliness', rating.timelinessRating),
      ('Communication', rating.communicationRating),
      ('Safety', rating.safetyRating),
    ];

    return Column(
      children: categories.map((category) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(category.$1, style: const TextStyle(fontWeight: FontWeight.w500)),
              ),
              ...List.generate(5, (index) {
                return Icon(
                  Icons.star,
                  size: 20,
                  color: index < category.$2 ? Colors.amber : Colors.grey.shade300,
                );
              }),
              const SizedBox(width: 8),
              Text('${category.$2}/5'),
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
}
