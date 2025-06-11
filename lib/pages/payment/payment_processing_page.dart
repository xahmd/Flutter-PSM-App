import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/payment_status.dart';
import 'card_payment_page.dart';
import 'duitnow_payment_page.dart';

class PaymentProcessingPage extends StatelessWidget {
  final String paymentId;
  final Map<String, dynamic> paymentData;

  const PaymentProcessingPage({
    super.key,
    required this.paymentId,
    required this.paymentData,
  });

  Future<void> _handlePaymentMethod(BuildContext context) async {
    final result = await showDialog<bool?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Payment Method'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.credit_card, color: Colors.deepOrange),
                title: const Text('Visa/Mastercard'),
                onTap: () async {
                  Navigator.pop(context, await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CardPaymentPage(
                        foremenId: paymentData['foremenId'],
                        foremenName: paymentData['foremenName'],
                        amount: paymentData['amount'],
                        currentBalance: 0.0,
                        paymentId: paymentId,
                      ),
                    ),
                  ));
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_balance, color: Colors.deepOrange),
                title: const Text('DuitNow'),
                onTap: () async {
                  Navigator.pop(context, await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DuitNowPaymentPage(
                        foremenId: paymentData['foremenId'],
                        foremenName: paymentData['foremenName'],
                        amount: paymentData['amount'],
                        currentBalance: 0.0,
                        paymentId: paymentId,
                      ),
                    ),
                  ));
                },
              ),
            ],
          ),
        );
      },
    );

    if (result == true) {
      // Payment successful, update status in Firestore
      await FirebaseFirestore.instance
          .collection('owner_payments')
          .doc(paymentId)
          .update({'status': PaymentStatus.paid.toString().split('.').last});
      
      if (context.mounted) {
        Navigator.pop(context, true); // Return true to indicate successful payment
      }
    }
  }

  Future<void> _markAsPending(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Pending'),
        content: const Text('Are you sure you want to mark this payment as pending?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('owner_payments')
          .doc(paymentId)
          .update({'status': PaymentStatus.pending.toString().split('.').last});
      
      if (context.mounted) {
        Navigator.pop(context, true); // Return true to indicate status change
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Process Payment'),
        backgroundColor: Colors.deepOrange,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepOrange.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Payment Details Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.deepOrange.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.payment,
                                color: Colors.deepOrange,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Payment Details',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildDetailRow(
                          'Foreman',
                          paymentData['foremenName'] ?? 'N/A',
                          Icons.person,
                        ),
                        const Divider(height: 24),
                        _buildDetailRow(
                          'Amount',
                          'RM ${paymentData['amount'].toStringAsFixed(2)}',
                          Icons.attach_money,
                          valueColor: Colors.deepOrange,
                          valueStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const Divider(height: 24),
                        _buildDetailRow(
                          'Date',
                          _formatDate((paymentData['timestamp'] as Timestamp?)?.toDate()),
                          Icons.calendar_today,
                        ),
                        if (paymentData['reference'] != null && paymentData['reference'].toString().isNotEmpty) ...[
                          const Divider(height: 24),
                          _buildDetailRow(
                            'Reference',
                            paymentData['reference'],
                            Icons.receipt,
                            valueStyle: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Action Buttons
                const Text(
                  'Payment Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handlePaymentMethod(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.payment, color: Colors.white),
                        label: const Text(
                          'Pay Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _markAsPending(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.pending_actions, color: Colors.white),
                        label: const Text(
                          'Mark as Pending',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _cancelPayment(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.cancel, color: Colors.white),
                    label: const Text(
                      'Cancel Payment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _cancelPayment(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Payment'),
        content: const Text('Are you sure you want to cancel this payment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('owner_payments')
          .doc(paymentId)
          .update({'status': PaymentStatus.cancelled.toString().split('.').last});
      
      if (context.mounted) {
        Navigator.pop(context, true); // Return true to indicate status change
      }
    }
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
    TextStyle? valueStyle,
  }) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.grey[600]),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ).merge(valueStyle),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 