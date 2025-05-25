class Rating {
  final String id;
  final String workerId;
  final String workerName;
  final String ownerId;
  final String ownerName;
  final int overallRating;
  final int technicalRating;
  final int timelinessRating;
  final int communicationRating;
  final int safetyRating;
  final String comments;
  final DateTime createdAt;
  final String projectName;

  Rating({
    required this.id,
    required this.workerId,
    required this.workerName,
    required this.ownerId,
    required this.ownerName,
    required this.overallRating,
    required this.technicalRating,
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
      workerId: json['workerId'] ?? '',
      workerName: json['workerName'] ?? '',
      ownerId: json['ownerId'] ?? '',
      ownerName: json['ownerName'] ?? '',
      overallRating: json['overallRating'] ?? 0,
      technicalRating: json['technicalRating'] ?? 0,
      timelinessRating: json['timelinessRating'] ?? 0,
      communicationRating: json['communicationRating'] ?? 0,
      safetyRating: json['safetyRating'] ?? 0,
      comments: json['comments'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      projectName: json['projectName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workerId': workerId,
      'workerName': workerName,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'overallRating': overallRating,
      'technicalRating': technicalRating,
      'timelinessRating': timelinessRating,
      'communicationRating': communicationRating,
      'safetyRating': safetyRating,
      'comments': comments,
      'createdAt': createdAt.toIso8601String(),
      'projectName': projectName,
    };
  }

  double get averageRating {
    return (overallRating + technicalRating + timelinessRating + 
            communicationRating + safetyRating) / 5.0;
  }
}
