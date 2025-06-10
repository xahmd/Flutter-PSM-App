import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/payment_status.dart';
import 'payment_amount_page.dart';
import 'card_payment_page.dart';
import 'duitnow_payment_page.dart';

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
        color = Colors.orange;
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

    return Chip(
      label: Text(
        text,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
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

  Widget _buildInitiatedPaymentsSection(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('owner_payments')
          .where('status', isEqualTo: 'PaymentStatus.initiated')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Error in initiated payments: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final payments = snapshot.data?.docs ?? [];
        print('Number of initiated payments: ${payments.length}');
        
        // Sort payments by timestamp in memory (if orderBy is removed due to index issue)
        // payments.sort((a, b) {
        //   final aData = a.data() as Map<String, dynamic>;
        //   final bData = b.data() as Map<String, dynamic>;
        //   final aTimestamp = (aData['timestamp'] as Timestamp).toDate();
        //   final bTimestamp = (bData['timestamp'] as Timestamp).toDate();
        //   return bTimestamp.compareTo(aTimestamp); // Descending order
        // });

        if (payments.isEmpty) {
          print('No initiated payments found');
          return const SizedBox.shrink();
        }

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
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: payments.length,
                itemBuilder: (context, index) {
                  final payment = payments[index].data() as Map<String, dynamic>;
                  print('Payment data: $payment');
                  final paymentModel = PaymentStatusModel.fromMap(
                    payments[index].id,
                    payment,
                  );

                  return Container(
                    width: 300,
                    margin: const EdgeInsets.only(left: 16, right: 8),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.deepOrange.shade50,
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.deepOrange,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    paymentModel.foremenName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Amount: RM ${paymentModel.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Date: ${paymentModel.timestamp?.day ?? '--'}/${paymentModel.timestamp?.month ?? '--'}/${paymentModel.timestamp?.year ?? '----'}',
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _handlePaymentMethod(context, paymentModel),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepOrange,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Pay Now'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _cancelPayment(context, paymentModel.id),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                    ),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 32),
          ],
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
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('owner_payments')
                    .where('foremenId', isEqualTo: foremenId)
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
                            backgroundColor: Colors.deepOrange.shade50,
                            child: Icon(
                              paymentModel.paymentMethod == 'DuitNow QR'
                                  ? Icons.qr_code
                                  : Icons.credit_card,
                              color: Colors.deepOrange,
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
                              Text(
                                '${paymentModel.timestamp?.day ?? '--'}/${paymentModel.timestamp?.month ?? '--'}/${paymentModel.timestamp?.year ?? '----'}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              _buildPaymentStatusChip(paymentModel.status),
                            ],
                          ),
                          trailing: paymentModel.status == PaymentStatus.initiated || paymentModel.status == PaymentStatus.pending
                              ? ElevatedButton(
                                  onPressed: () => _cancelPayment(context, paymentModel.id),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Cancel'),
                                )
                              : Text(
                                  paymentModel.paymentMethod ?? 'N/A',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  );
                },
              ),
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
                                    fontSize: 13,
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