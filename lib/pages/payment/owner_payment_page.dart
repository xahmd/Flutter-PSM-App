import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'duitnow_payment_page.dart';

class OwnerPaymentPage extends StatelessWidget {
  const OwnerPaymentPage({super.key});

  Future<void> _handlePayment(BuildContext context, String foremenId, String foremenName, double currentBalance) async {
    final amountController = TextEditingController();
    String selectedPaymentMethod = 'duitnow';

    // Show payment confirmation dialog
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Pay $foremenName'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount (RM)',
                      prefixText: 'RM ',
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Select Payment Method:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  RadioListTile<String>(
                    title: Row(
                      children: [
                        Image.asset(
                          'assets/images/DuitNow1.jpg',
                          height: 30,
                          width: 30,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 10),
                        const Text('DuitNow QR'),
                      ],
                    ),
                    value: 'duitnow',
                    groupValue: selectedPaymentMethod,
                    onChanged: (value) {
                      setState(() {
                        selectedPaymentMethod = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: Row(
                      children: [
                        Image.asset(
                          'assets/images/card.jpg',
                          height: 30,
                          width: 30,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 10),
                        const Text('Visa/Mastercard'),
                      ],
                    ),
                    value: 'card',
                    groupValue: selectedPaymentMethod,
                    onChanged: (value) {
                      setState(() {
                        selectedPaymentMethod = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final amount = double.tryParse(amountController.text);
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid amount')),
                      );
                      return;
                    }

                    Navigator.pop(context); // Close the dialog first

                    if (selectedPaymentMethod == 'duitnow') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DuitNowPaymentPage(
                            foremenId: foremenId,
                            foremenName: foremenName,
                            amount: amount,
                            currentBalance: currentBalance,
                          ),
                        ),
                      );
                    } else {
                      _processCardPayment(context, foremenId, foremenName, amount, currentBalance);
                    }
                  },
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _processCardPayment(BuildContext context, String foremenId, String foremenName, double amount, double currentBalance) {
    // Show card payment form dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Card Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Card Number',
                  hintText: '1234 5678 9012 3456',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Expiry Date',
                        hintText: 'MM/YY',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'CVV',
                        hintText: '123',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Amount to pay: RM ${amount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
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
                try {
                  // Get current user (owner) details
                  final owner = FirebaseAuth.instance.currentUser;
                  
                  // Start a batch write
                  final batch = FirebaseFirestore.instance.batch();
                  
                  // Update foreman's balance
                  final foremanRef = FirebaseFirestore.instance
                      .collection('users')
                      .doc(foremenId);
                  batch.update(foremanRef, {
                    'currentBalance': currentBalance + amount
                  });
                  
                  // Create payment record
                  final paymentRef = FirebaseFirestore.instance
                      .collection('payments')
                      .doc();
                  batch.set(paymentRef, {
                    'amount': amount,
                    'timestamp': FieldValue.serverTimestamp(),
                    'foremenId': foremenId,
                    'foremenName': foremenName,
                    'ownerId': owner?.uid,
                    'ownerEmail': owner?.email,
                    'paymentMethod': 'Card',
                    'status': 'completed'
                  });
                  
                  // Commit the batch
                  await batch.commit();
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Payment Successful'),
                          content: Text('Payment of RM ${amount.toStringAsFixed(2)} sent to $foremenName'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error processing payment: $e')),
                    );
                  }
                }
              },
              child: const Text('Pay'),
            ),
          ],
        );
      },
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
                        vertical: 8,
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
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              bottom: 16,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _handleHourlyRate(
                                    context,
                                    foreman.id,
                                    foremanName,
                                    foremanData['hourlyRate'] as double?,
                                  ),
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Set Rate'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.deepOrange,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
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