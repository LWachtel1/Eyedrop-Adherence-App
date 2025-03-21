import 'package:eyedrop/features/reminders/screens/reminder_details_screen.dart';
import 'package:eyedrop/features/reminders/services/reminder_service.dart';
import 'package:eyedrop/shared/services/firestore_service.dart';
import 'package:eyedrop/shared/widgets/base_layout_screen.dart';
import 'package:eyedrop/shared/widgets/delete_confirmation_dialog.dart';
import 'package:eyedrop/shared/widgets/searchable_list.dart';
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
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
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
                  Expanded(
                    child: Text(
                      medicationName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(reminder),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
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
                      color: Colors.blue[700],
                    ),
                    SizedBox(width: 1.w),
                    Expanded(
                      child: Text(
                        scheduleFrequency,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[700],
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
            ],
          ),
        ),
      ),
    );
  }

  /// Shows confirmation dialog before deleting a reminder.
  void _confirmDelete(Map<String, dynamic> reminder) {
    showDialog(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        medicationName: reminder["medicationName"] ?? "Unnamed Medication",
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
}