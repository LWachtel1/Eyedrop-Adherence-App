import 'dart:async';

import 'package:eyedrop/features/progress/controllers/progress_controller.dart';
import 'package:eyedrop/features/progress/models/progress_entry.dart';
import 'package:eyedrop/shared/widgets/base_layout_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

class AdherenceDetailsScreen extends StatefulWidget {
  const AdherenceDetailsScreen({Key? key}) : super(key: key);

  @override
  State<AdherenceDetailsScreen> createState() => _AdherenceDetailsScreenState();
}

class _AdherenceDetailsScreenState extends State<AdherenceDetailsScreen> {
  StreamSubscription<bool>? _refreshSubscription;

  @override
  void initState() {
    super.initState();
    
    // Get controller without setting up the stream yet
    final controller = Provider.of<ProgressController>(context, listen: false);
    
    // Set up stream subscription in post frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _setupStreamSubscription();
      }
    });
  }

  void _setupStreamSubscription() {
    final controller = Provider.of<ProgressController>(context, listen: false);
    _refreshSubscription = controller.refreshStream.listen((shouldRefresh) {
      if (shouldRefresh && mounted) {
        // Actually reload the data, not just update UI
        controller.loadProgressData();
        setState(() {}); // Also trigger a UI update
      }
    });
  }

  @override
  void dispose() {
    // Just cancel the subscription but don't touch the controller
    _refreshSubscription?.cancel();
    _refreshSubscription = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ProgressController>(context);
    
    return BaseLayoutScreen(
      child: RefreshIndicator(
        onRefresh: () async {
          final controller = Provider.of<ProgressController>(context, listen: false);
          await controller.loadProgressData();
        },
        child: StreamBuilder<List<ProgressEntry>>(
          stream: controller.entriesStream,
          builder: (context, snapshot) {
            return SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          "Overall Adherence",
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 3.h),
                    
                    // Date range indicator
                    _buildDateRangeInfo(controller),
                    
                    SizedBox(height: 3.h),
                    
                    // Loading indicator if data is loading
                    if (controller.isLoading && controller.entries.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 5.h),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else ...[
                      // Overall stats card
                      _buildOverallStatsCard(controller),
                      
                      SizedBox(height: 3.h),
                      
                      // Schedule type breakdown
                      _buildScheduleTypeBreakdown(controller),
                      
                      SizedBox(height: 3.h),
                      
                      // Time of day analysis card
                      _buildTimeOfDayAnalysis(controller),
                    ],
                  ],
                ),
              ),
            );
          }
        ),
      ),
    );
  }

  Widget _buildDateRangeInfo(ProgressController controller) {
    String dateRangeText = "All Time";
    
    if (controller.startDate != null && controller.endDate != null) {
      final startFormatted = DateFormat('MMM d, yyyy').format(controller.startDate!);
      final endFormatted = DateFormat('MMM d, yyyy').format(controller.endDate!);
      dateRangeText = "$startFormatted - $endFormatted";
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Row(
          children: [
            Icon(Icons.date_range, size: 18.sp, color: Colors.blue),
            SizedBox(width: 2.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Date Range",
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  dateRangeText,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            Spacer(),
            OutlinedButton(
              child: Text("Change", style: TextStyle(fontSize: 12.sp)),
              onPressed: () => _selectDateRange(context, controller),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context, ProgressController controller) async {
    final initialDateRange = DateTimeRange(
      start: controller.startDate ?? DateTime.now().subtract(const Duration(days: 7)),
      end: controller.endDate ?? DateTime.now(),
    );
    
    final pickedDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    
    if (pickedDateRange != null) {
      controller.setDateRange(pickedDateRange.start, pickedDateRange.end);
    }
  }

  Widget _buildOverallStatsCard(ProgressController controller) {
  final stats = controller.stats;
  final adherencePercentage = stats['adherencePercentage'] ?? 0.0;
  final takenCount = stats['takenCount'] ?? 0;
  final missedCount = stats['missedCount'] ?? 0;
  final totalCount = stats['totalCount'] ?? 0;
  final adherenceStreak = stats['adherenceStreak'] ?? 0;
  final dailyStreak = stats['dailyStreak'] ?? 0;
  final weeklyStreak = stats['weeklyStreak'] ?? 0;
  final monthlyStreak = stats['monthlyStreak'] ?? 0;
  final averageResponseDelay = stats['averageResponseDelayMs'] ?? 0;
  
  // Determine adherence color based on percentage
  Color adherenceColor = Colors.red;
  if (adherencePercentage >= 80) {
    adherenceColor = Colors.green;
  } else if (adherencePercentage >= 60) {
    adherenceColor = Colors.orange;
  } else if (adherencePercentage >= 40) {
    adherenceColor = Colors.amber;
  }
  
  return Card(
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    child: Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Overall Adherence",
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          
          // Adherence percentage with circular progress indicator
          Center(
            child: Column(
              children: [
                Container(
                  width: 30.w,
                  height: 30.w,
                  child: Stack(
                    children: [
                      Center(
                        child: SizedBox(
                          width: 30.w,
                          height: 30.w,
                          child: CircularProgressIndicator(
                            value: adherencePercentage / 100,
                            strokeWidth: 12,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(adherenceColor),
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${adherencePercentage.toStringAsFixed(1)}%",
                              style: TextStyle(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.bold,
                                color: adherenceColor,
                              ),
                            ),
                            Text(
                              "Adherence",
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 2.h),
              ],
            ),
          ),
          
          SizedBox(height: 2.h),
          
          // Detailed stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDetailStat("$takenCount", "Taken", Colors.green),
              _buildDetailStat("$missedCount", "Missed", Colors.red),
              _buildDetailStat("$totalCount", "Total", Colors.blue),
              _buildDetailStat("$adherenceStreak", "Best Streak", Colors.orange),
            ],
          ),
          
          // Add streak details by schedule type
          if (dailyStreak > 0 || weeklyStreak > 0 || monthlyStreak > 0) ...[
            SizedBox(height: 2.h),
            Divider(),
            SizedBox(height: 1.h),
            
            Text(
              "Streak Details",
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            
            Wrap(
              spacing: 2.w,
              children: [
                if (dailyStreak > 0)
                  Chip(
                    avatar: Icon(Icons.calendar_today, size: 16.sp, color: Colors.orange),
                    label: Text("Daily: $dailyStreak day(s)"),
                    backgroundColor: Colors.orange[50],
                  ),
                if (weeklyStreak > 0)
                  Chip(
                    avatar: Icon(Icons.date_range, size: 16.sp, color: Colors.blue),
                    label: Text("Weekly: $weeklyStreak week(s)"),
                    backgroundColor: Colors.blue[50],
                  ),
                if (monthlyStreak > 0)
                  Chip(
                    avatar: Icon(Icons.event_note, size: 16.sp, color: Colors.green),
                    label: Text("Monthly: $monthlyStreak month(s)"),
                    backgroundColor: Colors.green[50],
                  ),
              ],
            ),
          ],
          
          SizedBox(height: 2.h),
          Divider(),
          SizedBox(height: 1.h),
          
          // Average response time
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer, color: Colors.blue),
              SizedBox(width: 1.w),
              Text(
                "Average Response Time: ",
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                controller.formatResponseDelay(averageResponseDelay),
                style: TextStyle(
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildDetailStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleTypeBreakdown(ProgressController controller) {
    final scheduleTypeStats = controller.scheduleTypeStats;
    
    if (scheduleTypeStats.isEmpty) {
      return SizedBox.shrink();
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Schedule Type Breakdown",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            
            ...scheduleTypeStats.entries.map((entry) {
              // Format schedule type for display
              String scheduleType = entry.key;
              scheduleType = scheduleType.substring(0, 1).toUpperCase() + scheduleType.substring(1);
              
              final stats = entry.value;
              final adherencePercentage = stats['adherencePercentage'] ?? 0.0;
              final takenCount = stats['takenCount'] ?? 0;
              final missedCount = stats['missedCount'] ?? 0;
              
              // Complete schedule type breakdown visualization
              return Padding(
                padding: EdgeInsets.only(bottom: 2.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scheduleType,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Row(
                        children: [
                          if (adherencePercentage > 0)
                            Expanded(
                              flex: adherencePercentage.toInt(),
                              child: Container(
                                height: 3.h,
                                color: Colors.green,
                                alignment: Alignment.center,
                                child: adherencePercentage > 30
                                    ? Text(
                                        "${adherencePercentage.toInt()}%",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10.sp,
                                        ),
                                      )
                                    : SizedBox(),
                              ),
                            ),
                          if (adherencePercentage < 100)
                            Expanded(
                              flex: (100 - adherencePercentage).toInt(),
                              child: Container(
                                height: 3.h,
                                color: Colors.red,
                                alignment: Alignment.center,
                                child: (100 - adherencePercentage) > 30
                                    ? Text(
                                        "${(100 - adherencePercentage).toInt()}%",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10.sp,
                                        ),
                                      )
                                    : SizedBox(),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Taken: $takenCount",
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.green[700],
                          ),
                        ),
                        Text(
                          "Missed: $missedCount",
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeOfDayAnalysis(ProgressController controller) {
  // Group entries by hour of day
  final entriesByHour = <int, Map<String, int>>{};
  
  for (final entry in controller.entries) {
    final hour = entry.hour;
    
    if (!entriesByHour.containsKey(hour)) {
      entriesByHour[hour] = {'taken': 0, 'missed': 0};
    }
    
    if (entry.taken) {
      entriesByHour[hour]!['taken'] = (entriesByHour[hour]!['taken'] ?? 0) + 1;
    } else {
      entriesByHour[hour]!['missed'] = (entriesByHour[hour]!['missed'] ?? 0) + 1;
    }
  }
  
  if (entriesByHour.isEmpty) {
    return SizedBox.shrink();
  }
  
  // Sort hours for consistent display
  final sortedHours = entriesByHour.keys.toList()..sort();
  
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    child: Padding(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Time of Day Analysis",
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          
          ...sortedHours.map((hour) {
            final takenCount = entriesByHour[hour]!['taken'] ?? 0;
            final missedCount = entriesByHour[hour]!['missed'] ?? 0;
            final totalCount = takenCount + missedCount;
            final adherencePercentage = totalCount > 0 ? (takenCount / totalCount * 100) : 0;
            
            // Format hour for display (12-hour format with AM/PM)
            final timeFormat = DateFormat('h a');
            final timeString = timeFormat.format(DateTime(2022, 1, 1, hour));
            
            return Padding(
              padding: EdgeInsets.only(bottom: 1.5.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        timeString,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Total: $totalCount",
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  // Heat map style bar with gradient intensity
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      children: [
                        if (takenCount > 0)
                          Expanded(
                            flex: takenCount,
                            child: Container(
                              height: 2.h,
                              color: Colors.green.withOpacity(0.7 + (adherencePercentage / 300)),
                            ),
                          ),
                        if (missedCount > 0)
                          Expanded(
                            flex: missedCount,
                            child: Container(
                              height: 2.h,
                              color: Colors.red.withOpacity(0.7 + ((100 - adherencePercentage) / 300)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Adherence: ${adherencePercentage.toStringAsFixed(1)}%",
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "$takenCount taken, $missedCount missed",
                        style: TextStyle(
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    ),
  );
}
}