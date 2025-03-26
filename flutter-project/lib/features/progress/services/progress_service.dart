import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eyedrop/features/progress/models/progress_entry.dart';
import 'package:eyedrop/shared/services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:eyedrop/shared/utils/timezone_util.dart';

/// Service class for handling medication adherence progress tracking.
class ProgressService {
  // Singleton pattern
  static final ProgressService _instance = ProgressService._internal();
  factory ProgressService() => _instance;
  ProgressService._internal();

  final FirestoreService _firestoreService = FirestoreService();
  
  /// Creates a progress entry for a medication that was taken (notification tapped)
  Future<void> recordMedicationTaken({
    required String userId,
    required String reminderId,
    required String medicationId,
    required DateTime scheduledAt,
    required DateTime respondedAt,
    required String scheduleType,
    String? medicationName, // Add this parameter
  }) async {
    // Validate inputs
    if (userId.isEmpty) throw ArgumentError("User ID cannot be empty");
    if (reminderId.isEmpty) throw ArgumentError("Reminder ID cannot be empty");
    if (medicationId.isEmpty) throw ArgumentError("Medication ID cannot be empty");
    if (respondedAt.isBefore(scheduledAt)) throw ArgumentError("Response time cannot be before scheduled time");
    
    final responseDelayMs = respondedAt.difference(scheduledAt).inMilliseconds;
    
    // Validate reasonable response delay (max 24 hours)
    if (responseDelayMs < 0 || responseDelayMs > 86400000) { // 24 hours in milliseconds
      throw ArgumentError("Response delay must be between 0 and 24 hours");
    }
    
    // Use timezone utilities for consistent date handling
    final localScheduledAt = TimezoneUtil.toLocalTime(scheduledAt);
    final dayString = TimezoneUtil.generateDayString(localScheduledAt);
    final hour = TimezoneUtil.getLocalHour(localScheduledAt);
    
    final progressData = {
      'reminderId': reminderId,
      'medicationId': medicationId,
      'medicationName': medicationName, // Add this field
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'respondedAt': Timestamp.fromDate(respondedAt),
      'responseDelayMs': responseDelayMs,
      'taken': true,
      'dayString': dayString,
      'scheduleType': scheduleType.toLowerCase(),
      'hour': hour,
      'timezone': TimezoneUtil.getCurrentTimezoneName(),
      'timezoneOffset': TimezoneUtil.getCurrentTimezoneOffset(),
      'createdAt': FieldValue.serverTimestamp(),
    };
    
    try {
      await _firestoreService.addDoc(
        path: "users/$userId/progress",
        data: progressData,
      );
      
      log('Recorded medication taken: $reminderId at ${scheduledAt.toString()}');
    } catch (e) {
      log('Error recording medication taken: $e');
      throw Exception('Failed to record medication taken: $e');
    }
  }
  
  /// Creates a progress entry for a medication that was missed (no response)
  Future<void> recordMedicationMissed({
    required String userId,
    required String reminderId,
    required String medicationId,
    required DateTime scheduledAt,
    required String scheduleType,
    String? medicationName, // Add this parameter
  }) async {
    // Validate inputs
    if (userId.isEmpty) throw ArgumentError("User ID cannot be empty");
    if (reminderId.isEmpty) throw ArgumentError("Reminder ID cannot be empty");
    if (medicationId.isEmpty) throw ArgumentError("Medication ID cannot be empty");
    
    // Use timezone utilities for consistent date handling
    final localScheduledAt = TimezoneUtil.toLocalTime(scheduledAt);
    final dayString = TimezoneUtil.generateDayString(localScheduledAt);
    final hour = TimezoneUtil.getLocalHour(localScheduledAt);
    
    final progressData = {
      'reminderId': reminderId,
      'medicationId': medicationId,
      'medicationName': medicationName, // Add this field
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'respondedAt': null,
      'responseDelayMs': null,
      'taken': false,
      'dayString': dayString,
      'scheduleType': scheduleType.toLowerCase(),
      'hour': hour,
      'timezone': TimezoneUtil.getCurrentTimezoneName(),
      'timezoneOffset': TimezoneUtil.getCurrentTimezoneOffset(),
      'createdAt': FieldValue.serverTimestamp(),
    };
    
    try {
      await _firestoreService.addDoc(
        path: "users/$userId/progress",
        data: progressData,
      );
      
      log('Recorded medication missed: $reminderId at ${scheduledAt.toString()}');
    } catch (e) {
      log('Error recording medication missed: $e');
      throw Exception('Failed to record medication missed: $e');
    }
  }
  
  /// Checks if a progress entry exists for a specific reminder and time
  /// 
  /// Useful for plotting adherence for each hour in the day to find periods of non-adherence.
  Future<bool> hasProgressEntryForScheduledTime({
    required String userId,
    required String reminderId,
    required DateTime scheduledTime,
  }) async {
    try {
      final dayString = DateFormat('yyyy-MM-dd').format(scheduledTime);
      final hour = scheduledTime.hour;
      
      final entries = await _firestoreService.queryCollectionWithIds(
        collectionPath: "users/$userId/progress",
        filters: [
          {'field': 'reminderId', 'operator': '==', 'value': reminderId},
          {'field': 'dayString', 'operator': '==', 'value': dayString},
          {'field': 'hour', 'operator': '==', 'value': hour},
        ],
      );
      
      return entries.isNotEmpty;
    } catch (e) {
      log('Error checking progress entry: $e');
      return false;
    }
  }
  
  /// Gets all progress entries for a user
  Future<List<ProgressEntry>> getProgressEntries({
    required String userId, 
    String? medicationId,
    String? reminderId,
    DateTime? startDate,
    DateTime? endDate,
    int pageSize = 50,
    String? lastDocument,
    bool noCache = false, // Add this parameter
  }) async {
    try {
      if (userId.isEmpty) {
        throw Exception("User ID cannot be empty");
      }
      
      log("user ID: $userId");
      
      // First, get all relevant reminders
      final reminderPath = "users/$userId/reminders";
      
      // Get all reminders (without filtering by deletion status since we don't have that field anymore)
      final reminders = await _firestoreService.queryCollectionWithIds(
        collectionPath: reminderPath
      );
      log("Found ${reminders.length} reminders");
      
      // Extract reminder IDs
      final reminderIds = reminders.map((r) => r['id'] as String).toList();
      
      if (reminderIds.isEmpty) {
        log("No reminders found");
        return [];
      }
      
      // Handle Firestore's 10-item limit for "in" queries
      List<List<String>> reminderIdBatches = [];
      for (int i = 0; i < reminderIds.length; i += 10) {
        int end = i + 10;
        if (end > reminderIds.length) {
          end = reminderIds.length;
        }
        reminderIdBatches.add(reminderIds.sublist(i, end));
      }
      
      List<ProgressEntry> allEntries = [];
      
      for (final batch in reminderIdBatches) {
        List<Map<String, dynamic>> batchFilters = [
          {'field': 'reminderId', 'operator': 'in', 'value': batch},
        ];
        
        // Add optional filters
        if (medicationId != null) {
          batchFilters.add({'field': 'medicationId', 'operator': '==', 'value': medicationId});
        }
        
        if (reminderId != null) {
          batchFilters.add({'field': 'reminderId', 'operator': '==', 'value': reminderId});
        }
        
        if (startDate != null) {
          final startTimestamp = Timestamp.fromDate(startDate);
          batchFilters.add({'field': 'scheduledAt', 'operator': '>=', 'value': startTimestamp});
        }
        
        if (endDate != null) {
          final endTimestamp = Timestamp.fromDate(endDate);
          batchFilters.add({'field': 'scheduledAt', 'operator': '<=', 'value': endTimestamp});
        }
        
        final entries = await _firestoreService.queryCollectionWithIds(
          collectionPath: "users/$userId/progress",
          filters: batchFilters,
          orderBy: {'field': 'scheduledAt', 'descending': true},
          limit: pageSize,
          startAfterDocument: lastDocument,
          noCache: noCache, // Pass the parameter through
        );
        
        // Convert to ProgressEntry objects
        final progressEntries = entries.map((e) => 
          ProgressEntry.fromFirestore(e, e['id'] as String)
        ).toList();
        
        allEntries.addAll(progressEntries);
      }
      
      // If we need to sort or limit the combined results
      if (allEntries.length > pageSize) {
        allEntries.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
        allEntries = allEntries.take(pageSize).toList();
      }
      
      log("Returning ${allEntries.length} progress entries");
      return allEntries;
    } catch (e) {
      log('Error getting progress entries: $e');
      throw Exception("Failed to retrieve progress data: $e");
    }
  }
  
  /// Calculates adherence statistics for a set of progress entries
  Map<String, dynamic> calculateAdherenceStats(List<ProgressEntry> entries) {
    if (entries.isEmpty) {
      return _getEmptyStatsMap();
    }
    
    // Group entries by schedule type
    final Map<String, List<ProgressEntry>> byScheduleType = {};
    for (var entry in entries) {
      final scheduleType = entry.scheduleType.toLowerCase();
      if (!byScheduleType.containsKey(scheduleType)) {
        byScheduleType[scheduleType] = [];
      }
      byScheduleType[scheduleType]!.add(entry);
    }
    
    // Calculate basic stats
    int takenCount = entries.where((e) => e.taken).length;
    int totalCount = entries.length;
    double adherencePercentage = (takenCount / totalCount) * 100;
    
    // Calculate average response delay for taken medications
    List<int> responseDelays = entries
        .where((e) => e.taken && e.responseDelayMs != null)
        .map((e) => e.responseDelayMs!)
        .toList();
    
    int averageResponseDelayMs = responseDelays.isEmpty 
        ? 0
        : responseDelays.reduce((a, b) => a + b) ~/ responseDelays.length;
    
    
  
    return {
      'adherencePercentage': adherencePercentage,
      'takenCount': takenCount,
      'missedCount': totalCount - takenCount,
      'totalCount': totalCount,
      'averageResponseDelayMs': averageResponseDelayMs,
    };
  }
  
  
  /// Helper: Get ISO week number (1-53) from a date
  int _getIsoWeekNumber(DateTime date) {
    // Creates a DateTime object for the Thursday in the current week
    // Per ISO 8601, the first week of a year contains January 4th
    final thursday = date.subtract(Duration(days: date.weekday - DateTime.thursday));
    // Calculate the week number
    return ((thursday.difference(DateTime(thursday.year, 1, 1)).inDays) / 7).floor() + 1;
  }
  
  /// Calculates schedule-specific adherence statistics
  Map<String, dynamic> calculateScheduleTypeStats(List<ProgressEntry> entries) {
    // Group entries by schedule type
    Map<String, List<ProgressEntry>> byScheduleType = {};
    
    for (var entry in entries) {
      if (!byScheduleType.containsKey(entry.scheduleType)) {
        byScheduleType[entry.scheduleType] = [];
      }
      byScheduleType[entry.scheduleType]!.add(entry);
    }
    
    // Calculate stats for each schedule type
    Map<String, dynamic> result = {};
    
    for (var scheduleType in byScheduleType.keys) {
      final typeEntries = byScheduleType[scheduleType]!;
      
      // Use different calculation methods based on the schedule type
      if (scheduleType.toLowerCase() == 'weekly') {
        result[scheduleType] = _calculateWeeklyAdherenceStats(typeEntries);
      } else if (scheduleType.toLowerCase() == 'monthly') {
        result[scheduleType] = _calculateMonthlyAdherenceStats(typeEntries);
      } else {
        // Default to daily calculation method
        result[scheduleType] = _calculateDailyAdherenceStats(typeEntries);
      }
    }
    
    return result;
  }
  
  /// Calculates adherence stats for daily medications
  Map<String, dynamic> _calculateDailyAdherenceStats(List<ProgressEntry> entries) {
    if (entries.isEmpty) {
      return _getEmptyStatsMap();
    }
    
    int takenCount = entries.where((e) => e.taken).length;
    int totalCount = entries.length;
    double adherencePercentage = (takenCount / totalCount) * 100;
    
    // Calculate average response delay
    List<int> responseDelays = entries
        .where((e) => e.taken && e.responseDelayMs != null)
        .map((e) => e.responseDelayMs!)
        .toList();
    
    int averageResponseDelayMs = responseDelays.isEmpty 
        ? 0
        : responseDelays.reduce((a, b) => a + b) ~/ responseDelays.length;
   
    return {
      'adherencePercentage': adherencePercentage,
      'takenCount': takenCount,
      'missedCount': totalCount - takenCount,
      'totalCount': totalCount,
      'averageResponseDelayMs': averageResponseDelayMs,
    };
  }
  
  /// Calculates adherence stats specifically for weekly medications
  Map<String, dynamic> _calculateWeeklyAdherenceStats(List<ProgressEntry> entries) {
    if (entries.isEmpty) {
      return _getEmptyStatsMap();
    }
    
    // Group entries by week
    Map<String, List<ProgressEntry>> entriesByWeek = {};
    for (var entry in entries) {
      final date = DateFormat('yyyy-MM-dd').parse(entry.dayString);
      final weekYear = date.year;
      final weekNumber = _getIsoWeekNumber(date);
      final weekKey = '$weekYear-W$weekNumber';
      
      if (!entriesByWeek.containsKey(weekKey)) {
        entriesByWeek[weekKey] = [];
      }
      entriesByWeek[weekKey]!.add(entry);
    }
    
    // Calculate adherence by week
    int takenWeeks = 0;
    int totalWeeks = entriesByWeek.length;
    
    for (var weekEntries in entriesByWeek.values) {
      if (weekEntries.every((e) => e.taken)) {
        takenWeeks++;
      }
    }
    
    // Individual entries stats
    int takenCount = entries.where((e) => e.taken).length;
    int totalCount = entries.length;
    double entryAdherencePercentage = (takenCount / totalCount) * 100;
    
    // Week-based adherence percentage
    double weekAdherencePercentage = totalWeeks > 0 ? (takenWeeks / totalWeeks) * 100 : 0;
    
    // Calculate average response delay
    List<int> responseDelays = entries
        .where((e) => e.taken && e.responseDelayMs != null)
        .map((e) => e.responseDelayMs!)
        .toList();
    
    int averageResponseDelayMs = responseDelays.isEmpty 
        ? 0
        : responseDelays.reduce((a, b) => a + b) ~/ responseDelays.length;
    
    
    
    return {
      'adherencePercentage': weekAdherencePercentage, // Use week-based percentage
      'entryAdherencePercentage': entryAdherencePercentage, // Keep individual entry percentage too
      'takenCount': takenCount,
      'missedCount': totalCount - takenCount,
      'totalCount': totalCount,
      'takenWeeks': takenWeeks,
      'totalWeeks': totalWeeks,
      'averageResponseDelayMs': averageResponseDelayMs,
    };
  }
  
  /// Calculates adherence stats specifically for monthly medications
  Map<String, dynamic> _calculateMonthlyAdherenceStats(List<ProgressEntry> entries) {
    if (entries.isEmpty) {
      return _getEmptyStatsMap();
    }
    
    // Group entries by month
    Map<String, List<ProgressEntry>> entriesByMonth = {};
    for (var entry in entries) {
      final date = DateFormat('yyyy-MM-dd').parse(entry.dayString);
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      
      if (!entriesByMonth.containsKey(monthKey)) {
        entriesByMonth[monthKey] = [];
      }
      entriesByMonth[monthKey]!.add(entry);
    }
    
    // Calculate adherence by month
    int takenMonths = 0;
    int totalMonths = entriesByMonth.length;
    
    for (var monthEntries in entriesByMonth.values) {
      if (monthEntries.every((e) => e.taken)) {
        takenMonths++;
      }
    }
    
    // Individual entries stats
    int takenCount = entries.where((e) => e.taken).length;
    int totalCount = entries.length;
    double entryAdherencePercentage = (takenCount / totalCount) * 100;
    
    // Month-based adherence percentage
    double monthAdherencePercentage = totalMonths > 0 ? (takenMonths / totalMonths) * 100 : 0;
    
    // Calculate average response delay
    List<int> responseDelays = entries
        .where((e) => e.taken && e.responseDelayMs != null)
        .map((e) => e.responseDelayMs!)
        .toList();
    
    int averageResponseDelayMs = responseDelays.isEmpty 
        ? 0
        : responseDelays.reduce((a, b) => a + b) ~/ responseDelays.length;
    
    
    return {
      'adherencePercentage': monthAdherencePercentage, // Use month-based percentage
      'entryAdherencePercentage': entryAdherencePercentage, // Keep individual entry percentage too
      'takenCount': takenCount,
      'missedCount': totalCount - takenCount,
      'totalCount': totalCount,
      'takenMonths': takenMonths,
      'totalMonths': totalMonths,
      'averageResponseDelayMs': averageResponseDelayMs,
    };
  }
  
  /// Returns an empty stats map with default values
  Map<String, dynamic> _getEmptyStatsMap() {
    return {
      'adherencePercentage': 0.0,
      'takenCount': 0,
      'missedCount': 0,
      'totalCount': 0,
      'averageResponseDelayMs': 0,
    };
  }
  
  /// Gets all progress entries for specific medication
  Future<List<ProgressEntry>> getProgressEntriesForMedication({
    required String userId,
    required String medicationId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return getProgressEntries(
      userId: userId,
      medicationId: medicationId,
      startDate: startDate,
      endDate: endDate,
    );
  }
  
  /// Delete progress entries for a reminder (when a user wants to delete all history)
  Future<void> deleteProgressEntriesForReminder({
    required String userId,
    required String reminderId,
  }) async {
    try {
      if (userId.isEmpty || reminderId.isEmpty) {
        throw ArgumentError('User ID and reminder ID cannot be empty');
      }
      
      log("Attempting to delete progress entries for reminder: $reminderId");
      
      // Query all progress entries for this reminder
      final entries = await _firestoreService.queryCollectionWithIds(
        collectionPath: "users/$userId/progress",
        filters: [{'field': 'reminderId', 'operator': '==', 'value': reminderId}]
      );
      
      log("Found ${entries.length} progress entries to delete");
      
      // Delete each entry
      for (var entry in entries) {
        await _firestoreService.deleteDoc(
          collectionPath: "users/$userId/progress",
          docId: entry['id'],
        );
      }
      
      log('Deleted all progress entries for reminder: $reminderId');
      return;
    } catch (e) {
      log('Error deleting progress entries: $e');
      throw Exception('Failed to delete progress entries: $e');
    }
  }

  /// Creates a real-time stream of progress entries changes
  Stream<List<Map<String, dynamic>>> getProgressEntriesStream(String userId) {
    if (userId.isEmpty) {
      return Stream.value([]);
    }
    
    try {
      // Use the no-cache version for real-time updates
      return _firestoreService.getCollectionStreamWithIdsNoCache("users/$userId/progress");
    } catch (e) {
      log('Error creating progress entries stream: $e');
      return Stream.value([]);
    }
  }

  /// Gets all progress entries for statistics calculation (no pagination)
  Future<List<ProgressEntry>> getAllProgressEntriesForStats({
    required String userId, 
    String? medicationId,
    String? reminderId,
    DateTime? startDate,
    DateTime? endDate,
    bool noCache = false,
  }) async {
    try {
      if (userId.isEmpty) {
        throw ArgumentError("User ID is required");
      }
      
      // Build collection path
      final collectionPath = "users/$userId/progress";
      
      // Create filters based on parameters
      List<Map<String, dynamic>> filters = [];
      
      // Add medication filter if specified
      if (medicationId != null && medicationId.isNotEmpty) {
        filters.add({
          'field': 'medicationId',
          'operator': '==',
          'value': medicationId,
        });
      }
      
      // Add reminder filter if specified
      if (reminderId != null && reminderId.isNotEmpty) {
        filters.add({
          'field': 'reminderId',
          'operator': '==',
          'value': reminderId,
        });
      }
      
      // Add date range filters if specified
      if (startDate != null) {
        filters.add({
          'field': 'scheduledAt',
          'operator': '>=',
          'value': Timestamp.fromDate(startDate),
        });
      }
      
      if (endDate != null) {
        // Include the full day of the end date
        final adjustedEndDate = DateTime(
          endDate.year, 
          endDate.month, 
          endDate.day, 
          23, 59, 59
        );
        
        filters.add({
          'field': 'scheduledAt',
          'operator': '<=',
          'value': Timestamp.fromDate(adjustedEndDate),
        });
      }
      
      // Query Firestore with filters and order by scheduledAt
      final entriesData = await _firestoreService.queryCollectionWithIds(
        collectionPath: collectionPath,
        filters: filters.isEmpty ? null : filters,
        orderBy: {'field': 'scheduledAt', 'descending': true},
        noCache: noCache,
        // No pagination parameters - get all entries
      );
      
      // Convert to ProgressEntry objects
      final allEntries = entriesData.map((data) {
        try {
          return ProgressEntry.fromFirestore(data, data['id'] ?? '');
        } catch (e) {
          log('Error parsing progress entry: $e');
          return null;
        }
      }).whereType<ProgressEntry>().toList();
      
      return allEntries;
    } catch (e) {
      log('Error getting all progress entries for stats: $e');
      throw Exception('Failed to retrieve progress data for statistics: $e');
    }
  }

  
}