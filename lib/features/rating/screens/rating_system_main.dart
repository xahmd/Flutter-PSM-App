import 'package:flutter/material.dart';
import '../models/rating.dart';
import '../services/rating_service.dart';

class RatingSystemMain extends StatefulWidget {
  const RatingSystemMain({Key? key}) : super(key: key);

  @override
  State<RatingSystemMain> createState() => _RatingSystemMainState();
}

class _RatingSystemMainState extends State<RatingSystemMain> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RatingService _ratingService = RatingService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workshop Rating System'),
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.orange,
          tabs: const [
            Tab(icon: Icon(Icons.star_rate), text: 'All Ratings'),
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Stats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRatingsList(),
          _buildStatistics(),
        ],
      ),
    );
  }

  Widget _buildRatingsList() {
    return StreamBuilder<List<Rating>>(
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
          return const Center(child: Text('No ratings found'));
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ratings.length,
          itemBuilder: (context, index) {
            final rating = ratings[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          rating.workerName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            rating.projectName,
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildRatingItem('Overall', rating.overallRating),
                        _buildRatingItem('Technical', rating.technicalRating),
                        _buildRatingItem('Time', rating.timelinessRating),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildRatingItem('Communication', rating.communicationRating),
                        _buildRatingItem('Safety', rating.safetyRating),
                        Text(
                          'Avg: ${rating.averageRating.toStringAsFixed(1)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Comments: ${rating.comments}',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rated by: ${rating.ownerName} on ${_formatDate(rating.createdAt)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRatingItem(String label, int value) {
    return Expanded(
      child: Row(
        children: [
          Text('$label: '),
          Text(
            '$value',
            style: TextStyle(
              color: _getRatingColor(value),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRatingColor(int rating) {
    if (rating >= 4) return Colors.green;
    if (rating >= 3) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildStatistics() {
    return StreamBuilder<List<Rating>>(
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
          return const Center(child: Text('No data available for statistics'));
        }
        
        // Calculate statistics
        final avgOverall = _calculateAverage(ratings.map((r) => r.overallRating).toList());
        final avgTechnical = _calculateAverage(ratings.map((r) => r.technicalRating).toList());
        final avgTimeliness = _calculateAverage(ratings.map((r) => r.timelinessRating).toList());
        final avgCommunication = _calculateAverage(ratings.map((r) => r.communicationRating).toList());
        final avgSafety = _calculateAverage(ratings.map((r) => r.safetyRating).toList());
        final totalAvg = _calculateAverage(ratings.map((r) => r.averageRating).toList());
        
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildStatCard('Workshop Performance Overview', totalAvg, Colors.blue),
              const SizedBox(height: 20),
              _buildStatDetail('Overall Rating', avgOverall),
              _buildStatDetail('Technical Skills', avgTechnical),
              _buildStatDetail('Time Management', avgTimeliness),
              _buildStatDetail('Communication', avgCommunication),
              _buildStatDetail('Safety Compliance', avgSafety),
              const SizedBox(height: 20),
              Text(
                'Based on ${ratings.length} ratings',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, double value, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              value.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _getRatingDescription(value),
              style: TextStyle(color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatDetail(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Row(
            children: List.generate(5, (index) {
              double i = index + 1.0;
              return Icon(
                Icons.star,
                size: 20,
                color: i <= value 
                    ? Colors.amber 
                    : (i - 0.5) <= value 
                        ? Colors.amber.shade200
                        : Colors.grey.shade300,
              );
            }),
          ),
          const SizedBox(width: 8),
          Text(
            value.toStringAsFixed(1),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _getRatingColor(value.round()),
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingDescription(double rating) {
    if (rating >= 4.5) return 'Excellent';
    if (rating >= 4.0) return 'Very Good';
    if (rating >= 3.5) return 'Good';
    if (rating >= 3.0) return 'Average';
    if (rating >= 2.0) return 'Below Average';
    return 'Poor';
  }

  double _calculateAverage(List<num> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }
}
