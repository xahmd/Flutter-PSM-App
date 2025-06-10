import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'card_payment_page.dart';
import 'duitnow_payment_page.dart';

class PaymentAmountPage extends StatefulWidget {
  final String foremenId;
  final String foremenName;
  final double currentBalance;

  const PaymentAmountPage({
    super.key,
    required this.foremenId,
    required this.foremenName,
    required this.currentBalance,
  });

  @override
  State<PaymentAmountPage> createState() => _PaymentAmountPageState();
}

class _PaymentAmountPageState extends State<PaymentAmountPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _hoursController = TextEditingController();
  bool _isAmountMode = true;
  double? _hourlyRate;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHourlyRate();
  }

  Future<void> _loadHourlyRate() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.foremenId)
          .get();
      
      if (mounted) {
        setState(() {
          _hourlyRate = (doc.data()?['hourlyRate'] as num?)?.toDouble();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading hourly rate: $e')),
        );
      }
    }
  }

  void _calculateAmountFromHours() {
    if (_hoursController.text.isNotEmpty && _hourlyRate != null) {
      final hours = double.tryParse(_hoursController.text) ?? 0;
      final amount = hours * _hourlyRate!;
      _amountController.text = amount.toStringAsFixed(2);
    }
  }

  void _handlePayment() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Amount must be greater than 0')),
        );
        return;
      }

      showDialog(
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
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CardPaymentPage(
                          foremenId: widget.foremenId,
                          foremenName: widget.foremenName,
                          amount: amount,
                          currentBalance: widget.currentBalance,
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.account_balance, color: Colors.deepOrange),
                  title: const Text('DuitNow'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DuitNowPaymentPage(
                          foremenId: widget.foremenId,
                          foremenName: widget.foremenName,
                          amount: amount,
                          currentBalance: widget.currentBalance,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Payment Amount'),
        backgroundColor: Colors.deepOrange,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Foreman: ${widget.foremenName}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Current Balance: RM ${widget.currentBalance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.deepOrange,
                          ),
                        ),
                        if (_hourlyRate != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Hourly Rate: RM ${_hourlyRate!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('Enter Amount'),
                                selected: _isAmountMode,
                                onSelected: (selected) {
                                  setState(() {
                                    _isAmountMode = selected;
                                    if (selected) {
                                      _hoursController.clear();
                                    }
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('Enter Hours'),
                                selected: !_isAmountMode,
                                onSelected: (selected) {
                                  setState(() {
                                    _isAmountMode = !selected;
                                    if (selected) {
                                      _amountController.clear();
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_isAmountMode)
                          TextFormField(
                            controller: _amountController,
                            decoration: const InputDecoration(
                              labelText: 'Amount (RM)',
                              prefixText: 'RM ',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an amount';
                              }
                              final amount = double.tryParse(value);
                              if (amount == null || amount <= 0) {
                                return 'Please enter a valid amount';
                              }
                              return null;
                            },
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _hoursController,
                                decoration: const InputDecoration(
                                  labelText: 'Number of Hours',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter number of hours';
                                  }
                                  final hours = double.tryParse(value);
                                  if (hours == null || hours <= 0) {
                                    return 'Please enter valid hours';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  if (value.isNotEmpty) {
                                    _calculateAmountFromHours();
                                  }
                                },
                              ),
                              if (_hourlyRate != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Calculated Amount:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'RM ${_amountController.text.isEmpty ? "0.00" : _amountController.text}',
                                        style: const TextStyle(
                                          color: Colors.deepOrange,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _handlePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Proceed to Payment',
                    style: TextStyle(fontSize: 16),
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