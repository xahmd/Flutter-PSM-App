import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_sepg10/pages/models/schedule.dart';
import 'package:flutter_sepg10/pages/schedule/owner_schedule_management_page.dart';

class OwnerScheduleViewPage extends StatefulWidget {
  final String ownerId;

  const OwnerScheduleViewPage({Key? key, required this.ownerId}) : super(key: key);

  @override
  _OwnerScheduleViewPageState createState() => _OwnerScheduleViewPageState();
}

class _OwnerScheduleViewPageState extends State<OwnerScheduleViewPage> {
  String? selectedForemanId;
  bool showAvailableOnly = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Foremen Schedules'),
        backgroundColor: Colors.deepOrange,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OwnerScheduleManagementPage(
                    ownerId: widget.ownerId,
                  ),
                ),
              );
            },
          ),
        ],
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.ownerId)
                          .collection('myForemen')
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
                          value: selectedForemanId,
                          decoration: InputDecoration(
                            labelText: 'Select Foreman',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('All Foremen'),
                            ),
                            ...foremen.map((foreman) {
                              final data = foreman.data() as Map<String, dynamic>;
                              return DropdownMenuItem<String>(
                                value: foreman.id,
                                child: Text(data['name'] ?? 'Unknown Foreman'),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedForemanId = value;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  FilterChip(
                    label: const Text('Available Only'),
                    selected: showAvailableOnly,
                    onSelected: (value) {
                      setState(() {
                        showAvailableOnly = value;
                      });
                    },
                    selectedColor: Colors.deepOrange,
                    checkmarkColor: Colors.white,
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('foreman_schedules')
                    .where('createdBy', isEqualTo: widget.ownerId)
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
                  final filteredSchedules = schedules.where((doc) {
                    final schedule = Schedule.fromMap(doc.data() as Map<String, dynamic>);
                    if (selectedForemanId != null && schedule.foremanId != selectedForemanId) {
                      return false;
                    }
                    if (showAvailableOnly && !schedule.isAvailable) {
                      return false;
                    }
                    return true;
                  }).toList();

                  if (filteredSchedules.isEmpty) {
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
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredSchedules.length,
                    itemBuilder: (context, index) {
                      final schedule = Schedule.fromMap(
                        filteredSchedules[index].data() as Map<String, dynamic>,
                      );

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(schedule.foremanId)
                            .get(),
                        builder: (context, foremanSnapshot) {
                          String foremanName = 'Unknown Foreman';
                          if (foremanSnapshot.hasData && foremanSnapshot.data != null) {
                            final foremanData = foremanSnapshot.data!.data() as Map<String, dynamic>;
                            foremanName = foremanData['name'] ?? 'Unknown Foreman';
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: schedule.isAvailable
                                    ? Colors.green
                                    : Colors.deepOrange,
                                child: Icon(
                                  schedule.isAvailable
                                      ? Icons.check
                                      : Icons.schedule,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                foremanName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                '${DateFormat('MMM d, y').format(schedule.startDate)} - ${DateFormat('MMM d, y').format(schedule.endDate)}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Time: ${schedule.timeSlot}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      if (schedule.remarks?.isNotEmpty ?? false) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Remarks: ${schedule.remarks}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton.icon(
                                            onPressed: () {
                                              FirebaseFirestore.instance
                                                  .collection('foreman_schedules')
                                                  .doc(schedule.id)
                                                  .delete();
                                            },
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            label: const Text(
                                              'Delete',
                                              style: TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        ],
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 