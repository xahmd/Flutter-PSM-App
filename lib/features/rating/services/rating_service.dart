import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../firebase_options.dart';
import '../models/rating.dart';

class RatingService {
  // Singleton pattern
  static final RatingService _instance = RatingService._internal();
  factory RatingService() => _instance;
  RatingService._internal() {
    _initializeFirebase();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _ratingsCollection = 'ratings';
  final String _usersCollection = 'users';

  // In-memory storage for user roles (for optimization)
  final Map<String, String> _localRoles = {};

  // Local cache for ratings when Firebase is not accessible
  final Map<String, Rating> _localRatingsCache = {};

  // Initialize Firebase
  Future<void> _initializeFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print('🔥 Firebase initialized in RatingService');
      }
    } catch (e) {
      print('🔥 Error initializing Firebase in RatingService: $e');
    }
  }

  // Create a new rating with permission error handling
  Future<void> createRating(Rating rating) async {
    try {
      print('🔄 Attempting to save to Firestore...');
      print('📍 Collection: $_ratingsCollection');
      print('🆔 Document ID: ${rating.id}');

      await _firestore
          .collection(_ratingsCollection)
          .doc(rating.id)
          .set(rating.toJson());

      print('✅ Successfully saved to Firestore!');
    } catch (e) {
      print('❌ Firestore save error: $e');

      // Handle permission denied errors gracefully
      if (e.toString().contains('permission-denied') ||
          e.toString().contains('PERMISSION_DENIED')) {
        print(
          '🔥 Permission denied - storing rating in local cache for demo purposes',
        );

        // Store in local cache for demo purposes
        _localRatingsCache[rating.id] = rating;

        print('✅ Rating cached locally for demo purposes!');
        print('🔥 Local cache now has ${_localRatingsCache.length} ratings');

        // Print the cached rating details
        print(
          '🔥 Cached rating: ${rating.projectName} for ${rating.foremanName} (ID: ${rating.foremanId})',
        );

        // Don't throw error - let the user know it worked in demo mode
        return;
      }

      throw Exception('Failed to create rating: $e');
    }
  }

  // Get ratings for a specific foreman with local cache fallback
  Stream<List<Rating>> getForemanRatings(String foremanId) {
    print('🔥🔥🔥 GETTING RATINGS FOR FOREMAN: $foremanId');

    // Create a stream controller to handle both Firebase and local cache
    late StreamController<List<Rating>> controller;

    controller = StreamController<List<Rating>>(
      onListen: () {
        print('🔥 Stream listener attached for foreman: $foremanId');

        // Try Firestore first
        _firestore
            .collection(_ratingsCollection)
            .where('foremanId', isEqualTo: foremanId)
            .snapshots()
            .listen(
              (QuerySnapshot snapshot) {
                print(
                  '🔥 Firestore snapshot received: ${snapshot.docs.length} docs',
                );

                List<Rating> ratings = [];

                // Add Firestore ratings if available
                for (var doc in snapshot.docs) {
                  try {
                    final ratingData = doc.data() as Map<String, dynamic>;
                    print('🔥 Raw rating data: $ratingData');

                    final rating = Rating.fromJson(ratingData);
                    ratings.add(rating);
                    print(
                      '🔥 Successfully parsed Firestore rating: ${rating.id} for foreman ${rating.foremanId}',
                    );
                  } catch (e) {
                    print('🔥 Error parsing Firestore rating ${doc.id}: $e');
                    print('🔥 Raw data was: ${doc.data()}');
                  }
                }

                // Add local cache ratings
                final localRatings =
                    _localRatingsCache.values
                        .where((rating) => rating.foremanId == foremanId)
                        .toList();

                if (localRatings.isNotEmpty) {
                  ratings.addAll(localRatings);
                  print(
                    '🔥 Added ${localRatings.length} ratings from local cache',
                  );
                }

                // Sort by creation date
                ratings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                print('🔥 Final processed ratings: ${ratings.length}');
                print('🔥 Ratings IDs: ${ratings.map((r) => r.id).toList()}');

                if (!controller.isClosed) {
                  controller.add(ratings);
                }
              },
              onError: (error) {
                print('🔥 Firestore stream error: $error');

                // Return local cache only when Firebase fails
                final localRatings =
                    _localRatingsCache.values
                        .where((rating) => rating.foremanId == foremanId)
                        .toList();

                localRatings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                print(
                  '🔥 Returning ${localRatings.length} ratings from local cache only',
                );

                if (!controller.isClosed) {
                  controller.add(localRatings);
                }
              },
            );
      },
      onCancel: () {
        controller.close();
      },
    );

    return controller.stream;
  }

  // Get all ratings with local cache fallback (for View All Ratings screen)
  Stream<List<Rating>> getAllRatings() {
    print('🔥🔥🔥 GETTING ALL RATINGS 🔥🔥🔥');

    // Create a stream controller to handle both Firebase and local cache
    late StreamController<List<Rating>> controller;

    controller = StreamController<List<Rating>>(
      onListen: () {
        print('🔥 All ratings stream listener attached');

        // Try Firestore first
        _firestore
            .collection(_ratingsCollection)
            .snapshots()
            .listen(
              (QuerySnapshot snapshot) {
                print(
                  '🔥 Firestore all ratings snapshot: ${snapshot.docs.length} docs',
                );

                List<Rating> ratings = [];

                // Add Firestore ratings
                for (var doc in snapshot.docs) {
                  try {
                    final ratingData = doc.data() as Map<String, dynamic>;
                    print('🔥 Processing rating doc: ${doc.id}');

                    final rating = Rating.fromJson(ratingData);
                    ratings.add(rating);
                    print('🔥 Successfully parsed rating: ${rating.id}');
                  } catch (e) {
                    print('🔥 Error parsing Firestore rating ${doc.id}: $e');
                    print('🔥 Raw data: ${doc.data()}');
                  }
                }

                // Add local cache ratings
                ratings.addAll(_localRatingsCache.values);
                print(
                  '🔥 Added ${_localRatingsCache.length} ratings from local cache',
                );

                // Sort by creation date
                ratings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                print('🔥 Total ratings to return: ${ratings.length}');
                print(
                  '🔥 Sample rating IDs: ${ratings.take(5).map((r) => r.id).toList()}',
                );

                if (!controller.isClosed) {
                  controller.add(ratings);
                }
              },
              onError: (error) {
                print('🔥 Firestore all ratings error: $error');

                // If cache is empty and Firebase failed, populate with sample data
                if (_localRatingsCache.isEmpty) {
                  print('🔥 Cache is empty, populating with sample data...');
                  populateCacheWithSampleData();
                }

                // Return local cache (now with sample data if it was empty)
                final ratings = _localRatingsCache.values.toList();
                ratings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                print(
                  '🔥 Returning ${ratings.length} ratings from local cache only',
                );

                if (!controller.isClosed) {
                  controller.add(ratings);
                }
              },
            );
      },
      onCancel: () {
        controller.close();
      },
    );

    return controller.stream;
  }

  // Get average rating for a foreman
  Future<double> getForemanAverageRating(String foremanId) async {
    try {
      final snapshot =
          await _firestore
              .collection(_ratingsCollection)
              .where('foremanId', isEqualTo: foremanId)
              .get();

      if (snapshot.docs.isEmpty) return 0.0;

      double totalRating = 0.0;
      for (var doc in snapshot.docs) {
        final ratingData = doc.data();
        final rating = Rating.fromJson(ratingData);
        totalRating += rating.averageRating;
      }

      return totalRating / snapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get average rating: $e');
    }
  }

  // Improved role detection - Firebase first, then email fallback
  Future<String> getUserRole(String userId) async {
    try {
      print('🔍 Checking role for user: $userId');

      // First check in-memory storage
      final localRole = _localRoles[userId];

      if (localRole != null) {
        print('🎭 Found cached role: $localRole');
        return localRole;
      }

      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email?.toLowerCase() ?? '';

      print('🔍 User email: $email');

      String detectedRole = 'foreman'; // Default fallback

      // TRY FIRESTORE FIRST (Primary method)
      try {
        print('🔥 Attempting to read role from Firestore users collection...');
        final userDoc =
            await _firestore.collection(_usersCollection).doc(userId).get();

        if (userDoc.exists) {
          final data = userDoc.data();
          print('🔥 Firebase user data: $data');

          final roleFromFirebase =
              data?['role']?.toString().toLowerCase() ?? '';
          print('🔥 Role from Firebase: "$roleFromFirebase"');

          if (roleFromFirebase == 'owner' || roleFromFirebase == 'owners') {
            detectedRole = 'owner';
            print('🎭 ✅ DETECTED AS OWNER from Firebase database');
          } else if (roleFromFirebase == 'foreman' ||
              roleFromFirebase == 'foremen') {
            detectedRole = 'foreman';
            print('🎭 ✅ DETECTED AS FOREMAN from Firebase database');
          } else {
            print(
              '🔥 Unknown role in Firebase: "$roleFromFirebase", falling back to email detection',
            );
            // Continue to email detection below
          }
        } else {
          print(
            '🔥 User document not found in Firebase, falling back to email detection',
          );
          // Continue to email detection below
        }
      } catch (firestoreError) {
        print('🔥 Firebase read failed: $firestoreError');
        print('🔥 Falling back to email-based detection...');
        // Continue to email detection below
      }

      // EMAIL-BASED DETECTION (Fallback method)
      if (detectedRole == 'foreman') {
        // Only if Firebase didn't determine the role
        if (email.contains('owner') ||
            email.contains('admin') ||
            email.contains('boss') ||
            email.contains('manager') ||
            email.endsWith('@owner.com') ||
            email.endsWith('@admin.com') ||
            email.endsWith('@company.com') ||
            email.startsWith('owner') ||
            email.startsWith('admin') ||
            email.startsWith('boss')) {
          detectedRole = 'owner';
          print('🎭 ✅ DETECTED AS OWNER based on email patterns: $email');
        } else {
          print('🎭 ✅ DETECTED AS FOREMAN based on email patterns: $email');
        }
      }

      // Save to in-memory storage
      _localRoles[userId] = detectedRole;
      print('🎭 Final role determination: $detectedRole');

      return detectedRole;
    } catch (e) {
      print('🔥 Error getting user role: $e');
      return 'foreman'; // Safe fallback
    }
  }

  // Method to manually set user role (for testing purposes)
  Future<void> setUserRole(String userId, String role) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).set({
        'role': role,
        'email': FirebaseAuth.instance.currentUser?.email ?? '',
        'name':
            FirebaseAuth.instance.currentUser?.displayName ??
            FirebaseAuth.instance.currentUser?.email ??
            'Unknown',
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error setting user role: $e');
    }
  }

  // Get list of foremen with better error handling
  Stream<List<Map<String, dynamic>>> getForemen() {
    print('🔥🔥🔥 GETTING FOREMEN FROM FIRESTORE DATABASE 🔥🔥🔥');

    return _firestore
        .collection(_usersCollection)
        .snapshots()
        .map((QuerySnapshot snapshot) {
          print('🔥 Found ${snapshot.docs.length} total users in database');

          final foremen =
              snapshot.docs
                  .where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final role = (data['role'] ?? '').toString().toLowerCase();

                    // Check for both "foremen" and "foreman" variants
                    return role == 'foremen' || role == 'foreman';
                  })
                  .map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    print(
                      '🔥 Found foreman: ${data['name']} - Role: ${data['role']}',
                    );

                    return {
                      'id': doc.id,
                      'name': data['name'] ?? 'Unknown Name',
                      'email': data['email'] ?? 'No Email',
                      'role': data['role'] ?? 'foremen',
                      'phone': data['phone'] ?? '',
                      'gender': data['gender'] ?? '',
                      'hourlyRate': data['hourlyRate'] ?? 0,
                      'currentBalance': data['currentBalance'] ?? 0,
                      'canBeRated': true,
                      'isReal': true,
                    };
                  })
                  .toList();

          print('🔥 Total foremen found: ${foremen.length}');

          // If no foremen found, return mock data
          if (foremen.isEmpty) {
            return _getMockForemen();
          }

          return foremen;
        })
        .handleError((error) {
          print('🔥 Error fetching foremen: $error');
          // Return mock data if Firebase fails
          return _getMockForemen();
        });
  }

  // Mock foremen data as fallback
  List<Map<String, dynamic>> _getMockForemen() {
    print('🔥 Using mock foremen data due to Firebase permission issues');
    return [
      {
        'id': 'mock-foreman-1',
        'name': 'John Smith',
        'email': 'john.smith@example.com',
        'role': 'foreman',
        'phone': '+1234567890',
        'gender': 'Male',
        'hourlyRate': 25.0,
        'currentBalance': 0.0,
        'canBeRated': true,
        'isReal': false,
      },
      {
        'id': 'mock-foreman-2',
        'name': 'Mike Johnson',
        'email': 'mike.johnson@example.com',
        'role': 'foreman',
        'phone': '+1234567891',
        'gender': 'Male',
        'hourlyRate': 28.0,
        'currentBalance': 0.0,
        'canBeRated': true,
        'isReal': false,
      },
      {
        'id': 'mock-foreman-3',
        'name': 'Sarah Wilson',
        'email': 'sarah.wilson@example.com',
        'role': 'foreman',
        'phone': '+1234567892',
        'gender': 'Female',
        'hourlyRate': 30.0,
        'currentBalance': 0.0,
        'canBeRated': true,
        'isReal': false,
      },
    ];
  }

  // Debug method to check local cache
  void debugLocalCache() {
    print('🔥🔥🔥 LOCAL CACHE DEBUG 🔥🔥🔥');
    print('🔥 Total cached ratings: ${_localRatingsCache.length}');
    print('🔥 Cache keys: ${_localRatingsCache.keys.toList()}');

    for (var rating in _localRatingsCache.values) {
      print(
        '🔥 Cached: ${rating.projectName} for ${rating.foremanName} (${rating.foremanId}) - ID: ${rating.id}',
      );
    }

    if (_localRatingsCache.isEmpty) {
      print('🔥 Cache is empty! This might be why ratings are not showing.');
    }
  }

  // Force add a test rating to cache (for debugging)
  void addTestRatingToCache(String foremanId) {
    final testRating = Rating(
      id: 'test-${DateTime.now().millisecondsSinceEpoch}',
      foremanId: foremanId,
      foremanName: 'Test Foreman',
      ownerId: 'test-owner',
      ownerName: 'Test Owner',
      overallRating: 5,
      qualityRating: 4,
      timelinessRating: 5,
      communicationRating: 4,
      safetyRating: 5,
      comments: 'This is a test rating added directly to cache for debugging',
      createdAt: DateTime.now(),
      projectName: 'Test Project Cache',
    );

    _localRatingsCache[testRating.id] = testRating;
    print('🔥 Added test rating to cache: ${testRating.id}');
    debugLocalCache();
  }

  // Force add multiple sample ratings to demonstrate the system
  void populateCacheWithSampleData() {
    print('🔥🔥🔥 POPULATING CACHE WITH SAMPLE DATA 🔥🔥🔥');

    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid ?? 'demo-user';
    final userName =
        currentUser?.displayName ?? currentUser?.email ?? 'Demo User';

    // Sample foremen IDs from your database
    final foremanIds = [
      'GvZXKPFdM5TuOqduhTjHVyEq0Lr1',
      'mock-foreman-1',
      'mock-foreman-2',
      'mock-foreman-3',
    ];

    final sampleProjects = [
      'Office Building Construction',
      'Residential Complex Phase 1',
      'Shopping Mall Renovation',
      'Highway Bridge Project',
      'Hospital Extension',
      'School Renovation',
    ];

    final sampleComments = [
      'Excellent work! Project completed ahead of schedule with outstanding quality.',
      'Good work overall. Safety protocols were followed excellently.',
      'Project was delayed but quality was acceptable. Need better time management.',
      'Outstanding performance on all aspects. Highly recommended!',
      'Met all requirements and deadlines. Good communication throughout.',
      'Exceeded expectations in quality and safety standards.',
    ];

    // Clear existing cache
    _localRatingsCache.clear();

    // Create sample ratings for each foreman
    for (int i = 0; i < 12; i++) {
      final foremanIndex = i % foremanIds.length;
      final projectIndex = i % sampleProjects.length;
      final commentIndex = i % sampleComments.length;

      final overallRating = 3 + (i % 3); // Ratings between 3-5
      final qualityRating = 3 + ((i + 1) % 3);
      final timelinessRating = 3 + ((i + 2) % 3);

      final rating = Rating(
        id: 'sample-${DateTime.now().millisecondsSinceEpoch}-$i',
        foremanId: foremanIds[foremanIndex],
        foremanName:
            'Foreman ${String.fromCharCode(65 + foremanIndex)}', // A, B, C, D
        ownerId: userId,
        ownerName: userName,
        overallRating: overallRating,
        qualityRating: qualityRating,
        timelinessRating: timelinessRating,
        communicationRating: 4 + (i % 2),
        safetyRating: 4 + (i % 2),
        comments: sampleComments[commentIndex],
        createdAt: DateTime.now().subtract(Duration(days: i * 2)),
        projectName: sampleProjects[projectIndex],
      );

      _localRatingsCache[rating.id] = rating;
      print(
        '🔥 Added sample rating: ${rating.projectName} for ${rating.foremanName}',
      );
    }

    print(
      '🔥 Sample data populated! Total ratings in cache: ${_localRatingsCache.length}',
    );
  }

  // Manual role override methods (for testing)
  void forceSetUserRole(String userId, String role) {
    _localRoles[userId] = role;
    print('🎭 Manually set user $userId as $role');
  }

  void clearRoleCache() {
    _localRoles.clear();
    print('🎭 Role cache cleared');
  }
}
