import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/rating.dart';

class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'ratings';

  // Create a new rating (only owners can create ratings)
  Future<void> createRating(Rating rating) async {
    try {
      print('🔄 Attempting to save to Firestore...');
      print('📍 Collection: $_collection');
      print('🆔 Document ID: ${rating.id}');
      
      await _firestore.collection(_collection).doc(rating.id).set(rating.toJson());
      
      print('✅ Successfully saved to Firestore!');
    } catch (e) {
      print('❌ Firestore save error: $e');
      throw Exception('Failed to create rating: $e');
    }
  }

  // Get all ratings (only for owners)
  Stream<List<Rating>> getAllRatings() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Rating.fromJson(doc.data()))
            .toList());
  }

  // Get ratings for a specific foreman (for foremen to see their own ratings)
  Stream<List<Rating>> getForemanRatings(String foremanId) {
    print('🔥🔥🔥 GETTING RATINGS FOR FOREMAN: $foremanId');
    return _firestore
        .collection(_collection)
        .where('foremanId', isEqualTo: foremanId)
        .snapshots()
        .map((snapshot) {
          print('🔥 Raw snapshot docs: ${snapshot.docs.length}');
          
          // Debug each document
          for (var doc in snapshot.docs) {
            print('🔥 Document ${doc.id}: ${doc.data()}');
          }
          
          final ratings = snapshot.docs.map((doc) {
            try {
              final rating = Rating.fromJson(doc.data());
              print('🔥 Successfully parsed rating: ${rating.id}');
              return rating;
            } catch (e) {
              print('🔥 Error parsing rating ${doc.id}: $e');
              print('🔥 Raw data: ${doc.data()}');
              return null;
            }
          }).where((rating) => rating != null).cast<Rating>().toList();
          
          print('🔥 Final processed ratings: ${ratings.length}');
          return ratings;
        });
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

  // Check user role
  Future<String> getUserRole(String userId) async {
    try {
      print('🔍 Checking role for user: $userId');
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        final data = userDoc.data();
        print('👤 User data found: $data');
        final role = data?['role'] ?? 'foreman';
        print('🎭 User role from database: $role');
        
        // Convert to lowercase for consistency
        final normalizedRole = role.toString().toLowerCase();
        print('🎭 Normalized role: $normalizedRole');
        
        // Map different role variations to standard ones
        if (normalizedRole == 'owner' || normalizedRole == 'owners') {
          print('🎭 Final role: owner');
          return 'owner';
        } else if (normalizedRole == 'foreman' || normalizedRole == 'foremen') {
          print('🎭 Final role: foreman'); 
          return 'foreman';
        } else {
          print('🎭 Unknown role, defaulting to: foreman');
          return 'foreman';
        }
      } else {
        print('🆕 User document does not exist, creating with foreman role');
        await _createUserDocument(userId, 'foreman');
        return 'foreman';
      }
    } catch (e) {
      print('❌ Error getting user role: $e');
      return 'foreman';
    }
  }

  // Helper method to create user document
  Future<void> _createUserDocument(String userId, String role) async {
    final user = FirebaseAuth.instance.currentUser;
    await _firestore.collection('users').doc(userId).set({
      'role': role,
      'email': user?.email ?? '',
      'name': user?.displayName ?? user?.email ?? 'Unknown',
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  // Method to manually set user role (for testing purposes)
  Future<void> setUserRole(String userId, String role) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'role': role,
        'email': FirebaseAuth.instance.currentUser?.email ?? '',
        'name': FirebaseAuth.instance.currentUser?.displayName ?? 
                FirebaseAuth.instance.currentUser?.email ?? 'Unknown',
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error setting user role: $e');
    }
  }

  // Get list of foremen (for owners)
  Stream<List<Map<String, dynamic>>> getForemen() {
    print('🔥🔥🔥 GETTING FOREMEN LIST 🔥🔥🔥');
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'foreman')
        .snapshots()
        .map((snapshot) {
          print('🔥 Found ${snapshot.docs.length} users with role "foreman"');
          final foremen = snapshot.docs.map((doc) {
            print('🔥 Foreman: ${doc.data()}');
            return {
              'id': doc.id,
              'name': doc.data()['name'] ?? 'Unknown',
              'email': doc.data()['email'] ?? '',
            };
          }).toList();
          print('🔥 Processed foremen: $foremen');
          return foremen;
        });
  }
}
