import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/payment_status.dart';
import 'payment_success_page.dart';

class DuitNowPaymentPage extends StatefulWidget {
  final String foremenId;
  final String foremenName;
  final double amount;
  final double currentBalance;
  final String paymentId;

  const DuitNowPaymentPage({
    super.key,
    required this.foremenId,
    required this.foremenName,
    required this.amount,
    required this.currentBalance,
    required this.paymentId,
  });

  @override
  State<DuitNowPaymentPage> createState() => _DuitNowPaymentPageState();
}

class _DuitNowPaymentPageState extends State<DuitNowPaymentPage> {
  bool _isProcessing = false;

  Future<void> _processPayment(BuildContext context) async {
    setState(() => _isProcessing = true);

    try {
      // Add artificial delay to simulate payment processing
      await Future.delayed(const Duration(seconds: 3));

      final owner = FirebaseAuth.instance.currentUser;
      final batch = FirebaseFirestore.instance.batch();
      
      // Update foreman's balance
      final foremanRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.foremenId);
      batch.update(foremanRef, {'currentBalance': FieldValue.increment(widget.amount)});
      
      // Update existing payment record
      final paymentRef = FirebaseFirestore.instance
          .collection('owner_payments')
          .doc(widget.paymentId);
      batch.update(paymentRef, {
        'status': PaymentStatus.paid.toString().split('.').last,
        'paymentMethod': 'DuitNow QR',
      });
      
      await batch.commit();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing payment: $e')),
        );
        Navigator.pop(context, false);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
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
                        'Payment to: ${widget.foremenName}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Amount: RM ${widget.amount.toStringAsFixed(2)}',
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
                  onPressed: _isProcessing ? null : () => _processPayment(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
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