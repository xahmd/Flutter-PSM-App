import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/payment_status.dart';

class ForemenPaymentPage extends StatelessWidget {
  const ForemenPaymentPage({super.key});

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '--/--/---- --:--'; // Placeholder for null timestamp
    }
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildPaymentStatusChip(PaymentStatus status) {
    Color color;
    String text;

    switch (status) {
      case PaymentStatus.initiated:
        color = Colors.blue;
        text = 'Initiated';
        break;
      case PaymentStatus.pending:
        color = Colors.amber;
        text = 'Pending';
        break;
      case PaymentStatus.paid:
        color = Colors.green;
        text = 'Paid';
        break;
      case PaymentStatus.cancelled:
        color = Colors.red;
        text = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view payments')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Payments'),
        backgroundColor: Colors.deepOrange,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.hasError) {
            return Center(child: Text('Error: ${userSnapshot.error}'));
          }

          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
          final currentBalance = (userData?['currentBalance'] as num?)?.toDouble() ?? 0.0;
          final hourlyRate = (userData?['hourlyRate'] as num?)?.toDouble();

          return Column(
            children: [
              // Balance Card
              Card(
                margin: const EdgeInsets.all(16),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Current Balance',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'RM ${currentBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                      if (hourlyRate != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Hourly Rate: RM ${hourlyRate.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Payment History
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Payment History',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Payment List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('owner_payments')
                      .where('foremenId', isEqualTo: currentUser.uid)
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final payments = snapshot.data?.docs ?? [];

                    if (payments.isEmpty) {
                      return const Center(
                        child: Text(
                          'No payment history yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: payments.length,
                      itemBuilder: (context, index) {
                        final payment = payments[index].data() as Map<String, dynamic>;
                        final amount = payment['amount'] as double;
                        final status = payment['status'] as String;
                        final timestamp = payment['timestamp'] as Timestamp?;
                        final ownerName = payment['ownerName'] as String? ?? 'Unknown Owner';
                        final ownerEmail = payment['ownerEmail'] as String?;

                        PaymentStatus paymentStatus;
                        if (status.contains('paid')) {
                            paymentStatus = PaymentStatus.paid;
                        } else if (status.contains('cancelled')) {
                            paymentStatus = PaymentStatus.cancelled;
                        } else if (status.contains('initiated')) {
                            paymentStatus = PaymentStatus.initiated;
                        } else {
                            paymentStatus = PaymentStatus.pending;
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: paymentStatus == PaymentStatus.paid
                                  ? Colors.green.shade50
                                  : paymentStatus == PaymentStatus.initiated
                                      ? Colors.blue.shade50
                                      : paymentStatus == PaymentStatus.cancelled
                                          ? Colors.red.shade50
                                          : Colors.amber.shade50,
                              child: Icon(
                                paymentStatus == PaymentStatus.paid
                                    ? Icons.check_circle
                                    : paymentStatus == PaymentStatus.initiated
                                        ? Icons.pending_actions
                                        : paymentStatus == PaymentStatus.cancelled
                                            ? Icons.cancel
                                            : Icons.payment,
                                color: paymentStatus == PaymentStatus.paid
                                    ? Colors.green
                                    : paymentStatus == PaymentStatus.initiated
                                        ? Colors.blue
                                        : paymentStatus == PaymentStatus.cancelled
                                            ? Colors.red
                                            : Colors.amber,
                              ),
                            ),
                            title: Text(
                              'RM ${amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatDate(timestamp?.toDate()),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                _buildPaymentStatusChip(paymentStatus),
                                if (ownerEmail != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'From: $ownerEmail',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Payment Statistics
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('owner_payments')
                      .where('foremenId', isEqualTo: currentUser.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox.shrink();
                    }

                    final payments = snapshot.data?.docs ?? [];
                    final totalPayments = payments.length;
                    
                    // Calculate total received from paid payments only
                    final totalAmount = payments.fold<double>(
                      0,
                      (sum, payment) {
                        final paymentData = payment.data() as Map<String, dynamic>;
                        final status = paymentData['status'] as String;
                        if (status.contains('paid')) {
                          return sum + (paymentData['amount'] as num).toDouble();
                        }
                        return sum;
                      },
                    );

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatistic('Total Payments', totalPayments.toString()),
                        _buildStatistic(
                          'Total Received',
                          'RM ${totalAmount.toStringAsFixed(2)}',
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatistic(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
} 