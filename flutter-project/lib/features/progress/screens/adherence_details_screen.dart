import 'dart:async';
import 'dart:developer';
import 'dart:math' as Math;

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
            // Handle connection states
            if (snapshot.connectionState == ConnectionState.waiting && controller.entries.isEmpty) {
              return Center(child: CircularProgressIndicator());
            }
            
            // Handle errors
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 48),
                    SizedBox(height: 16),
                    Text("Error loading data: ${snapshot.error}"),
                    ElevatedButton(
                      onPressed: () => controller.loadProgressData(forceRefresh: true),
                      child: Text("Retry"),
                    ),
                  ],
                ),
              );
            }
            
            // Use data from stream or fallback to controller entries
            final entries = snapshot.data ?? controller.entries;
            
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
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          
          // Adherence percentage with circular progress indicator
          Center(
            child: Column(
              children: [
                SizedBox(
                  height: 20.h,
                  width: 20.h,
                  child: Stack(
                    children: [
                      Center(
                        child: SizedBox(
                          height: 18.h,
                          width: 18.h,
                          child: CircularProgressIndicator(
                            value: adherencePercentage / 100,
                            strokeWidth: 10,
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

// Add a new widget to display medication streaks
Widget _buildMedicationStreakRow({
  required String medicationName,
  required int streak,
  required String streakType,
  required IconData icon,
  required Color color,
}) {
  String unit = streakType == 'daily' ? 'day(s)' : 
               (streakType == 'weekly' ? 'week(s)' : 'month(s)');
  log("streaktype $streakType streak $streak");
  
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 0.5.h),
    child: Row(
      children: [
        Icon(icon, size: 16.sp, color: color),
        SizedBox(width: 2.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                medicationName,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                "$streak $unit streak",
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
            final scheduleType = entry.key;
            final stats = entry.value;
            
            final takenCount = stats['takenCount'] ?? 0;
            final missedCount = stats['missedCount'] ?? 0;
            final totalCount = takenCount + missedCount;
            
            // CRITICAL FIX: Calculate the adherence percentage correctly
            final adherencePercentage = totalCount > 0 
                ? (takenCount / totalCount * 100).roundToDouble() 
                : 0.0;
            
            // Calculate bar proportions based on percentages, not raw counts
            final takenFlex = (adherencePercentage / 100 * 100).round();
            final missedFlex = 100 - takenFlex;
            
            // Ensure minimum visibility of each section if it has entries
            final effectiveTakenFlex = takenCount > 0 ? Math.max<int>(takenFlex, 5) : 0;
            final effectiveMissedFlex = missedCount > 0 ? Math.max(missedFlex, 5) : 0;
            
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
                        if (takenCount > 0)
                          Expanded(
                            flex: effectiveTakenFlex,
                            child: Container(
                              height: 3.h,
                              color: Colors.green,
                              alignment: Alignment.center,
                              child: effectiveTakenFlex > 25
                                  ? Text(
                                      "${adherencePercentage.round()}%",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10.sp,
                                      ),
                                    )
                                  : SizedBox(),
                            ),
                          ),
                        if (missedCount > 0)
                          Expanded(
                            flex: effectiveMissedFlex.toInt(),
                            child: Container(
                              height: 3.h,
                              color: Colors.red,
                              alignment: Alignment.center,
                              child: effectiveMissedFlex > 25
                                  ? Text(
                                      "${(100 - adherencePercentage).round()}%",
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
                      Text(
                        "${adherencePercentage.round()}% adherence",
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
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
  
  // Use the complete stats entries if available, otherwise use the displayed entries
  final entriesToUse = controller.statsEntries.isNotEmpty ? 
    controller.statsEntries : controller.entries;  

  for (final entry in entriesToUse) {
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
          
          // Map over hours and create list items
          ...sortedHours.map((hour) {
            final takenCount = entriesByHour[hour]!['taken'] ?? 0;
            final missedCount = entriesByHour[hour]!['missed'] ?? 0;
            final totalCount = takenCount + missedCount;
            
            // Calculate adherence percentage safely
            final adherencePercentage = totalCount > 0 ? (takenCount / totalCount * 100) : 0;
            
            // Format hour for display (12-hour format with AM/PM)
            final timeFormat = DateFormat('h a');
            final timeString = timeFormat.format(DateTime(2022, 1, 1, hour));
            
            // Calculate percentage-based flex values to ensure proper proportions
            final takenPercentage = adherencePercentage.round();
            final missedPercentage = 100 - takenPercentage;
            
            return Padding(
              padding: EdgeInsets.only(bottom: 1.5.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 20.w,
                        child: Text(
                          timeString,
                          style: TextStyle(
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                      Expanded(
                        child: takenCount > 0 || missedCount > 0 ? Row(
                          children: [
                            // Key fix: Only show the taken bar if adherence > 0
                            if (takenCount > 0)
                              Expanded(
                                flex: takenPercentage,
                                child: Container(
                                  height: 2.5.h,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(4),
                                      bottomLeft: Radius.circular(4),
                                      // Add right-side radius if there are no missed meds
                                      topRight: missedCount == 0 ? Radius.circular(4) : Radius.zero,
                                      bottomRight: missedCount == 0 ? Radius.circular(4) : Radius.zero,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: takenPercentage > 25
                                    ? Text(
                                        takenCount.toString(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10.sp,
                                        ),
                                      )
                                    : SizedBox.shrink(),
                                ),
                              ),
                            // Key fix: Only show the missed bar if there are actually missed entries
                            if (missedCount > 0)
                              Expanded(
                                flex: missedPercentage,
                                child: Container(
                                  height: 2.5.h,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(4),
                                      bottomRight: Radius.circular(4),
                                      // Add left-side radius if there are no taken meds
                                      topLeft: takenCount == 0 ? Radius.circular(4) : Radius.zero,
                                      bottomLeft: takenCount == 0 ? Radius.circular(4) : Radius.zero,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: missedPercentage > 25
                                    ? Text(
                                        missedCount.toString(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10.sp,
                                        ),
                                      )
                                    : SizedBox.shrink(),
                                ),
                              ),
                          ],
                        ) : Container(
                          height: 2.5.h,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "No data",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10.sp,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    "${adherencePercentage.toStringAsFixed(1)}% adherence (${takenCount}/${totalCount})",
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
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