import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_sepg10/pages/models/schedule.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScheduleManagementPage extends StatefulWidget {
  final String foremanId;

  const ScheduleManagementPage({Key? key, required this.foremanId}) : super(key: key);

  @override
  _ScheduleManagementPageState createState() => _ScheduleManagementPageState();
}

class _ScheduleManagementPageState extends State<ScheduleManagementPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? startDate;
  DateTime? endDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  final TextEditingController _remarksController = TextEditingController();
  bool _isLoading = false;
  String? _userRole;
  String? _selectedForemanId;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        setState(() {
          _userRole = userDoc.data()?['role'] as String?;
          if (_userRole == 'Owner') {
            _selectedForemanId = widget.foremanId;
          }
        });
      }
    } catch (e) {
      debugPrint('Error checking user role: $e');
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _saveSchedule() async {
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
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Create schedule
      Schedule schedule = Schedule(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        foremanId: _userRole == 'Owner' ? _selectedForemanId! : widget.foremanId,
        startDate: startDate!,
        endDate: endDate!,
        startTime: startTime!,
        endTime: endTime!,
        remarks: _remarksController.text,
        timeSlot: '${startTime!.format(context)} - ${endTime!.format(context)}',
        isAvailable: false,
        createdBy: currentUser.uid,
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
            content: Text('Schedule saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving schedule: $e'),
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

  Future<void> _createScheduleFromSlot(Schedule slot) async {
    setState(() {
      startDate = slot.startDate;
      endDate = slot.endDate;
      startTime = slot.startTime;
      endTime = slot.endTime;
    });
  }

  Future<void> _deleteSchedule(String scheduleId) async {
    try {
      await FirebaseFirestore.instance.collection('foreman_schedules').doc(scheduleId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting schedule: $e'),
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

  Widget _buildForemanSelector() {
    if (_userRole != 'Owner') return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Foremen')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final foremen = snapshot.data!.docs;
        if (foremen.isEmpty) {
          return const Text('No foremen found');
        }

        return DropdownButtonFormField<String>(
          value: _selectedForemanId,
          decoration: InputDecoration(
            labelText: 'Select Foreman',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          items: foremen.map((foreman) {
            final data = foreman.data() as Map<String, dynamic>;
            return DropdownMenuItem<String>(
              value: foreman.id,
              child: Text(data['name'] ?? 'Unknown Foreman'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedForemanId = value;
            });
          },
        );
      },
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
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (schedule.remarks?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Remarks: ${schedule.remarks}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: () => _createScheduleFromSlot(schedule),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Use This Slot'),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSchedulesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('foreman_schedules')
          .where('foremanId', isEqualTo: widget.foremanId)
          .where('isAvailable', isEqualTo: false)
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

        final schedules = snapshot.data?.docs ?? [];

        if (schedules.isEmpty) {
          return const Center(
            child: Text(
              'No schedules found',
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
          itemCount: schedules.length,
          itemBuilder: (context, index) {
            final schedule = schedules[index].data() as Map<String, dynamic>;
            final scheduleModel = Schedule.fromMap(schedule);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  '${DateFormat('MMM d, y').format(scheduleModel.startDate)} - ${DateFormat('MMM d, y').format(scheduleModel.endDate)}',
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
                      'Time: ${scheduleModel.timeSlot}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (scheduleModel.remarks?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Remarks: ${scheduleModel.remarks}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteSchedule(scheduleModel.id),
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
        title: Text(_userRole == 'Owner' ? 'Manage Foremen Schedules' : 'My Schedule'),
        backgroundColor: Colors.deepOrange,
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_userRole == 'Owner') ...[
                _buildForemanSelector(),
                const SizedBox(height: 16),
              ],
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userRole == 'Owner' ? 'Create New Schedule' : 'Add Schedule',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDatePicker(
                          'Start Date',
                          startDate,
                          (date) => setState(() => startDate = date),
                        ),
                        const SizedBox(height: 16),
                        _buildDatePicker(
                          'End Date',
                          endDate,
                          (date) => setState(() => endDate = date),
                        ),
                        const SizedBox(height: 16),
                        _buildTimePicker(
                          'Start Time',
                          startTime,
                          (time) => setState(() => startTime = time),
                        ),
                        const SizedBox(height: 16),
                        _buildTimePicker(
                          'End Time',
                          endTime,
                          (time) => setState(() => endTime = time),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _remarksController,
                          decoration: InputDecoration(
                            labelText: 'Remarks',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveSchedule,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'Save Schedule',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _userRole == 'Owner' ? 'Available Slots' : 'My Available Slots',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildAvailableSlotsList(),
              const SizedBox(height: 24),
              Text(
                _userRole == 'Owner' ? 'Scheduled Slots' : 'My Scheduled Slots',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildSchedulesList(),
            ],
          ),
        ),
      ),
    );
  }
} 