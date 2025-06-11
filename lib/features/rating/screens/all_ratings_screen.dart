import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/rating.dart';
import '../services/rating_service.dart';

class AllRatingsScreen extends StatefulWidget {
  const AllRatingsScreen({Key? key}) : super(key: key);

  @override
  State<AllRatingsScreen> createState() => _AllRatingsScreenState();
}

class _AllRatingsScreenState extends State<AllRatingsScreen> {
  final RatingService _ratingService = RatingService();
  String _filterBy = 'all'; // 'all', 'my_ratings', 'high_rated', 'recent'
  String _sortBy = 'date'; // 'date', 'rating', 'foreman'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Ratings'),
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'date',
                    child: Row(
                      children: [
                        Icon(Icons.date_range),
                        SizedBox(width: 8),
                        Text('Sort by Date'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'rating',
                    child: Row(
                      children: [
                        Icon(Icons.star),
                        SizedBox(width: 8),
                        Text('Sort by Rating'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'foreman',
                    child: Row(
                      children: [
                        Icon(Icons.person),
                        SizedBox(width: 8),
                        Text('Sort by Foreman'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2C3E50), Color(0xFF34495E)],
          ),
        ),
        child: Column(
          children: [_buildFilterChips(), Expanded(child: _buildRatingsList())],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All Ratings', 'all'),
            const SizedBox(width: 8),
            _buildFilterChip('My Ratings', 'my_ratings'),
            const SizedBox(width: 8),
            _buildFilterChip('High Rated (4+)', 'high_rated'),
            const SizedBox(width: 8),
            _buildFilterChip('Recent (30 days)', 'recent'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterBy == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[600],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterBy = value;
        });
      },
      backgroundColor: Colors.white.withOpacity(0.1),
      selectedColor: Colors.blue.withOpacity(0.3),
      checkmarkColor: Colors.white,
    );
  }

  Widget _buildRatingsList() {
    return StreamBuilder<List<Rating>>(
      stream: _ratingService.getAllRatings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(height: 20),
                Text(
                  'Error loading ratings',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Using demo mode due to database permissions',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      _ratingService.addTestRatingToCache(user.uid);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Demo rating added!')),
                      );
                    }
                  },
                  child: const Text('Add Demo Rating'),
                ),
              ],
            ),
          );
        }

        List<Rating> ratings = snapshot.data ?? [];

        // Apply filters
        ratings = _applyFilters(ratings);

        // Apply sorting
        ratings = _applySorting(ratings);

        if (ratings.isEmpty) {
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
                  'No ratings found',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _getEmptyStateMessage(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      _ratingService.addTestRatingToCache(user.uid);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Demo rating added!')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('Add Demo Rating'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Summary header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.analytics,
                    color: Colors.white.withOpacity(0.8),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${ratings.length} ratings found',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Avg: ${_calculateAverageRating(ratings).toStringAsFixed(1)}⭐',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Ratings list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: ratings.length,
                itemBuilder: (context, index) {
                  final rating = ratings[index];
                  return _buildRatingCard(rating);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  List<Rating> _applyFilters(List<Rating> ratings) {
    final user = FirebaseAuth.instance.currentUser;

    switch (_filterBy) {
      case 'my_ratings':
        return ratings.where((r) => r.ownerId == user?.uid).toList();
      case 'high_rated':
        return ratings.where((r) => r.averageRating >= 4.0).toList();
      case 'recent':
        final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
        return ratings
            .where((r) => r.createdAt.isAfter(thirtyDaysAgo))
            .toList();
      default:
        return ratings;
    }
  }

  List<Rating> _applySorting(List<Rating> ratings) {
    switch (_sortBy) {
      case 'rating':
        ratings.sort((a, b) => b.averageRating.compareTo(a.averageRating));
        break;
      case 'foreman':
        ratings.sort((a, b) => a.foremanName.compareTo(b.foremanName));
        break;
      default: // 'date'
        ratings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    return ratings;
  }

  double _calculateAverageRating(List<Rating> ratings) {
    if (ratings.isEmpty) return 0.0;
    final sum = ratings.map((r) => r.averageRating).reduce((a, b) => a + b);
    return sum / ratings.length;
  }

  String _getEmptyStateMessage() {
    switch (_filterBy) {
      case 'my_ratings':
        return 'You haven\'t created any ratings yet.\nStart rating your foremen!';
      case 'high_rated':
        return 'No ratings with 4+ stars found.\nKeep encouraging good work!';
      case 'recent':
        return 'No ratings in the last 30 days.\nTime to check on your team!';
      default:
        return 'No ratings found in the system.\nCreate your first rating!';
    }
  }

  Widget _buildRatingCard(Rating rating) {
    final user = FirebaseAuth.instance.currentUser;
    final isMyRating = rating.ownerId == user?.uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showRatingDetails(rating),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    isMyRating
                        ? Colors.blue.withOpacity(0.5)
                        : Colors.white.withOpacity(0.2),
                width: isMyRating ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rating.projectName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Foreman: ${rating.foremanName}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getRatingColor(rating.averageRating),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                rating.averageRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isMyRating) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'MY RATING',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Rated by: ${rating.ownerName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(rating.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                if (rating.comments.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    rating.comments,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRatingDetails(Rating rating) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(Icons.rate_review, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rating.projectName,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('Foreman', rating.foremanName),
                  _buildDetailRow('Rated by', rating.ownerName),
                  _buildDetailRow('Date', _formatDate(rating.createdAt)),
                  const SizedBox(height: 16),
                  const Text(
                    'Ratings Breakdown:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildRatingRow('Overall', rating.overallRating),
                  _buildRatingRow('Quality', rating.qualityRating),
                  _buildRatingRow('Timeliness', rating.timelinessRating),
                  _buildRatingRow('Communication', rating.communicationRating),
                  _buildRatingRow('Safety', rating.safetyRating),
                  if (rating.comments.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Comments:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(rating.comments),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildRatingRow(String label, int rating) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:', style: const TextStyle(fontSize: 14)),
          ),
          ...List.generate(
            5,
            (i) => Icon(
              Icons.star,
              size: 16,
              color: i < rating ? Colors.amber : Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$rating/5',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
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
