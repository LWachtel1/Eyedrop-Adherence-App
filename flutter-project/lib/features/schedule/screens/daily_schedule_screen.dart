import 'package:eyedrop/features/schedule/screens/schedule_type_base_screen.dart';
import 'package:flutter/material.dart';

class DailyScheduleScreen extends ScheduleTypeBaseScreen {
  static const String id = '/schedule/daily';
  
  const DailyScheduleScreen({Key? key}) : super(key: key);
  
  @override
  _DailyScheduleScreenState createState() => _DailyScheduleScreenState();
}

class _DailyScheduleScreenState extends ScheduleTypeBaseState<DailyScheduleScreen> {
  @override
  String get scheduleType => 'daily';
  
  @override
  String get screenTitle => 'Daily Reminders';
  
  @override
  Color get themeColor => Colors.green;
  
  @override
  IconData get screenIcon => Icons.today;
}