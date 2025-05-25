import 'package:flutter/material.dart';
import '../../models/rating.dart';
import '../../services/rating_service.dart';
import 'create_rating_screen.dart';

class OwnerRatingsDashboard extends StatelessWidget {
  final RatingService _ratingService = RatingService();

  OwnerRatingsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ratings Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showForemanSelection(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Rating>>(
        stream: _ratingService.getAllRatings(),
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
              child: Text('No ratings available'),
            );
          }

          return Column(
            children: [
              _buildSummaryCards(ratings),
              Expanded(
                child: ListView.builder(
                  itemCount: ratings.length,
                  itemBuilder: (context, index) {
                    final rating = ratings[index];
                    return _buildRatingCard(rating, context);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(List<Rating> ratings) {
    final totalRatings = ratings.length;
    final averageRating = ratings.isEmpty ? 0.0 : 
        ratings.map((r) => r.averageRating).reduce((a, b) => a + b) / totalRatings;
    final uniqueForemen = ratings.map((r) => r.foremanId).toSet().length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _buildSummaryCard('Total Ratings', totalRatings.toString(), Colors.blue)),
          const SizedBox(width: 8),
          Expanded(child: _buildSummaryCard('Average Rating', averageRating.toStringAsFixed(1), Colors.green)),
          const SizedBox(width: 8),
          Expanded(child: _buildSummaryCard('Foremen Rated', uniqueForemen.toString(), Colors.orange)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingCard(Rating rating, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  rating.foremanName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    Text(rating.averageRating.toStringAsFixed(1)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Project: ${rating.projectName}'),
            Text('Date: ${rating.createdAt.toString().split(' ')[0]}'),
            const SizedBox(height: 8),
            _buildRatingRow('Overall', rating.overallRating),
            _buildRatingRow('Quality', rating.qualityRating),
            _buildRatingRow('Timeliness', rating.timelinessRating),
            _buildRatingRow('Communication', rating.communicationRating),
            _buildRatingRow('Safety', rating.safetyRating),
            if (rating.comments.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Comments: ${rating.comments}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRow(String label, int rating) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label)),
          ...List.generate(5, (index) {
            return Icon(
              Icons.star,
              size: 16,
              color: index < rating ? Colors.amber : Colors.grey,
            );
          }),
        ],
      ),
    );
  }

  void _showForemanSelection(BuildContext context) {
    // This would typically show a list of foremen to select from
    // For now, showing a simple dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Foreman to Rate'),
        content: const Text('This would show a list of available foremen'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateRatingScreen(
                    foremanId: 'demo_foreman_id',
                    foremanName: 'Demo Foreman',
                  ),
                ),
              );
            },
            child: const Text('Demo Rate'),
          ),
        ],
      ),
    );
  }
}
