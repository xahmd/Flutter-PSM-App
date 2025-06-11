import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_sepg10/pages/models/schedule.dart';

class AvailableSlotsPage extends StatefulWidget {
  final String foremanId;

  const AvailableSlotsPage({Key? key, required this.foremanId}) : super(key: key);

  @override
  _AvailableSlotsPageState createState() => _AvailableSlotsPageState();
}

class _AvailableSlotsPageState extends State<AvailableSlotsPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? startDate;
  DateTime? endDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  final TextEditingController _remarksController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _saveAvailableSlot() async {
    if (!_formKey.currentState!.validate()) return;
    if (startDate == null || endDate == null || startTime == null || endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create schedule
      Schedule schedule = Schedule(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        foremanId: widget.foremanId,
        startDate: startDate!,
        endDate: endDate!,
        startTime: startTime!,
        endTime: endTime!,
        remarks: _remarksController.text,
        timeSlot: '${startTime!.format(context)} - ${endTime!.format(context)}',
        isAvailable: true,
      );

      await FirebaseFirestore.instance
          .collection('foreman_schedules')
          .doc(schedule.id)
          .set(schedule.toMap());

      // Reset form
      setState(() {
        startDate = null;
        endDate = null;
        startTime = null;
        endTime = null;
        _remarksController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Available slot saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving slot: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteSlot(String slotId) async {
    try {
      await FirebaseFirestore.instance.collection('foreman_schedules').doc(slotId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Slot deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting slot: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDatePicker(
    String label,
    DateTime? selectedDate,
    Function(DateTime) onDateSelected,
  ) {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          selectedDate != null
              ? DateFormat('MMM d, y').format(selectedDate)
              : 'Select date',
        ),
      ),
    );
  }

  Widget _buildTimePicker(
    String label,
    TimeOfDay? selectedTime,
    Function(TimeOfDay) onTimeSelected,
  ) {
    return InkWell(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (picked != null) {
          onTimeSelected(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          suffixIcon: const Icon(Icons.access_time),
        ),
        child: Text(
          selectedTime != null
              ? selectedTime.format(context)
              : 'Select time',
        ),
      ),
    );
  }

  Widget _buildAvailableSlotsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('foreman_schedules')
          .where('foremanId', isEqualTo: widget.foremanId)
          .where('isAvailable', isEqualTo: true)
          .orderBy('startDate', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final slots = snapshot.data?.docs ?? [];

        if (slots.isEmpty) {
          return const Center(
            child: Text(
              'No available slots found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: slots.length,
          itemBuilder: (context, index) {
            final slot = slots[index].data() as Map<String, dynamic>;
            final schedule = Schedule.fromMap(slot);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  '${DateFormat('MMM d, y').format(schedule.startDate)} - ${DateFormat('MMM d, y').format(schedule.endDate)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Time: ${schedule.timeSlot}',
                      style: const TextStyle(
                        color: Colors.deepOrange,
                      ),
                    ),
                    if (schedule.remarks?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Remarks: ${schedule.remarks}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteSlot(schedule.id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Slots'),
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Add Available Slot',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        _buildDatePicker(
                          'Start Date',
                          startDate,
                          (date) => setState(() => startDate = date),
                        ),
                        const SizedBox(height: 15),
                        _buildDatePicker(
                          'End Date',
                          endDate,
                          (date) => setState(() => endDate = date),
                        ),
                        const SizedBox(height: 15),
                        _buildTimePicker(
                          'Start Time',
                          startTime,
                          (time) => setState(() => startTime = time),
                        ),
                        const SizedBox(height: 15),
                        _buildTimePicker(
                          'End Time',
                          endTime,
                          (time) => setState(() => endTime = time),
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _remarksController,
                          decoration: const InputDecoration(
                            labelText: 'Remarks (Optional)',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _saveAvailableSlot,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Save Available Slot',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Your Available Slots',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
              const SizedBox(height: 10),
              _buildAvailableSlotsList(),
            ],
          ),
        ),
      ),
    );
  }
} 