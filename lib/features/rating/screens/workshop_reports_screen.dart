import 'package:flutter/material.dart';
import '../models/rating.dart';
import '../services/rating_service.dart';

class WorkshopReportsScreen extends StatefulWidget {
  const WorkshopReportsScreen({Key? key}) : super(key: key);

  @override
  State<WorkshopReportsScreen> createState() => _WorkshopReportsScreenState();
}

class _WorkshopReportsScreenState extends State<WorkshopReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RatingService _ratingService = RatingService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('Workshop Reports'),
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.orange,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Overview'),
            Tab(icon: Icon(Icons.people), text: 'Workers'),
            Tab(icon: Icon(Icons.trending_up), text: 'Performance'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildWorkersTab(),
          _buildPerformanceTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
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

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCards(ratings),
              const SizedBox(height: 24),
              _buildRecentActivity(ratings),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards(List<Rating> ratings) {
    final totalRatings = ratings.length;
    final avgRating = ratings.isEmpty ? 0.0 : 
        ratings.map((r) => r.averageRating).reduce((a, b) => a + b) / totalRatings;
    final uniqueWorkers = ratings.map((r) => r.workerId).toSet().length;
    final recentRatings = ratings.where((r) => 
        DateTime.now().difference(r.createdAt).inDays <= 7).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Workshop Summary',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildSummaryCard('Total Ratings', totalRatings.toString(), Icons.star, Colors.blue),
            _buildSummaryCard('Average Score', avgRating.toStringAsFixed(1), Icons.trending_up, Colors.green),
            _buildSummaryCard('Active Workers', uniqueWorkers.toString(), Icons.people, Colors.orange),
            _buildSummaryCard('This Week', recentRatings.toString(), Icons.calendar_today, Colors.purple),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(List<Rating> ratings) {
    final recentRatings = ratings.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...recentRatings.map((rating) => _buildActivityItem(rating)).toList(),
      ],
    );
  }

  Widget _buildActivityItem(Rating rating) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(
            rating.workerName[0],
            style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(rating.workerName),
        subtitle: Text('${rating.projectName} • ${_formatDate(rating.createdAt)}'),
        trailing: Container(
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
      ),
    );
  }

  Widget _buildWorkersTab() {
    return StreamBuilder<List<Rating>>(
      stream: _ratingService.getAllRatings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final ratings = snapshot.data ?? [];
        final workerStats = _calculateWorkerStats(ratings);

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: workerStats.length,
          itemBuilder: (context, index) {
            final worker = workerStats[index];
            return _buildWorkerStatsCard(worker);
          },
        );
      },
    );
  }

  Widget _buildWorkerStatsCard(Map<String, dynamic> worker) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.orange.shade100,
                  child: Text(
                    worker['name'][0],
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker['name'],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${worker['totalRatings']} ratings • Avg: ${worker['avgRating'].toStringAsFixed(1)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getRatingColor(worker['avgRating']),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getRatingLabel(worker['avgRating']),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSkillBars(worker),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillBars(Map<String, dynamic> worker) {
    return Column(
      children: [
        _buildSkillBar('Technical', worker['avgTechnical']),
        _buildSkillBar('Communication', worker['avgCommunication']),
        _buildSkillBar('Safety', worker['avgSafety']),
        _buildSkillBar('Timeliness', worker['avgTimeliness']),
      ],
    );
  }

  Widget _buildSkillBar(String skill, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(skill, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: value / 5,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(_getRatingColor(value)),
            ),
          ),
          const SizedBox(width: 8),
          Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return StreamBuilder<List<Rating>>(
      stream: _ratingService.getAllRatings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final ratings = snapshot.data ?? [];
        return _buildPerformanceCharts(ratings);
      },
    );
  }

  Widget _buildPerformanceCharts(List<Rating> ratings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Trends',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildTrendCard('Overall Performance', ratings),
          const SizedBox(height: 16),
          _buildCategoryPerformance(ratings),
        ],
      ),
    );
  }

  Widget _buildTrendCard(String title, List<Rating> ratings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Performance Chart\n(Chart implementation would go here)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPerformance(List<Rating> ratings) {
    if (ratings.isEmpty) return const SizedBox();

    final avgOverall = ratings.map((r) => r.overallRating).reduce((a, b) => a + b) / ratings.length;
    final avgTechnical = ratings.map((r) => r.technicalRating).reduce((a, b) => a + b) / ratings.length;
    final avgCommunication = ratings.map((r) => r.communicationRating).reduce((a, b) => a + b) / ratings.length;
    final avgSafety = ratings.map((r) => r.safetyRating).reduce((a, b) => a + b) / ratings.length;
    final avgTimeliness = ratings.map((r) => r.timelinessRating).reduce((a, b) => a + b) / ratings.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category Averages',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildCategoryItem('Overall Performance', avgOverall),
            _buildCategoryItem('Technical Skills', avgTechnical),
            _buildCategoryItem('Communication', avgCommunication),
            _buildCategoryItem('Safety Compliance', avgSafety),
            _buildCategoryItem('Time Management', avgTimeliness),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String category, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(category, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                Icons.star,
                size: 20,
                color: index < value.round() ? Colors.amber : Colors.grey.shade300,
              );
            }),
          ),
          const SizedBox(width: 8),
          Text(
            value.toStringAsFixed(1),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _getRatingColor(value),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _calculateWorkerStats(List<Rating> ratings) {
    final workerMap = <String, List<Rating>>{};
    
    for (final rating in ratings) {
      workerMap.putIfAbsent(rating.workerId, () => []).add(rating);
    }

    return workerMap.entries.map((entry) {
      final workerRatings = entry.value;
      final avgRating = workerRatings.map((r) => r.averageRating).reduce((a, b) => a + b) / workerRatings.length;
      final avgTechnical = workerRatings.map((r) => r.technicalRating).reduce((a, b) => a + b) / workerRatings.length;
      final avgCommunication = workerRatings.map((r) => r.communicationRating).reduce((a, b) => a + b) / workerRatings.length;
      final avgSafety = workerRatings.map((r) => r.safetyRating).reduce((a, b) => a + b) / workerRatings.length;
      final avgTimeliness = workerRatings.map((r) => r.timelinessRating).reduce((a, b) => a + b) / workerRatings.length;

      return {
        'id': entry.key,
        'name': workerRatings.first.workerName,
        'totalRatings': workerRatings.length,
        'avgRating': avgRating,
        'avgTechnical': avgTechnical,
        'avgCommunication': avgCommunication,
        'avgSafety': avgSafety,
        'avgTimeliness': avgTimeliness,
      };
    }).toList()..sort((a, b) => (b['avgRating'] as double).compareTo(a['avgRating'] as double));
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.0) return Colors.green;
    if (rating >= 3.0) return Colors.orange;
    return Colors.red;
  }

  String _getRatingLabel(double rating) {
    if (rating >= 4.5) return 'Excellent';
    if (rating >= 4.0) return 'Good';
    if (rating >= 3.0) return 'Average';
    return 'Needs Improvement';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
