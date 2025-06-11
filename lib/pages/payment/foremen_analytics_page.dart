import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/payment_status.dart';

class ForemenAnalyticsPage extends StatelessWidget {
  const ForemenAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view analytics')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Analytics'),
        backgroundColor: Colors.deepOrange,
      ),
      body: StreamBuilder<QuerySnapshot>(
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
                'No payment data available for analytics',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverviewCard(payments),
                const SizedBox(height: 16),
                _buildStatusDistributionCard(payments),
                const SizedBox(height: 16),
                _buildMonthlySummaryCard(payments),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewCard(List<QueryDocumentSnapshot> payments) {
    final totalAmount = payments.fold<double>(
      0,
      (sum, payment) {
        final data = payment.data() as Map<String, dynamic>;
        return sum + (data['amount'] as num).toDouble();
      },
    );

    final paidAmount = payments.fold<double>(
      0,
      (sum, payment) {
        final data = payment.data() as Map<String, dynamic>;
        final status = data['status'] as String;
        if (status.contains('paid')) {
          return sum + (data['amount'] as num).toDouble();
        }
        return sum;
      },
    );

    final averageAmount = totalAmount / payments.length;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatisticRow('Total Payments', payments.length.toString()),
            _buildStatisticRow('Total Amount', 'RM ${totalAmount.toStringAsFixed(2)}'),
            _buildStatisticRow('Paid Amount', 'RM ${paidAmount.toStringAsFixed(2)}'),
            _buildStatisticRow('Average Payment', 'RM ${averageAmount.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDistributionCard(List<QueryDocumentSnapshot> payments) {
    final statusCounts = <PaymentStatus, int>{};
    for (var payment in payments) {
      final data = payment.data() as Map<String, dynamic>;
      final status = data['status'] as String;
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
      statusCounts[paymentStatus] = (statusCounts[paymentStatus] ?? 0) + 1;
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Status Distribution',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...statusCounts.entries.map((entry) {
              final color = entry.key == PaymentStatus.paid
                  ? Colors.green
                  : entry.key == PaymentStatus.pending
                      ? Colors.amber
                      : entry.key == PaymentStatus.initiated
                          ? Colors.blue
                          : Colors.red;
              final percentage = (entry.value / payments.length * 100).toStringAsFixed(1);
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              entry.key.toString().split('.').last,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '$percentage%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: entry.value / payments.length,
                      backgroundColor: color.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${entry.value} payments',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlySummaryCard(List<QueryDocumentSnapshot> payments) {
    final Map<String, double> monthlyTotals = {};
    for (var payment in payments) {
      final data = payment.data() as Map<String, dynamic>;
      final timestamp = data['timestamp'] as Timestamp?;
      if (timestamp != null) {
        final date = timestamp.toDate();
        final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        final amount = (data['amount'] as num).toDouble();
        monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0) + amount;
      }
    }

    final sortedMonths = monthlyTotals.keys.toList()..sort();
    sortedMonths.sort((a, b) => b.compareTo(a)); // Sort in descending order

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedMonths.take(6).map((month) {
              final year = month.substring(0, 4);
              final monthNum = int.parse(month.substring(5));
              final monthName = DateTime(2000, monthNum, 1).toString().substring(4, 7);
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$monthName $year',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'RM ${monthlyTotals[month]!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: monthlyTotals[month]! / monthlyTotals[sortedMonths.first]!,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.deepOrange,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
} 