import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/schedule.dart';

class OwnerSchedulePage extends StatefulWidget {
  const OwnerSchedulePage({super.key});

  @override
  State<OwnerSchedulePage> createState() => _OwnerSchedulePageState();
}

class _OwnerSchedulePageState extends State<OwnerSchedulePage> {
  String? _selectedForemanId;
  bool _showAvailableOnly = false;
  final _formKey = GlobalKey<FormState>();
  DateTime? _startDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final _remarksController = TextEditingController();
  final _dateFormat = DateFormat('MMM dd, yyyy');
  final _timeFormat = DateFormat('hh:mm a');

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    try {
      final startDateTime = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );

      final endDateTime = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        _endTime!.hour,
        _endTime!.minute,
      );

      if (endDateTime.isBefore(startDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time')),
        );
        return;
      }

      final schedule = Schedule(
        id: FirebaseFirestore.instance.collection('foreman_schedules').doc().id,
        foremanId: _selectedForemanId!,
        startDate: startDateTime,
        endDate: endDateTime,
        startTime: _startTime!,
        endTime: _endTime!,
        timeSlot: '${_startTime!.format(context)} - ${_endTime!.format(context)}',
        remarks: _remarksController.text,
        isAvailable: true,
        createdBy: FirebaseFirestore.instance.collection('users').doc().id,
      );

      await FirebaseFirestore.instance
          .collection('foreman_schedules')
          .doc(schedule.id)
          .set(schedule.toMap());

      _formKey.currentState!.reset();
      _remarksController.clear();
      setState(() {
        _startDate = null;
        _startTime = null;
        _endTime = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating schedule: $e')),
        );
      }
    }
  }

  Future<void> _deleteSchedule(String scheduleId) async {
    try {
      await FirebaseFirestore.instance
          .collection('foreman_schedules')
          .doc(scheduleId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting schedule: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepOrange.shade50,
              Colors.white,
              Colors.deepOrange.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                        color: Colors.deepOrange,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Schedule Management',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Create New Schedule',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                              ),
                            ),
                            const SizedBox(height: 16),
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .where('role', isEqualTo: 'Foremen')
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return const Text('Error loading foremen');
                                }

                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.deepOrange,
                                    ),
                                  );
                                }

                                final foremen = snapshot.data?.docs ?? [];
                                
                                if (foremen.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'No foremen found',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 16,
                                      ),
                                    ),
                                  );
                                }

                                return DropdownButtonFormField<String>(
                                  value: _selectedForemanId,
                                  decoration: InputDecoration(
                                    labelText: 'Select Foreman',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.person,
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                                  items: foremen.map((doc) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    return DropdownMenuItem<String>(
                                      value: doc.id,
                                      child: Text(data['name'] ?? 'Unknown'),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedForemanId = value;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please select a foreman';
                                    }
                                    return null;
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      labelText: 'Start Date',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.calendar_today,
                                        color: Colors.deepOrange,
                                      ),
                                    ),
                                    controller: TextEditingController(
                                      text: _startDate != null
                                          ? _dateFormat.format(_startDate!)
                                          : '',
                                    ),
                                    onTap: () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now().add(
                                          const Duration(days: 365),
                                        ),
                                      );
                                      if (date != null) {
                                        setState(() {
                                          _startDate = date;
                                        });
                                      }
                                    },
                                    validator: (value) {
                                      if (_startDate == null) {
                                        return 'Please select a date';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      labelText: 'Start Time',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.access_time,
                                        color: Colors.deepOrange,
                                      ),
                                    ),
                                    controller: TextEditingController(
                                      text: _startTime != null
                                          ? _startTime!.format(context)
                                          : '',
                                    ),
                                    onTap: () async {
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.now(),
                                      );
                                      if (time != null) {
                                        setState(() {
                                          _startTime = time;
                                        });
                                      }
                                    },
                                    validator: (value) {
                                      if (_startTime == null) {
                                        return 'Please select a time';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'End Time',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(
                                  Icons.access_time,
                                  color: Colors.deepOrange,
                                ),
                              ),
                              controller: TextEditingController(
                                text: _endTime != null
                                    ? _endTime!.format(context)
                                    : '',
                              ),
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (time != null) {
                                  setState(() {
                                    _endTime = time;
                                  });
                                }
                              },
                              validator: (value) {
                                if (_endTime == null) {
                                  return 'Please select a time';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _remarksController,
                              decoration: InputDecoration(
                                labelText: 'Remarks',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(
                                  Icons.note,
                                  color: Colors.deepOrange,
                                ),
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _saveSchedule,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepOrange,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Create Schedule',
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
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Text(
                        'Schedules',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: _showAvailableOnly,
                        onChanged: (value) {
                          setState(() {
                            _showAvailableOnly = value;
                          });
                        },
                        activeColor: Colors.deepOrange,
                      ),
                      const Text('Available Only'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('foreman_schedules')
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
                          child: CircularProgressIndicator(
                            color: Colors.deepOrange,
                          ),
                        );
                      }

                      final schedules = snapshot.data?.docs ?? [];
                      final filteredSchedules = schedules.where((doc) {
                        final schedule = Schedule.fromMap(
                            doc.data() as Map<String, dynamic>);
                        if (_selectedForemanId != null && 
                            schedule.foremanId != _selectedForemanId) {
                          return false;
                        }
                        if (_showAvailableOnly && !schedule.isAvailable) {
                          return false;
                        }
                        return true;
                      }).toList();

                      if (filteredSchedules.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No schedules found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredSchedules.length,
                        itemBuilder: (context, index) {
                          final doc = filteredSchedules[index];
                          final schedule = Schedule.fromMap(
                              doc.data() as Map<String, dynamic>);

                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(schedule.foremanId)
                                .get(),
                            builder: (context, snapshot) {
                              final foremanName = snapshot.hasData
                                  ? (snapshot.data!.data()
                                          as Map<String, dynamic>)['name'] ??
                                      'Unknown'
                                  : 'Loading...';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  foremanName,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  _dateFormat
                                                      .format(schedule.startDate),
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: schedule.isAvailable
                                                  ? Colors.green.shade100
                                                  : Colors.red.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              schedule.isAvailable
                                                  ? 'Available'
                                                  : 'Booked',
                                              style: TextStyle(
                                                color: schedule.isAvailable
                                                    ? Colors.green.shade800
                                                    : Colors.red.shade800,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.access_time,
                                            size: 20,
                                            color: Colors.deepOrange,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${_timeFormat.format(schedule.startDate)} - ${_timeFormat.format(schedule.endDate)}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (schedule.remarks?.isNotEmpty ?? false) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.note,
                                              size: 20,
                                              color: Colors.deepOrange,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                schedule.remarks!,
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          TextButton.icon(
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    AlertDialog(
                                                  title: const Text(
                                                      'Delete Schedule'),
                                                  content: const Text(
                                                      'Are you sure you want to delete this schedule?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context),
                                                      child: const Text('Cancel'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        _deleteSchedule(doc.id);
                                                        Navigator.pop(context);
                                                      },
                                                      child: const Text(
                                                        'Delete',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            label: const Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
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
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 