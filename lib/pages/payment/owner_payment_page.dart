import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/payment_status.dart';
import 'payment_amount_page.dart';
import 'card_payment_page.dart';
import 'duitnow_payment_page.dart';
import 'owner_analytics_page.dart';
import 'payment_processing_page.dart';

class OwnerPaymentPage extends StatelessWidget {
  const OwnerPaymentPage({super.key});

  Future<void> _handlePayment(BuildContext context, String foremenId, String foremenName, double currentBalance) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentAmountPage(
          foremenId: foremenId,
          foremenName: foremenName,
          currentBalance: currentBalance,
        ),
      ),
    );
  }

  Future<void> _handleHourlyRate(BuildContext context, String foremenId, String foremenName, double? currentRate) async {
    final TextEditingController rateController = TextEditingController(
      text: currentRate?.toString() ?? '',
    );

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Hourly Rate'),
        content: TextField(
                controller: rateController,
          keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Hourly Rate (RM)',
                  prefixText: 'RM ',
              ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
              final rate = double.tryParse(rateController.text);
              if (rate != null && rate > 0) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(foremenId)
                    .update({'hourlyRate': rate});
                  if (context.mounted) {
                    Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Hourly rate updated successfully')),
                  );
                }
                }
              },
              child: const Text('Save'),
            ),
        ],
      ),
    );
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

  Future<void> _handlePaymentMethod(BuildContext context, PaymentStatusModel payment) async {
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
                        foremenId: payment.foremenId,
                        foremenName: payment.foremenName,
                        amount: payment.amount,
                        currentBalance: 0.0, // This will be updated in the payment page
                        paymentId: payment.id,
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
                        foremenId: payment.foremenId,
                        foremenName: payment.foremenName,
                        amount: payment.amount,
                        currentBalance: 0.0, // This will be updated in the payment page
                        paymentId: payment.id,
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
          .doc(payment.id)
          .update({'status': PaymentStatus.paid.toString().split('.').last});
    }
  }

  Future<void> _cancelPayment(BuildContext context, String paymentId) async {
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
      try {
        await FirebaseFirestore.instance
            .collection('owner_payments')
            .doc(paymentId)
            .update({'status': PaymentStatus.cancelled.toString().split('.').last});
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment cancelled successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error cancelling payment: ${e}')),
          );
        }
      }
    }
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

  Widget _buildInitiatedPaymentsSection(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('owner_payments')
          .where('status', whereIn: ['initiated', 'pending'])
          .orderBy('status')
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
          return const SizedBox.shrink();
        }

        // Separate payments by status
        final initiatedPayments = payments.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] as String;
          return status == 'initiated';
        }).toList();

        final pendingPayments = payments.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] as String;
          return status == 'pending';
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Pending Payments',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              height: 220,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Show initiated payments first
                  ...initiatedPayments.map((doc) {
                    final payment = doc.data() as Map<String, dynamic>;
                    final paymentModel = PaymentStatusModel.fromMap(
                      doc.id,
                      payment,
                    );
                    return _buildPaymentCard(
                      context,
                      payment,
                      paymentModel,
                      true,
                      Colors.blue,
                    );
                  }).toList(),
                  // Then show pending payments
                  ...pendingPayments.map((doc) {
                    final payment = doc.data() as Map<String, dynamic>;
                    final paymentModel = PaymentStatusModel.fromMap(
                      doc.id,
                      payment,
                    );
                    return _buildPaymentCard(
                      context,
                      payment,
                      paymentModel,
                      false,
                      Colors.orange,
                    );
                  }).toList(),
                ],
              ),
            ),
            const Divider(height: 32),
          ],
        );
      },
    );
  }

  Widget _buildPaymentCard(
    BuildContext context,
    Map<String, dynamic> payment,
    PaymentStatusModel paymentModel,
    bool isInitiated,
    Color statusColor,
  ) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(left: 16, right: 8),
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentProcessingPage(
                  paymentId: paymentModel.id,
                  paymentData: payment,
                ),
              ),
            );

            if (result == true && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment status updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          child: Stack(
            children: [
              // Status indicator line
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      bottomLeft: Radius.circular(4),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.deepOrange.shade50,
                          child: const Icon(
                            Icons.person,
                            color: Colors.deepOrange,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            paymentModel.foremenName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'RM ${paymentModel.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(payment['timestamp']),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    if (payment['reference'] != null && payment['reference'].toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Ref: ${payment['reference']}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isInitiated ? 'Initiated' : 'Pending',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.touch_app,
                              color: Colors.deepOrange,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Tap to process',
                              style: TextStyle(
                                color: Colors.deepOrange,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentHistorySection(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('owner_payments')
          .where('status', whereIn: ['paid', 'cancelled'])
          .orderBy('status')
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
            final paymentModel = PaymentStatusModel.fromMap(
              payments[index].id,
              payment,
            );

            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: paymentModel.status == PaymentStatus.paid
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  child: Icon(
                    paymentModel.status == PaymentStatus.paid
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: paymentModel.status == PaymentStatus.paid
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                title: Text(
                  'RM ${paymentModel.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      paymentModel.foremenName,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(paymentModel.timestamp),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    if (payment['reference'] != null && payment['reference'].toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Ref: ${payment['reference']}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: _buildPaymentStatusChip(paymentModel.status),
              ),
            );
          },
        );
      },
    );
  }

  void _showPaymentDetails(BuildContext context, String foremenId, String foremenName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepOrange,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Payment History - ${foremenName}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildPaymentHistorySection(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showForemanDetails(BuildContext context, String foremenId, String foremenName, Map<String, dynamic> foremanData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepOrange,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Foreman Details - $foremenName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailCard(
                      title: 'Personal Information',
                      children: [
                        _buildDetailRow(
                          icon: Icons.person,
                          label: 'Name',
                          value: foremanData['name'] ?? 'Not set',
                        ),
                        _buildDetailRow(
                          icon: Icons.email,
                          label: 'Email',
                          value: foremanData['email'] ?? 'Not set',
                        ),
                        _buildDetailRow(
                          icon: Icons.phone,
                          label: 'Phone',
                          value: foremanData['phone'] ?? 'Not set',
                        ),
                        _buildDetailRow(
                          icon: Icons.wc,
                          label: 'Gender',
                          value: foremanData['gender'] ?? 'Not set',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDetailCard(
                      title: 'Work Information',
                      children: [
                        _buildDetailRow(
                          icon: Icons.work,
                          label: 'Role',
                          value: foremanData['role'] ?? 'Not set',
                        ),
                        _buildDetailRow(
                          icon: Icons.attach_money,
                          label: 'Hourly Rate',
                          value: foremanData['hourlyRate'] != null 
                              ? 'RM ${(foremanData['hourlyRate'] as num).toStringAsFixed(2)}'
                              : 'Not set',
                        ),
                        _buildDetailRow(
                          icon: Icons.account_balance_wallet,
                          label: 'Current Balance',
                          value: 'RM ${(foremanData['currentBalance'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDetailCard(
                      title: 'Account Information',
                      children: [
                        _buildDetailRow(
                          icon: Icons.calendar_today,
                          label: 'Joining Date',
                          value: foremanData['joiningDate'] != null 
                              ? (foremanData['joiningDate'] as Timestamp).toDate().toString().split(' ')[0]
                              : 'Not set',
                        ),
                        _buildDetailRow(
                          icon: Icons.badge,
                          label: 'Employee ID',
                          value: foremanData['employeeId'] ?? 'Not set',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Payment Management'),
        backgroundColor: Colors.deepOrange,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OwnerAnalyticsPage(),
                ),
              );
            },
            tooltip: 'View Analytics',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInitiatedPaymentsSection(context),
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Foremen List',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'Foremen')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final foremen = snapshot.data?.docs ?? [];

                if (foremen.isEmpty) {
                  return const Center(child: Text('No foremen found'));
                }

                return ListView.builder(
                  itemCount: foremen.length,
                  itemBuilder: (context, index) {
                    final foreman = foremen[index];
                    final foremanData = foreman.data() as Map<String, dynamic>;
                    final foremanName = foremanData['name'] ?? 'Unknown';
                    final currentBalance = (foremanData['currentBalance'] as num?)?.toDouble() ?? 0.0;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.deepOrange,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(foremanName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Balance: RM ${currentBalance.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.deepOrange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Hourly Rate: ${foremanData['hourlyRate'] != null ? 'RM ${(foremanData['hourlyRate'] as num).toStringAsFixed(2)}' : 'Not set'}',
                                  style: TextStyle(
                                    color: foremanData['hourlyRate'] != null ? Colors.black87 : Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => _showForemanDetails(
                                    context,
                                    foreman.id,
                                    foremanName,
                                    foremanData,
                                  ),
                                  icon: const Icon(Icons.person),
                                  color: Colors.deepOrange,
                                  tooltip: 'View Details',
                                ),
                                IconButton(
                                  onPressed: () => _showPaymentDetails(
                                    context,
                                    foreman.id,
                                    foremanName,
                                  ),
                                  icon: const Icon(Icons.visibility),
                                  color: Colors.deepOrange,
                                  tooltip: 'View Payment History',
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                  onPressed: () => _handleHourlyRate(
                                    context,
                                    foreman.id,
                                    foremanName,
                                    foremanData['hourlyRate'] as double?,
                                  ),
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Set Rate'),
                                    style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.deepOrange,
                                      side: const BorderSide(color: Colors.deepOrange),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                  onPressed: () => _handlePayment(
                                    context,
                                    foreman.id,
                                    foremanName,
                                    currentBalance,
                                  ),
                                  icon: const Icon(Icons.payment),
                                    label: const Text('New Payment'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepOrange,
                                    foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 