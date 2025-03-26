import 'package:eyedrop/features/schedule/screens/schedule_type_base_screen.dart';
import 'package:flutter/material.dart';

class MonthlyScheduleScreen extends ScheduleTypeBaseScreen {
  static const String id = '/schedule/monthly';
  
  const MonthlyScheduleScreen({Key? key}) : super(key: key);
  
  @override
  _MonthlyScheduleScreenState createState() => _MonthlyScheduleScreenState();
}

class _MonthlyScheduleScreenState extends ScheduleTypeBaseState<MonthlyScheduleScreen> {
  @override
  String get scheduleType => 'monthly';
  
  @override
  String get screenTitle => 'Monthly Reminders';
  
  @override
  Color get themeColor => Colors.purple;
  
  @override
  IconData get screenIcon => Icons.calendar_month;
}