import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus {
  initiated,  // Owner has initiated the payment
  pending,    // Foreman has acknowledged and payment is pending
  paid,       // Payment has been completed
  cancelled   // Payment was cancelled
}

class PaymentStatusModel {
  final String id;
  final String foremenId;
  final String foremenName;
  final String ownerId;
  final String ownerEmail;
  final double amount;
  final DateTime? timestamp;
  final PaymentStatus status;
  final String? paymentMethod;
  final String? transactionId;

  PaymentStatusModel({
    required this.id,
    required this.foremenId,
    required this.foremenName,
    required this.ownerId,
    required this.ownerEmail,
    required this.amount,
    this.timestamp,
    required this.status,
    this.paymentMethod,
    this.transactionId,
  });

  factory PaymentStatusModel.fromMap(String id, Map<String, dynamic> map) {
    return PaymentStatusModel(
      id: id,
      foremenId: map['foremenId'] as String,
      foremenName: map['foremenName'] as String,
      ownerId: map['ownerId'] as String,
      ownerEmail: map['ownerEmail'] as String,
      amount: (map['amount'] as num).toDouble(),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate(),
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => PaymentStatus.initiated,
      ),
      paymentMethod: map['paymentMethod'] as String?,
      transactionId: map['transactionId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'foremenId': foremenId,
      'foremenName': foremenName,
      'ownerId': ownerId,
      'ownerEmail': ownerEmail,
      'amount': amount,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : null,
      'status': status.toString().split('.').last,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
    };
  }

  PaymentStatusModel copyWith({
    String? id,
    String? foremenId,
    String? foremenName,
    String? ownerId,
    String? ownerEmail,
    double? amount,
    DateTime? timestamp,
    PaymentStatus? status,
    String? paymentMethod,
    String? transactionId,
  }) {
    return PaymentStatusModel(
      id: id ?? this.id,
      foremenId: foremenId ?? this.foremenId,
      foremenName: foremenName ?? this.foremenName,
      ownerId: ownerId ?? this.ownerId,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
    );
  }
} 