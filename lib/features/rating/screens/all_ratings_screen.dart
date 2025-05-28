import 'package:flutter/material.dart';
import '../models/rating.dart';
import '../services/rating_service.dart';

class AllRatingsScreen extends StatelessWidget {
  const AllRatingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final RatingService ratingService = RatingService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Ratings'),
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2C3E50), Color(0xFF34495E)],
          ),
        ),
        child: StreamBuilder<List<Rating>>(
          stream: ratingService.getAllRatings(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }

            final ratings = snapshot.data ?? [];

            if (ratings.isEmpty) {
              return const Center(
                child: Text(
                  'No ratings available',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ratings.length,
              itemBuilder: (context, index) {
                final rating = ratings[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${rating.foremanName} - ${rating.projectName}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getRatingColor(rating.averageRating),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              rating.averageRating.toStringAsFixed(1),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rated by: ${rating.ownerName}',
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                      Text(
                        'Date: ${_formatDate(rating.createdAt)}',
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                      if (rating.comments.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          rating.comments,
                          style: TextStyle(color: Colors.white.withOpacity(0.9)),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
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
