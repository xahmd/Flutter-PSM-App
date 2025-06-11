import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/payment_status.dart';

class OwnerAnalyticsPage extends StatelessWidget {
  const OwnerAnalyticsPage({super.key});

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

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return 'N/A';
    }
    
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildStatisticsCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Analytics'),
        backgroundColor: Colors.deepOrange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('owner_payments')
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
          
          // Calculate statistics
          double totalPaid = 0;
          double totalPending = 0;
          int totalTransactions = payments.length;
          int paidTransactions = 0;
          int pendingTransactions = 0;

          for (var doc in payments) {
            final payment = doc.data() as Map<String, dynamic>;
            final amount = payment['amount'] as double;
            final status = payment['status'] as String;

            if (status.contains('paid')) {
              totalPaid += amount;
              paidTransactions++;
            } else if (status.contains('pending') || status.contains('initiated')) {
              totalPending += amount;
              pendingTransactions++;
            }
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistics Cards
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      _buildStatisticsCard(
                        'Total Paid',
                        'RM ${totalPaid.toStringAsFixed(2)}',
                        Icons.account_balance_wallet,
                        Colors.green,
                      ),
                      _buildStatisticsCard(
                        'Pending Amount',
                        'RM ${totalPending.toStringAsFixed(2)}',
                        Icons.pending_actions,
                        Colors.amber,
                      ),
                      _buildStatisticsCard(
                        'Total Transactions',
                        totalTransactions.toString(),
                        Icons.receipt_long,
                        Colors.blue,
                      ),
                      _buildStatisticsCard(
                        'Paid Transactions',
                        paidTransactions.toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Transactions List
                  const Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      final payment = payments[index].data() as Map<String, dynamic>;
                      final amount = payment['amount'] as double;
                      final status = payment['status'] as String;
                      final timestamp = payment['timestamp'] as Timestamp?;
                      final foremenName = payment['foremenName'] as String? ?? 'Unknown';
                      final reference = payment['reference'] as String?;
                      final paymentMethod = payment['paymentMethod'] as String?;

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
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
                              const SizedBox(height: 4),
                              Text(
                                foremenName,
                                style: const TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(timestamp),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              if (reference != null && reference.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Ref: $reference',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: _buildPaymentStatusChip(paymentStatus),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 