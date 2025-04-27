// lib/features/progress/screens/medication_progress_screen.dart
import 'dart:async';

import 'package:eyedrop/features/medications/services/medication_service.dart';
import 'package:eyedrop/features/progress/controllers/progress_controller.dart';
import 'package:eyedrop/features/progress/models/progress_entry.dart';
import 'package:eyedrop/shared/services/firestore_service.dart';
import 'package:eyedrop/shared/utils/timezone_util.dart';
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
  late ProgressController _progressController;

  @override
  void initState() {
    super.initState();
    
    // Get controller without setting up the stream yet
    _progressController = Provider.of<ProgressController>(context, listen: false);
    
    // Set up stream subscription in post frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _setupStreamSubscription();
        _loadMedications();
      }
    });
  }

  void _setupStreamSubscription() {
    _refreshSubscription?.cancel();
    _refreshSubscription = _progressController.refreshStream.listen((_) {
      if (mounted) {
        _loadMedications();
      }
    });
  }

  Future<void> _loadMedications() async {
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _eyeMedications = [];
        });
        return;
      }
      
      final medicationService = Provider.of<MedicationService>(context, listen: false);
      final medications = await medicationService.getEyeMedications(user.uid);
      
      setState(() {
        _eyeMedications = medications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _eyeMedications = [];
      });
    }
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    // Reset the controller state when leaving this screen
    _progressController.resetFilters();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayoutScreen(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  "Medication Progress",
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 2.h),
            
            // Loading indicator or medication list
            if (_isLoading)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_eyeMedications.isEmpty)
              Expanded(
                child: Center(
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
                          "No medications found",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          "Add a medication to start tracking your progress",
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
              )
            else
              Expanded(
                child: _buildMedicationList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationList() {
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
        onTap: () async {
          // Load progress data for this medication
          await controller.loadMedicationProgress(medicationId);
          
          // Navigate to medication-specific progress screen
          if (mounted) {
            _showMedicationProgressBottomSheet(context, medication);
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.all(3.w),
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
              SizedBox(height: 0.5.h),
              Text(
                applicationSite,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
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
        return WillPopScope(
          onWillPop: () async {
            // Reset filters when the bottom sheet is closed
            _progressController.resetFilters();
            return true;
          },
          child: DraggableScrollableSheet(
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
          ),
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
            
            return RefreshIndicator(
              onRefresh: () async {
                await controller.loadMedicationProgress(medication['id']);
              },
              child: ListView(
                children: [
                  // Adherence stats card
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
                  ...days.map((dayString) {
                    final dayEntries = entriesByDay[dayString]!;
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
                  }).toList(),
                  
                  // Load more button if there's more data
                  if (controller.hasMoreData)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(2.h),
                        child: controller.isLoadingMore
                            ? CircularProgressIndicator(strokeWidth: 2)
                            : TextButton(
                                onPressed: () => controller.loadMoreData(),
                                child: Text("Load More"),
                              ),
                      ),
                    ),
                ],
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
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 0.5.h),
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

  Color _getAdherenceColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 70) return Colors.orange;
    return Colors.red;
  }

  Widget _buildProgressEntryCard(ProgressEntry entry, ProgressController controller) {
    final isTaken = entry.taken;
    final time = DateFormat('h:mm a').format(entry.scheduledAt);
    String responseText = "Not taken";
    
    if (isTaken && entry.responseDelayMs != null) {
      responseText = "Response: ${controller.formatResponseDelay(entry.responseDelayMs)}";
    }
    
    return Card(
      elevation: 1,
      margin: EdgeInsets.symmetric(vertical: 0.5.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: isTaken ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        child: Row(
          children: [
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
          ],
        ),
      ),
    );
  }
}