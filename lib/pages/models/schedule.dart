import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Schedule {
  final String id;
  final String foremanId;
  final DateTime startDate;
  final DateTime endDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String? remarks;
  final bool isAvailable;
  final String timeSlot;
  final String? createdBy;

  Schedule({
    required this.id,
    required this.foremanId,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    this.remarks,
    this.isAvailable = true,
    required this.timeSlot,
    this.createdBy,
  });

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'foremanId': foremanId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'startTime': '${startTime.hour}:${startTime.minute}',
      'endTime': '${endTime.hour}:${endTime.minute}',
      'remarks': remarks,
      'isAvailable': isAvailable,
      'timeSlot': timeSlot,
      'createdBy': createdBy,
    };
  }

  factory Schedule.fromMap(Map<String, dynamic> map) {
    final startTimeParts = (map['startTime'] as String).split(':');
    final endTimeParts = (map['endTime'] as String).split(':');

    final startTime = TimeOfDay(
      hour: int.parse(startTimeParts[0]),
      minute: int.parse(startTimeParts[1]),
    );
    final endTime = TimeOfDay(
      hour: int.parse(endTimeParts[0]),
      minute: int.parse(endTimeParts[1]),
    );

    final timeSlot = map['timeSlot'] as String? ?? 
      '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} - ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

    return Schedule(
      id: map['id'] as String,
      foremanId: map['foremanId'] as String,
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      startTime: startTime,
      endTime: endTime,
      remarks: map['remarks'] as String?,
      isAvailable: map['isAvailable'] as bool? ?? true,
      timeSlot: timeSlot,
      createdBy: map['createdBy'] as String?,
    );
  }
} 