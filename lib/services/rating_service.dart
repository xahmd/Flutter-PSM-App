import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rating.dart';

class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'ratings';

  // Create a new rating (Owner only)
  Future<void> createRating(Rating rating) async {
    try {
      await _firestore.collection(_collection).doc(rating.id).set(rating.toJson());
    } catch (e) {
      throw Exception('Failed to create rating: $e');
    }
  }

  // Get all ratings (Owner only)
  Stream<List<Rating>> getAllRatings() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Rating.fromJson(doc.data()))
            .toList());
  }

  // Get ratings for a specific foreman
  Stream<List<Rating>> getForemanRatings(String foremanId) {
    return _firestore
        .collection(_collection)
        .where('foremanId', isEqualTo: foremanId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Rating.fromJson(doc.data()))
            .toList());
  }

  // Get ratings by owner
  Stream<List<Rating>> getRatingsByOwner(String ownerId) {
    return _firestore
        .collection(_collection)
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Rating.fromJson(doc.data()))
            .toList());
  }

  // Get average rating for a foreman
  Future<double> getForemanAverageRating(String foremanId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('foremanId', isEqualTo: foremanId)
          .get();

      if (snapshot.docs.isEmpty) return 0.0;

      double totalRating = 0.0;
      for (var doc in snapshot.docs) {
        final rating = Rating.fromJson(doc.data());
        totalRating += rating.averageRating;
      }

      return totalRating / snapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get average rating: $e');
    }
  }

  // Delete a rating (Owner only)
  Future<void> deleteRating(String ratingId) async {
    try {
      await _firestore.collection(_collection).doc(ratingId).delete();
    } catch (e) {
      throw Exception('Failed to delete rating: $e');
    }
  }

  // Update a rating (Owner only)
  Future<void> updateRating(Rating rating) async {
    try {
      await _firestore.collection(_collection).doc(rating.id).update(rating.toJson());
    } catch (e) {
      throw Exception('Failed to update rating: $e');
    }
  }
}
