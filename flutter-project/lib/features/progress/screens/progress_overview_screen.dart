import 'package:eyedrop/features/progress/controllers/progress_controller.dart';
import 'package:eyedrop/features/progress/models/progress_entry.dart';
import 'package:eyedrop/features/progress/screens/adherence_details_screen.dart';
import 'package:eyedrop/features/progress/screens/medication_progress_screen.dart';
import 'package:eyedrop/features/reminders/screens/reminder_details_screen.dart';
import 'package:eyedrop/features/reminders/services/reminder_service.dart';
import 'package:eyedrop/shared/utils/timezone_util.dart';
import 'package:eyedrop/shared/widgets/base_layout_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'dart:async';
import 'dart:developer';

class ProgressOverviewScreen extends StatefulWidget {
  static const String id = '/progress';

  const ProgressOverviewScreen({Key? key}) : super(key: key);

  @override
  State<ProgressOverviewScreen> createState() => _ProgressOverviewScreenState();
}

class _ProgressOverviewScreenState extends State<ProgressOverviewScreen> with WidgetsBindingObserver {
  bool _isLoading = false;
  late ProgressController _progressController;
  StreamSubscription? _refreshSubscription;
  bool _controllerInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get controller reference
    _progressController = Provider.of<ProgressController>(context, listen: false);
    
    if (!_controllerInitialized) {
      _controllerInitialized = true;
      
      // Ensure controller is ready for use
      _progressController.resetController();
      
      // Initialize safely with the enhanced method
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Initialize both types of real-time updates
          _progressController.initialize();
          // Load initial data
          _progressController.loadProgressData();
        }
      });
    }
  }

  @override
  void didUpdateWidget(ProgressOverviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh when returning to this screen
    if (mounted && _controllerInitialized) {
      _progressController.loadProgressData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Cancel our subscription but don't dispose the controller
    _refreshSubscription?.cancel();
    _refreshSubscription = null;
    
    // Clean up screen-specific resources
    if (_controllerInitialized) {
      _progressController.cleanupScreenResources();
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ProgressController>(context);

    return BaseLayoutScreen(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with options
            _buildHeader(controller),
            
            SizedBox(height: 2.h),
            
            // Filter options
            _buildFilterOptions(controller),
            
            SizedBox(height: 2.h),
            
            // Quick stats
            _buildQuickStats(controller),
            
            SizedBox(height: 3.h),
            
            // Navigation buttons
            _buildNavigationButtons(),
            
            SizedBox(height: 2.h),
            
            // Progress entries list
            Expanded(
              child: _buildProgressList(controller),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ProgressController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            "Progress Overview",
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterOptions(ProgressController controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Filter Options",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.calendar_today, size: 16.sp),
                    label: Text(
                      controller.startDate != null && controller.endDate != null
                          ? "${DateFormat('MMM d').format(controller.startDate!)} - ${DateFormat('MMM d').format(controller.endDate!)}"
                          : "Select Date Range",
                      style: TextStyle(fontSize: 12.sp),
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () => _selectDateRange(context, controller),
                  ),
                ),
                SizedBox(width: 2.w),
                IconButton(
                  icon: Icon(Icons.refresh),
                  tooltip: "Reset filters",
                  onPressed: () => controller.resetFilters(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context, ProgressController controller) async {
    try {
      final initialDateRange = DateTimeRange(
        start: controller.startDate ?? DateTime.now().subtract(const Duration(days: 7)),
        end: controller.endDate ?? DateTime.now(),
      );
      
      final pickedDateRange = await showDateRangePicker(
        context: context,
        initialDateRange: initialDateRange,
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Colors.blue,
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );
      
      if (pickedDateRange != null) {
        // Fix: When end date is today, ensure we get the whole day
        final endDate = pickedDateRange.end;
        final now = DateTime.now();
        
        // Check if the selected end date is today
        final isToday = endDate.year == now.year && 
                      endDate.month == now.month && 
                      endDate.day == now.day;
                      
        // If today is selected, use current time instead of midnight
        final adjustedEndDate = isToday ? 
            DateTime(now.year, now.month, now.day, now.hour, now.minute, now.second) : 
            endDate;
        
        controller.setDateRange(pickedDateRange.start, adjustedEndDate);
        if (controller.hasError) {
          _showSnackBar(controller.errorMessage ?? "Error setting date range", isError: true);
        } else {
          _showSnackBar("Date range updated");
        }
      }
    } catch (e) {
      _showSnackBar("Error selecting dates: ${e.toString()}", isError: true);
    }
  }

  Widget _buildQuickStats(ProgressController controller) {

    log(controller.stats.toString());
    final stats = controller.stats;
    final adherencePercentage = stats['adherencePercentage'] ?? 0.0;
    final takenCount = stats['takenCount'] ?? 0;
    final missedCount = stats['missedCount'] ?? 0;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Quick Stats",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  "${adherencePercentage.toStringAsFixed(1)}%",
                  "Adherence",
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatItem(
                  "$takenCount",
                  "Taken",
                  Icons.thumb_up,
                  Colors.blue,
                ),
                _buildStatItem(
                  "$missedCount",
                  "Missed",
                  Icons.thumb_down,
                  Colors.red,
                ),
                
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20.sp),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: Icon(Icons.analytics),
            label: Text("Overall Adherence", style: TextStyle(fontSize: 12.sp)),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 1.5.h),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdherenceDetailsScreen()),
              );
            },
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: ElevatedButton.icon(
            icon: Icon(Icons.medication),
            label: Text("Medication View", style: TextStyle(fontSize: 12.sp)),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 1.5.h),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MedicationProgressScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  // Replace the existing _buildProgressList method with this StreamBuilder approach

Widget _buildProgressList(ProgressController controller) {
  return RefreshIndicator(
    onRefresh: () async {
      // Force a complete reload from the server
      await _progressController.loadProgressData(reset: true, forceRefresh: true);
    },
    child: StreamBuilder<List<ProgressEntry>>(
      stream: controller.entriesStream,
      builder: (context, snapshot) {
        // Handle connection states
        if (snapshot.connectionState == ConnectionState.waiting && controller.entries.isEmpty) {
          return Center(child: CircularProgressIndicator());
        }
        
        // Complete the error handling section in _buildProgressList
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
        
        // When we have data, use it
        final entries = snapshot.data ?? controller.entries;
        
        if (entries.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.all(5.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 40.sp,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      "Start taking your medications to track your progress.",
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        
        // Group entries by day
        final entriesByDay = controller.getEntriesByDay(entries);
        final days = entriesByDay.keys.toList();
        
        return NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
                !controller.isLoading && 
                !controller.isLoadingMore &&
                controller.hasMoreData) {
              // We're at the bottom, load more data
              controller.loadMoreData();
            }
            return false;
          },
          child: ListView.builder(
            itemCount: days.length + (controller.isLoadingMore || controller.hasMoreData ? 1 : 0),
            itemBuilder: (context, index) {
              // Show loader at the end
              if (index == days.length) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(2.h),
                    child: controller.isLoadingMore
                        ? CircularProgressIndicator(strokeWidth: 2)
                        : controller.hasMoreData
                            ? TextButton(
                                onPressed: () => controller.loadMoreData(),
                                child: Text("Load More"),
                              )
                            : Text("No more entries"),
                  ),
                );
              }
              
              final dayString = days[index];
              final dayEntries = entriesByDay[dayString]!;
              // Use timezone utility to format day
              final formattedDay = TimezoneUtil.formatDayString(dayString);
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(2.w, 2.h, 0, 1.h),
                    child: Text(
                      formattedDay,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...dayEntries.map((entry) => _buildProgressEntryCard(entry, controller)).toList(),
                ],
              );
            },
          ),
        );
      },
    ),
  );
}

  // Update the onTap handler in the entry card for safer navigation
  Widget _buildProgressEntryCard(dynamic entry, ProgressController controller) {
    final isTaken = entry.taken;
    final medicationId = entry.medicationId;
    final reminderId = entry.reminderId;
    
    // Format time
    final time = DateFormat('h:mm a').format(entry.scheduledAt);
    
    // Response delay text
    String responseText = "Not taken";
    if (isTaken && entry.responseDelayMs != null) {
      responseText = "Response: ${controller.formatResponseDelay(entry.responseDelayMs)}";
    }
    
    return Card(
      elevation: 1,
      margin: EdgeInsets.symmetric(vertical: 0.5.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: isTaken ? Colors.green[50] : Colors.red[50],
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          // Navigate to reminder details if we have a reminder ID
          if (reminderId.isNotEmpty) {
            _navigateToReminderDetails(reminderId);
          }
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          child: Row(
            children: [
              // Status icon
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: isTaken ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isTaken ? Icons.check : Icons.close,
                  color: Colors.white,
                  size: 16.sp,
                ),
              ),
              SizedBox(width: 3.w),
              
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isTaken ? "Taken" : "Missed",
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: isTaken ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      responseText,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Navigation indicator
              Icon(
                Icons.chevron_right,
                color: Colors.grey[600],
                size: 20.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add safe navigation method
  Future<void> _navigateToReminderDetails(String reminderId) async {
    try {
      final reminderService = Provider.of<ReminderService>(context, listen: false);
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        _showSnackBar("You must be signed in to view reminder details", isError: true);
        return;
      }
      
      setState(() => _isLoading = true);
      
      final reminder = await reminderService.getReminderById(user.uid, reminderId);
      
      setState(() => _isLoading = false);
      
      if (reminder != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReminderDetailScreen(reminder: reminder),
          ),
        );
      } else {
        _showSnackBar("Reminder not found or was deleted", isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Error loading reminder: ${e.toString()}", isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 2),
        action: isError 
            ? SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              )
            : null,
      ),
    );
  }
}