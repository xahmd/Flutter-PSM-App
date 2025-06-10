import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'payment_amount_page.dart';

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

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Set Hourly Rate for $foremenName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: rateController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Hourly Rate (RM)',
                  prefixText: 'RM ',
                  hintText: 'Enter hourly rate',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final newRate = double.tryParse(rateController.text);
                if (newRate != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(foremenId)
                      .update({'hourlyRate': newRate});
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Hourly rate updated for $foremenName')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid rate')),
                  );
                }
              },
              child: const Text('Save'),
            ),
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
                    'Payment History - $foremenName',
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
                    .collection('payments')
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
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      final payment = payments[index].data() as Map<String, dynamic>;
                      final amount = (payment['amount'] as num).toDouble();
                      final timestamp = (payment['timestamp'] as Timestamp).toDate();
                      final paymentMethod = payment['paymentMethod'] as String;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'RM ${amount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      paymentMethod,
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${timestamp.day}/${timestamp.month}/${timestamp.year}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Hourly Rate: ${foremanData['hourlyRate'] != null ? 'RM ${(foremanData['hourlyRate'] as num).toStringAsFixed(2)}' : 'Not set'}',
                                  style: TextStyle(
                                    color: foremanData['hourlyRate'] != null ? Colors.black87 : Colors.grey,
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
                                    label: const Text('Pay'),
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