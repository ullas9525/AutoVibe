import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';

class Schedule {
  final String id;
  final String name;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final List<bool> days; // Mon-Sun
  final bool isEnabled;
  final int alarmId; // Persistent ID for AlarmManager

  Schedule({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.days,
    this.isEnabled = true,
    required this.alarmId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startTime': {'hour': startTime.hour, 'minute': startTime.minute},
      'endTime': {'hour': endTime.hour, 'minute': endTime.minute},
      'days': days,
      'isEnabled': isEnabled,
      'alarmId': alarmId,
    };
  }

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'],
      name: map['name'],
      startTime: TimeOfDay(
        hour: map['startTime']['hour'],
        minute: map['startTime']['minute'],
      ),
      endTime: TimeOfDay(
        hour: map['endTime']['hour'],
        minute: map['endTime']['minute'],
      ),
      days: List<bool>.from(map['days']),
      isEnabled: map['isEnabled'] ?? true,
      // Migration: If alarmId is missing, generate a random one (safe for 32-bit)
      alarmId: map['alarmId'] ?? Random().nextInt(0x7FFFFFFF),
    );
  }

  String toJson() => json.encode(toMap());

  factory Schedule.fromJson(String source) => Schedule.fromMap(json.decode(source));
}
