import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DuitNowPaymentPage extends StatelessWidget {
  final String foremenId;
  final String foremenName;
  final double amount;
  final double currentBalance;

  const DuitNowPaymentPage({
    super.key,
    required this.foremenId,
    required this.foremenName,
    required this.amount,
    required this.currentBalance,
  });

  Future<void> _processPayment(BuildContext context) async {
    try {
      final owner = FirebaseAuth.instance.currentUser;
      final batch = FirebaseFirestore.instance.batch();
      
      // Update foreman's balance
      final foremanRef = FirebaseFirestore.instance
          .collection('users')
          .doc(foremenId);
      batch.update(foremanRef, {'currentBalance': currentBalance + amount});
      
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
        'paymentMethod': 'DuitNow QR',
        'status': 'completed'
      });
      
      await batch.commit();
      
      if (context.mounted) {
        // Navigate to success page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentSuccessPage(
              amount: amount,
              foremenName: foremenName,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing payment: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DuitNow QR Payment'),
        backgroundColor: Colors.deepOrange,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Payment to: $foremenName',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Amount: RM ${amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/qr.jpg',
                    height: 300,
                    width: 300,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Scan the QR code with your banking app',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _processPayment(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Payment Sent',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentSuccessPage extends StatelessWidget {
  final double amount;
  final String foremenName;

  const PaymentSuccessPage({
    super.key,
    required this.amount,
    required this.foremenName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 100,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Payment Successful!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'RM ${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'has been sent to $foremenName',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate back to the owner payment page
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      // If we're not already on the owner payment page, navigate to it
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 18,
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
} 