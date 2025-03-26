import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyedrop/features/notifications/controllers/notification_controller.dart';
import 'package:eyedrop/features/reminders/screens/reminder_details_screen.dart';
import 'package:eyedrop/features/reminders/services/reminder_service.dart';
import 'package:eyedrop/shared/services/firestore_service.dart';
import 'package:eyedrop/shared/widgets/base_layout_screen.dart';
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
  List<Map<String, dynamic>> _activeReminders = [];
  List<Map<String, dynamic>> _deletedReminders = [];
  List<Map<String, dynamic>> _filteredActiveReminders = [];
  List<Map<String, dynamic>> _filteredDeletedReminders = [];
  TextEditingController _searchController = TextEditingController();
  String _sortOption = "Newest First";
  bool _showDeletedReminders = false;
  
  // Track any reminders being updated to show loading indicators
  final Map<String, bool> _loadingReminders = {};

  @override
  void initState() {
    super.initState();
    reminderService = Provider.of<ReminderService>(context, listen: false);
    _searchController.addListener(() {
      setState(() {
        // Trigger rebuild, filtering happens in build
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Filters and sorts reminders based on search and sort criteria
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
          // Header with search and sort options
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
            child: Row(
              children: [
                // Search field
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search reminders...",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                // Sort dropdown
                PopupMenuButton<String>(
                  icon: Icon(Icons.sort),
                  onSelected: (String value) {
                    setState(() {
                      _sortOption = value;
                    });
                  },
                  itemBuilder: (BuildContext context) => [
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

          // Reminders list with StreamBuilder
          Expanded(
            child: user == null
                ? Center(child: Text("Please log in"))
                : Column(
                    children: [
                      // Active reminders section
                      Expanded(
                        child: StreamBuilder<List<Map<String, dynamic>>>(
                          stream: reminderService.buildActiveRemindersStream(user.uid),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting && 
                                _activeReminders.isEmpty) {
                              return Center(child: CircularProgressIndicator());
                            }

                            if (snapshot.hasData) {
                              _activeReminders = snapshot.data!;
                              _filteredActiveReminders = _processReminders(_activeReminders);
                            }

                            if (_filteredActiveReminders.isEmpty && 
                                _filteredDeletedReminders.isEmpty) {
                              return _buildEmptyState();
                            }

                            if (_filteredActiveReminders.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "No active reminders",
                                      style: TextStyle(fontSize: 16.sp),
                                    ),
                                    SizedBox(height: 1.h),
                                    Text(
                                      "Add a reminder or check the archived section",
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ListView.builder(
                              padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 4.w),
                              itemCount: _filteredActiveReminders.length,
                              itemBuilder: (context, index) {
                                return _buildReminderCard(_filteredActiveReminders[index], false);
                              },
                            );
                          },
                        ),
                      ),
                      
                      // Archived/Deleted reminders section
                      Card(
                        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          title: Text(
                            "Archived Reminders",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_showDeletedReminders ? "Hide" : "Show"),
                              Icon(
                                _showDeletedReminders 
                                    ? Icons.keyboard_arrow_up 
                                    : Icons.keyboard_arrow_down,
                              ),
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              _showDeletedReminders = !_showDeletedReminders;
                            });
                          },
                        ),
                      ),
                      
                      // Deleted reminders list (expandable)
                      if (_showDeletedReminders)
                        Expanded(
                          child: StreamBuilder<List<Map<String, dynamic>>>(
                            stream: reminderService.buildDeletedRemindersStream(user.uid),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting && 
                                  _deletedReminders.isEmpty) {
                                return Center(child: CircularProgressIndicator());
                              }

                              if (snapshot.hasData) {
                                _deletedReminders = snapshot.data!;
                                _filteredDeletedReminders = _processReminders(_deletedReminders);
                              }

                              if (_filteredDeletedReminders.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      "No archived reminders",
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return ListView.builder(
                                padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 4.w),
                                itemCount: _filteredDeletedReminders.length,
                                itemBuilder: (context, index) {
                                  return _buildReminderCard(_filteredDeletedReminders[index], true);
                                },
                              );
                            },
                          ),
                        ),
                    ],
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
  Widget _buildReminderCard(Map<String, dynamic> reminder, bool isArchived) {
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
    
    // Format deleted date if archived
    String archivedDate = "";
    if (isArchived && reminder["deletedAt"] != null) {
      final date = reminder["deletedAt"] is DateTime 
          ? reminder["deletedAt"] 
          : reminder["deletedAt"].toDate();
      archivedDate = "Archived on: ${DateFormat('dd MMM yyyy').format(date)}";
    }
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 1.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      // Add visual indication based on status
      color: isArchived ? Colors.grey[200] : (isExpired ? Colors.red[50] : (isEnabled ? null : Colors.grey[100])),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reminder info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Medication name
                        Text(
                          medicationName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                            color: isArchived ? Colors.grey[700] : null,
                          ),
                        ),
                        
                        SizedBox(height: 0.5.h),
                        
                        // Schedule details
                        Text(
                          scheduleFrequency,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[700],
                          ),
                        ),
                        
                        SizedBox(height: 0.5.h),
                        
                        // Start date and duration
                        Text(
                          "From: $startDate  |  Duration: $duration",
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                        
                        // Show archived date if applicable
                        if (isArchived && archivedDate.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 0.5.h),
                            child: Text(
                              archivedDate,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Action buttons
                  Column(
                    children: [
                      if (isArchived) 
                        // Hard delete button for archived reminders
                        IconButton(
                          icon: Icon(Icons.delete_forever, color: Colors.red),
                          onPressed: () => _confirmHardDelete(reminder),
                        )
                      else
                        // Regular delete button for active reminders
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(reminder),
                        ),
                      
                      // Show enabled/expired status for active reminders
                      if (!isArchived)
                        isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Switch(
                                value: isEnabled,
                                onChanged: isExpired 
                                    ? null 
                                    : (value) => _toggleReminderState(reminder, value),
                              ),
                              
                      // Show restore button for archived reminders
                      if (isArchived)
                        IconButton(
                          icon: Icon(Icons.restore, color: Colors.blue),
                          onPressed: () => _restoreReminder(reminder),
                          tooltip: "Restore",
                        ),
                    ],
                  ),
                ],
              ),
              
              // Status indicators
              if (!isArchived && (isExpired || !isEnabled))
                Container(
                  margin: EdgeInsets.only(top: 1.h),
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: isExpired ? Colors.red[100] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    isExpired ? "Expired" : "Disabled",
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isExpired ? Colors.red[900] : Colors.grey[700],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Shows confirmation dialog before soft-deleting a reminder
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
                SnackBar(content: Text("Reminder archived successfully")),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Failed to archive reminder: $e")),
              );
            }
          }
        },
      ),
    );
  }
  
  /// Shows confirmation dialog before hard-deleting a reminder
  void _confirmHardDelete(Map<String, dynamic> reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Permanently Delete Reminder?"),
        content: Text(
          "Are you sure you want to permanently delete the reminder for ${reminder["medicationName"] ?? "Unnamed Medication"}? This action cannot be undone and all progress data will be lost."
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) {
                _showErrorSnackBar("You must be logged in to perform this action");
                return;
              }
              
              try {
                await reminderService.hardDeleteReminder(user.uid, reminder["id"]);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Reminder permanently deleted")),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  _showErrorSnackBar("Failed to delete reminder: $e");
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text("Delete Permanently"),
          ),
        ],
      ),
    );
  }
  
  /// Restores a soft-deleted reminder
  void _restoreReminder(Map<String, dynamic> reminder) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorSnackBar("You must be logged in to perform this action");
      return;
    }
    
    final reminderId = reminder["id"];
    
    setState(() {
      _loadingReminders[reminderId] = true;
    });
    
    try {
      // Update the reminder to remove the isDeleted flag
      await reminderService.firestoreService.updateDoc(
        collectionPath: "users/${user.uid}/reminders",
        docId: reminderId,
        newData: {
          'isDeleted': false,
          'deletedAt': FieldValue.delete(),
        },
      );
      
      // Update the medication reminderSet field if needed
      final medicationId = reminder["userMedicationId"];
      if (medicationId != null) {
        await reminderService.updateMedicationReminderStatus(user.uid, medicationId, true);
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Reminder restored successfully")),
        );
      }
    } catch (e) {
      _showErrorSnackBar("Failed to restore reminder: $e");
    } finally {
      if (mounted) {
        setState(() {
          _loadingReminders.remove(reminderId);
        });
      }
    }
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
}