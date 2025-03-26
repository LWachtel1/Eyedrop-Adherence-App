import 'package:eyedrop/features/schedule/screens/schedule_type_base_screen.dart';
import 'package:flutter/material.dart';

class WeeklyScheduleScreen extends ScheduleTypeBaseScreen {
  static const String id = '/schedule/weekly';
  
  const WeeklyScheduleScreen({Key? key}) : super(key: key);
  
  @override
  _WeeklyScheduleScreenState createState() => _WeeklyScheduleScreenState();
}

class _WeeklyScheduleScreenState extends ScheduleTypeBaseState<WeeklyScheduleScreen> {
  @override
  String get scheduleType => 'weekly';
  
  @override
  String get screenTitle => 'Weekly Reminders';
  
  @override
  Color get themeColor => Colors.blue;
  
  @override
  IconData get screenIcon => Icons.view_week;
}