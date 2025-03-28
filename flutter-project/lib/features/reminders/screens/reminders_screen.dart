import 'package:eyedrop/features/notifications/controllers/notification_controller.dart';
import 'package:eyedrop/features/progress/controllers/progress_controller.dart';
import 'package:eyedrop/features/reminders/screens/reminder_details_screen.dart';
import 'package:eyedrop/features/reminders/services/reminder_service.dart';
import 'package:eyedrop/shared/services/firestore_service.dart';
import 'package:eyedrop/shared/widgets/base_layout_screen.dart';
import 'package:eyedrop/shared/widgets/confirmation_dialog.dart';
import 'package:eyedrop/shared/widgets/delete_confirmation_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

/// Screen for displaying all reminders.
class RemindersScreen extends StatefulWidget {
  static const String id = '/reminders';
  
  @override
  _RemindersScreenState createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  late ReminderService reminderService;
  List<Map<String, dynamic>> _reminders = [];
  List<Map<String, dynamic>> _filteredReminders = [];
  TextEditingController _searchController = TextEditingController();
  String _sortOption = "Newest First";
  
  // Track any reminders being updated to show loading indicators
  final Map<String, bool> _loadingReminders = {};

  @override
  void initState() {
    super.initState();
    reminderService = Provider.of<ReminderService>(context, listen: false);
    _searchController.addListener(() {
      setState(() {
        // Trigger rebuild, filtering happens in build.
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Filters and sorts reminders based on search and sort criteria.
  List<Map<String, dynamic>> _processReminders(List<Map<String, dynamic>> reminders) {
    String query = _searchController.text.toLowerCase();
    
    // Apply search filter
    List<Map<String, dynamic>> filtered = reminders.where((reminder) {
      String name = (reminder["medicationName"] ?? "").toLowerCase();
      String type = (reminder["medicationType"] ?? "").toLowerCase();
      return name.contains(query) || type.contains(query);
    }).toList();
    
    // Apply sorting
    if (_sortOption == "Newest First") {
      filtered.sort((a, b) {
        var aTime = a["createdAt"];
        var bTime = b["createdAt"];
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });
    } else if (_sortOption == "Oldest First") {
      filtered.sort((a, b) {
        var aTime = a["createdAt"];
        var bTime = b["createdAt"];
        if (aTime == null || bTime == null) return 0;
        return aTime.compareTo(bTime);
      });
    } else if (_sortOption == "A-Z") {
      filtered.sort((a, b) {
        return (a["medicationName"] ?? "").compareTo(b["medicationName"] ?? "");
      });
    } else if (_sortOption == "Z-A") {
      filtered.sort((a, b) {
        return (b["medicationName"] ?? "").compareTo(a["medicationName"] ?? "");
      });
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return BaseLayoutScreen(
      child: Column(
        children: [
          // Sort dropdown
          Padding(
            padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 5.w),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search reminders",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                PopupMenuButton<String>(
                  icon: Icon(Icons.sort),
                  tooltip: "Sort reminders",
                  onSelected: (value) {
                    setState(() {
                      _sortOption = value;
                    });
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: "Newest First",
                      child: Text("Newest First"),
                    ),
                    PopupMenuItem(
                      value: "Oldest First",
                      child: Text("Oldest First"),
                    ),
                    PopupMenuItem(
                      value: "A-Z",
                      child: Text("A-Z"),
                    ),
                    PopupMenuItem(
                      value: "Z-A",
                      child: Text("Z-A"),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Reminders list
          Expanded(
            child: user == null
                ? Center(child: Text("Please log in"))
                : StreamBuilder<List<Map<String, dynamic>>>(
                    stream: reminderService.buildRemindersStream(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && 
                          _reminders.isEmpty) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasData) {
                        _reminders = snapshot.data!;
                        _filteredReminders = _processReminders(_reminders);
                      }

                      if (_filteredReminders.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.builder(
                        padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 4.w),
                        itemCount: _filteredReminders.length,
                        itemBuilder: (context, index) {
                          return _buildReminderCard(_filteredReminders[index]);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Builds the UI for when no reminders are found.
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(5.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 40.sp,
              color: Colors.grey,
            ),
            SizedBox(height: 2.h),
            Text(
              "No Reminders Found",
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              "You don't have any reminders yet. Add a reminder by tapping the + button in the top navigation bar.",
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

  /// Formats the schedule type and frequency into a readable string
  String _formatScheduleFrequency(dynamic scheduleType, dynamic frequency) {
    if (scheduleType == null) return "N/A";
    
    String type = scheduleType.toString().toLowerCase();
    int freq = frequency is int ? 
        frequency : 
        int.tryParse(frequency?.toString() ?? '1') ?? 1;
    
    // Capitalize first letter of schedule type
    String formattedType = type.substring(0, 1).toUpperCase() + type.substring(1);
    
    if (type == "daily") {
      return freq == 1 ? "Once daily" : "$freq times daily";
    } else if (type == "weekly") {
      return freq == 1 ? "Once weekly" : "$freq times per week";
    } else if (type == "monthly") {
      return freq == 1 ? "Once monthly" : "$freq times per month";
    }
    
    return "$formattedType: $freq times";
  }

  /// Builds a card for displaying reminder information.
  Widget _buildReminderCard(Map<String, dynamic> reminder) {
    // Get basic info
    String medicationName = reminder["medicationName"] ?? "Unnamed Medication";
    bool smartScheduling = reminder["smartScheduling"] == true;
    bool isIndefinite = reminder["isIndefinite"] == true;
    bool isEnabled = reminder["isEnabled"] ?? true;
    bool isExpired = reminder["isExpired"] == true;
    String reminderId = reminder["id"] ?? "";
    
    // Check if this reminder is currently being updated
    bool isLoading = _loadingReminders[reminderId] == true;
    
    // Format start date
    String startDate = "N/A";
    if (reminder["startDate"] != null) {
      final date = reminder["startDate"] is DateTime 
          ? reminder["startDate"] 
          : reminder["startDate"].toDate();
      startDate = DateFormat('dd MMM yyyy').format(date);
    }
    
    // Format duration
    String duration = isIndefinite 
        ? "Indefinite" 
        : "${reminder["durationLength"] ?? ""} ${reminder["durationUnits"] ?? ""}";
    
    // Get schedule type and frequency for the card
    String scheduleFrequency = _formatScheduleFrequency(
      reminder["scheduleType"], 
      reminder["frequency"]
    );
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 1.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      // Add visual indication based on status
      color: isExpired ? Colors.red[50] : (isEnabled ? null : Colors.grey[100]),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReminderDetailScreen(reminder: reminder),
          ),
        ),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Medication name with enabled/disabled indicator
                  Expanded(
                    child: Row(
                      children: [
                        // Status indicator dot
                        Container(
                          width: 10,
                          height: 10,
                          margin: EdgeInsets.only(right: 2.w),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isExpired 
                                ? Colors.red 
                                : (isEnabled ? Colors.green : Colors.grey),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            medicationName,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: isExpired 
                                  ? Colors.red 
                                  : (isEnabled ? null : Colors.grey),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        // Show expired tag if needed
                        if (isExpired)
                          Container(
                            margin: EdgeInsets.only(left: 1.w),
                            padding: EdgeInsets.symmetric(
                              horizontal: 1.w, 
                              vertical: 0.2.h
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.red),
                            ),
                            child: Text(
                              "EXPIRED",
                              style: TextStyle(
                                fontSize: 8.sp,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Only show toggle switch if not expired
                  if (!isExpired)
                    Row(
                      children: [
                        // Toggle switch for enabling/disabling
                        if (isLoading)
                          Container(
                            width: 20,
                            height: 20,
                            margin: EdgeInsets.only(right: 2.w),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              value: isEnabled,
                              onChanged: (value) => _toggleReminderState(reminder, value),
                            ),
                          ),
                        
                        SizedBox(width: 1.w),
                        
                        // Delete button
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(reminder),
                        ),
                      ],
                    ),
                  
                  // Show renew button for expired reminders
                  if (isExpired)
                    ElevatedButton.icon(
                      icon: Icon(Icons.refresh, size: 14.sp),
                      label: Text("Renew", style: TextStyle(fontSize: 10.sp)),
                      onPressed: () => _renewReminder(reminder),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                      ),
                    ),
                ],
              ),
              
              // Add schedule type and frequency to the card
              Padding(
                padding: EdgeInsets.only(top: 0.5.h, bottom: 1.h),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14.sp,
                      color: isEnabled ? Colors.blue[700] : Colors.grey,
                    ),
                    SizedBox(width: 1.w),
                    Expanded(
                      child: Text(
                        scheduleFrequency,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: isEnabled ? Colors.blue[700] : Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              
              Row(
                children: [
                  Icon(
                    smartScheduling 
                        ? Icons.auto_awesome 
                        : Icons.access_time,
                    size: 14.sp,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    smartScheduling 
                        ? "Smart Scheduling" 
                        : "Manual Scheduling",
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 0.5.h),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12.sp,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          "Starts: $startDate",
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          isIndefinite
                              ? Icons.all_inclusive
                              : Icons.timelapse,
                          size: 12.sp,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 1.w),
                        Expanded(
                          child: Text(
                            duration,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.more_vert),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => Container(
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: Icon(Icons.delete_sweep, color: Colors.red),
                            title: Text("Delete Progress History"),
                            onTap: () {
                              Navigator.pop(context); // Close the bottom sheet
                              _confirmDeleteProgress(reminder);
                            },
                          ),
                          Divider(),
                          ListTile(
                            leading: Icon(Icons.close),
                            title: Text("Cancel"),
                            onTap: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Toggles a reminder's enabled state
  Future<void> _toggleReminderState(Map<String, dynamic> reminder, bool newValue) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorSnackBar("You must be logged in to perform this action");
      return;
    }
    
    if (!reminder.containsKey("id") || reminder["id"] == null) {
      _showErrorSnackBar("Cannot update reminder: missing ID");
      return;
    }
    
    final reminderId = reminder["id"];
    
    // Set loading state
    setState(() {
      _loadingReminders[reminderId] = true;
    });
    
    try {
      await reminderService.toggleReminderState(
        user.uid,
        reminderId,
        newValue
      );
      
      // Success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Reminder ${newValue ? 'enabled' : 'disabled'}"),
          backgroundColor: newValue ? Colors.green : Colors.grey,
        ),
      );
    } catch (e) {
      _showErrorSnackBar("Failed to update reminder: $e");
    } finally {
      // Clear loading state if component is still mounted
      if (mounted) {
        setState(() {
          _loadingReminders.remove(reminderId);
        });
      }
    }
  }
  
  /// Shows an error message to the user
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Shows confirmation dialog before deleting a reminder.
  void _confirmDelete(Map<String, dynamic> reminder) {
    showDialog(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        medicationName: reminder["medicationName"] ?? "Unnamed Medication",
        isReminder: true, // Specify this is a reminder deletion
        onConfirm: () async {
          try {
            await reminderService.deleteReminder(reminder);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Reminder deleted successfully")),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Failed to delete reminder: $e")),
              );
            }
          }
        },
      ),
    );
  }

  // Add this method to renew a reminder from the list
  Future<void> _renewReminder(Map<String, dynamic> reminder) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorSnackBar("You must be logged in to perform this action");
      return;
    }
    
    final reminderId = reminder["id"];
    
    // Set loading state
    setState(() {
      _loadingReminders[reminderId] = true;
    });
    
    try {
      final newReminderId = await reminderService.renewReminder(user.uid, reminderId);
      
      if (newReminderId != null) {
        // Get the new reminder data
        final newReminder = await reminderService.getReminderById(user.uid, newReminderId);
        
        if (newReminder != null) {
          // Schedule notifications for the new reminder
          final notificationController = Provider.of<NotificationController>(context, listen: false);
          notificationController.scheduleReminderNotifications(newReminder);
        }
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Reminder renewed successfully")),
        );
      } else {
        _showErrorSnackBar("Failed to renew reminder");
      }
    } catch (e) {
      _showErrorSnackBar("Error renewing reminder: $e");
    } finally {
      // Clear loading state
      if (mounted) {
        setState(() {
          _loadingReminders.remove(reminderId);
        });
      }
    }
  }

  void _confirmDeleteProgress(Map<String, dynamic> reminder) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: "Delete Progress History",
        message: "Are you sure you want to delete all progress history for ${reminder["medicationName"] ?? "Unnamed Medication"}? This action cannot be undone.",
        onConfirm: () async {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) {
            _showErrorSnackBar("You must be logged in to delete progress data");
            return;
          }
          
          try {
            setState(() {
              _loadingReminders[reminder["id"]] = true;
            });
            
            final progressController = Provider.of<ProgressController>(context, listen: false);
            await progressController.deleteProgressForReminder(reminder["id"]);
            
            setState(() {
              _loadingReminders.remove(reminder["id"]);
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Progress history deleted successfully")),
            );
          } catch (e) {
            setState(() {
              _loadingReminders.remove(reminder["id"]);
            });
            _showErrorSnackBar("Failed to delete progress history: $e");
          }
        },
      ),
    );
  }
}