import 'package:cloud_firestore/cloud_firestore.dart';

class Rating {
  final String id;
  final String foremanId;
  final String foremanName;
  final String ownerId;
  final String ownerName;
  final int overallRating;
  final int qualityRating;
  final int timelinessRating;
  final int communicationRating;
  final int safetyRating;
  final String comments;
  final DateTime createdAt;
  final String projectName;

  Rating({
    required this.id,
    required this.foremanId,
    required this.foremanName,
    required this.ownerId,
    required this.ownerName,
    required this.overallRating,
    required this.qualityRating,
    required this.timelinessRating,
    required this.communicationRating,
    required this.safetyRating,
    required this.comments,
    required this.createdAt,
    required this.projectName,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'] ?? '',
      foremanId: json['foremanId'] ?? '',
      foremanName: json['foremanName'] ?? '',
      ownerId: json['ownerId'] ?? '',
      ownerName: json['ownerName'] ?? '',
      overallRating: json['overallRating'] ?? 0,
      qualityRating: json['qualityRating'] ?? 0,
      timelinessRating: json['timelinessRating'] ?? 0,
      communicationRating: json['communicationRating'] ?? 0,
      safetyRating: json['safetyRating'] ?? 0,
      comments: json['comments'] ?? '',
      createdAt: _parseDateTime(json['createdAt']),
      projectName: json['projectName'] ?? '',
    );
  }

  // Helper method to parse various date formats
  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();

    try {
      if (dateValue is String) {
        // Handle ISO string format
        return DateTime.parse(dateValue);
      } else if (dateValue is Timestamp) {
        // Handle Firestore Timestamp
        return dateValue.toDate();
      } else if (dateValue is int) {
        // Handle milliseconds since epoch
        return DateTime.fromMillisecondsSinceEpoch(dateValue);
      } else {
        print('Unknown date format: $dateValue (${dateValue.runtimeType})');
        return DateTime.now();
      }
    } catch (e) {
      print(' Error parsing date $dateValue: $e');
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'foremanId': foremanId,
      'foremanName': foremanName,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'overallRating': overallRating,
      'qualityRating': qualityRating,
      'timelinessRating': timelinessRating,
      'communicationRating': communicationRating,
      'safetyRating': safetyRating,
      'comments': comments,
      'createdAt': createdAt.toIso8601String(),
      'projectName': projectName,
      'averageRating': averageRating, // Add this line
    };
  }

  double get averageRating {
    return (overallRating +
            qualityRating +
            timelinessRating +
            communicationRating +
            safetyRating) /
        5.0;
  }
}
