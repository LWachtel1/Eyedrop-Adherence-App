// lib/features/progress/screens/medication_progress_screen.dart
import 'dart:async';

import 'package:eyedrop/features/medications/services/medication_service.dart';
import 'package:eyedrop/features/progress/controllers/progress_controller.dart';
import 'package:eyedrop/features/progress/models/progress_entry.dart';
import 'package:eyedrop/shared/services/firestore_service.dart';
import 'package:eyedrop/shared/widgets/base_layout_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

class MedicationProgressScreen extends StatefulWidget {
  const MedicationProgressScreen({Key? key}) : super(key: key);

  @override
  State<MedicationProgressScreen> createState() => _MedicationProgressScreenState();
}

class _MedicationProgressScreenState extends State<MedicationProgressScreen> {
  List<Map<String, dynamic>> _eyeMedications = [];
  bool _isLoading = true;
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
        _loadMedications();
      }
    });
  }

  void _setupStreamSubscription() {
    final controller = Provider.of<ProgressController>(context, listen: false);
    _refreshSubscription = controller.refreshStream.listen((shouldRefresh) {
      if (shouldRefresh && mounted) {
        // Actually reload the medications list and progress data
        _loadMedications();
        
        // If a medication is selected, also reload its specific progress
        if (controller.selectedMedicationId != null) {
          controller.loadMedicationProgress(controller.selectedMedicationId!);
        }
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

  Future<void> _loadMedications() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final medicationService = Provider.of<MedicationService>(context, listen: false);
      final progressController = Provider.of<ProgressController>(context, listen: false);
      
      // Get all medications
      final medications = await medicationService.buildMedicationsStream(firestoreService, user.uid).first;
      
      // Only show medications with active reminders
      final eyeMeds = medications.where((med) => 
        med["medType"] == "Eye Medication" && med["reminderSet"] == true
      ).toList();
      
      setState(() {
        _eyeMedications = eyeMeds;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading medications: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return BaseLayoutScreen(
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
                  "Medication Adherence",
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 3.h),
            
            _buildDateRangeSelector(),
            
            SizedBox(height: 3.h),
            
            Expanded(
              child: _buildMedicationList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    final controller = Provider.of<ProgressController>(context);
    
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
        child: Column(
          children: [
            Row(
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

  Widget _buildMedicationList() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (_eyeMedications.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(5.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.medication_outlined,
                size: 40.sp,
                color: Colors.grey,
              ),
              SizedBox(height: 2.h),
              Text(
                "No Eye Medications Found",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 1.h),
              Text(
                "You don't have any eye medications with reminders set. Add medications and set reminders to track your progress.",
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _eyeMedications.length,
      itemBuilder: (context, index) {
        final medication = _eyeMedications[index];
        return _buildMedicationCard(medication);
      },
    );
  }

  Widget _buildMedicationCard(Map<String, dynamic> medication) {
    final controller = Provider.of<ProgressController>(context, listen: false);
    final medicationId = medication['id'];
    final medicationName = medication['medicationName'] ?? 'Unnamed Medication';
    final applicationSite = medication['applicationSite'] ?? 'Not specified';
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 1.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () {
          // Load progress data for this medication
          controller.loadMedicationProgress(medicationId);
          
          // Navigate to medication-specific progress screen
          _showMedicationProgressBottomSheet(context, medication);
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.medication_outlined,
                  color: Colors.blue[800],
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicationName,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Applied to: $applicationSite",
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 20.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMedicationProgressBottomSheet(BuildContext context, Map<String, dynamic> medication) {
    final medicationName = medication['medicationName'] ?? 'Unnamed Medication';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: EdgeInsets.fromLTRB(4.w, 2.w, 4.w, 4.w),
              child: Column(
                children: [
                  // Handle
                  Container(
                    width: 15.w,
                    height: 0.5.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  
                  // Title
                  Text(
                    medicationName,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 3.h),
                  
                  // Progress details
                  Expanded(
                    child: _buildMedicationProgressDetails(medication),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMedicationProgressDetails(Map<String, dynamic> medication) {
    return Consumer<ProgressController>(
      builder: (context, controller, child) {
        return StreamBuilder<List<ProgressEntry>>(
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
                    onPressed: () => controller.loadMedicationProgress(medication['id']),
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
                        "No progress data for this medication",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        "Take your medication to start tracking your progress",
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            
            // Calculate adherence stats
            final stats = controller.stats;
            final adherencePercentage = stats['adherencePercentage'] ?? 0.0;
            final takenCount = stats['takenCount'] ?? 0;
            final missedCount = stats['missedCount'] ?? 0;
            final totalCount = stats['totalCount'] ?? 0;
            
            // Group entries by day for display
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
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Adherence statistics
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: EdgeInsets.all(3.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Adherence Statistics",
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatColumn(
                                  "${adherencePercentage.toStringAsFixed(1)}%", 
                                  "Adherence", 
                                  _getAdherenceColor(adherencePercentage)
                                ),
                                _buildStatColumn("$takenCount", "Taken", Colors.green),
                                _buildStatColumn("$missedCount", "Missed", Colors.red),
                                _buildStatColumn("$totalCount", "Total", Colors.blue),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 2.h),
                    
                    // Progress entries by day
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: days.length,
                      itemBuilder: (context, index) {
                        final dayString = days[index];
                        final dayEntries = entriesByDay[dayString]!;
                        final formattedDay = controller.formatDayString(dayString);
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: 2.h, bottom: 1.h),
                              child: Text(
                                formattedDay,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ...dayEntries.map((entry) => _buildEntryCard(entry, controller)).toList(),
                          ],
                        );
                      },
                    ),
                    
                    // Loading indicator for pagination
                    if (controller.isLoadingMore || controller.hasMoreData)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(2.h),
                          child: controller.isLoadingMore
                              ? CircularProgressIndicator(strokeWidth: 2)
                              : controller.hasMoreData
                                  ? TextButton(
                                      onPressed: () => controller.loadMoreData(),
                                      child: Text("Load More"),
                                    )
                                  : SizedBox(),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatColumn(String value, String label, Color color) {
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

  Widget _buildEntryCard(dynamic entry, ProgressController controller) {
    final isTaken = entry.taken;
    final time = DateFormat('h:mm a').format(entry.scheduledAt);
    
    String statusText = isTaken ? "Taken" : "Missed";
    String responseText = "";
    
    if (isTaken && entry.responseDelayMs != null) {
      responseText = "Response: ${controller.formatResponseDelay(entry.responseDelayMs)}";
    }
    
    return Card(
      elevation: 1,
      margin: EdgeInsets.symmetric(vertical: 0.5.h),
      color: isTaken ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: EdgeInsets.all(2.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(1.5.w),
              decoration: BoxDecoration(
                color: isTaken ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isTaken ? Icons.check : Icons.close,
                color: Colors.white,
                size: 12.sp,
              ),
            ),
            SizedBox(width: 2.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (responseText.isNotEmpty)
                  Text(
                    responseText,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[700],
                    ),
                  ),
              ],
            ),
            Spacer(),
            Text(
              statusText,
              style: TextStyle(
                color: isTaken ? Colors.green[700] : Colors.red[700],
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAdherenceColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    if (percentage >= 40) return Colors.amber;
    return Colors.red;
  }
}