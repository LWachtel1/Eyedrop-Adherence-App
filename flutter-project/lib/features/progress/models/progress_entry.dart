import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Represents a single medication reminder event and the user's response to it.
class ProgressEntry {
  final String id;
  final String reminderId;
  final String medicationId;
  final DateTime scheduledAt;
  final DateTime? respondedAt;
  final int? responseDelayMs;
  final bool taken;
  final String dayString;
  final String scheduleType;
  final int hour;
  final String? timezone;
  final int? timezoneOffset;

  ProgressEntry({
    required this.id,
    required this.reminderId,
    required this.medicationId,
    required this.scheduledAt,
    this.respondedAt,
    this.responseDelayMs,
    required this.taken,
    required this.dayString,
    required this.scheduleType,
    required this.hour,
    this.timezone,
    this.timezoneOffset,
  });

  /// Creates a ProgressEntry from Firestore data with validation
  factory ProgressEntry.fromFirestore(Map<String, dynamic> data, String id) {
    // Validate id
    if (id.isEmpty) {
      throw ArgumentError('Progress entry ID cannot be empty');
    }
    
    // Validate essential fields
    final reminderId = data['reminderId'] as String? ?? '';
    if (reminderId.isEmpty) {
      throw ArgumentError('Reminder ID cannot be empty');
    }
    
    final medicationId = data['medicationId'] as String? ?? '';
    if (medicationId.isEmpty) {
      throw ArgumentError('Medication ID cannot be empty');
    }
    
    // Extract and validate scheduledAt
    DateTime scheduledAt;
    if (data['scheduledAt'] is Timestamp) {
      scheduledAt = (data['scheduledAt'] as Timestamp).toDate();
    } else if (data['scheduledAt'] is DateTime) {
      scheduledAt = data['scheduledAt'] as DateTime;
    } else {
      throw ArgumentError('Invalid or missing scheduledAt timestamp');
    }
    
    // Extract and validate respondedAt if present
    DateTime? respondedAt;
    if (data['respondedAt'] is Timestamp) {
      respondedAt = (data['respondedAt'] as Timestamp).toDate();
    } else if (data['respondedAt'] is DateTime) {
      respondedAt = data['respondedAt'] as DateTime;
    }
    
    // If both dates are present, ensure respondedAt is after scheduledAt
    if (respondedAt != null && respondedAt.isBefore(scheduledAt)) {
      throw ArgumentError('Response time cannot be before scheduled time');
    }
    
    // Validate and extract other fields
    final responseDelayMs = data['responseDelayMs'] as int?;
    final taken = data['taken'] as bool? ?? false;
    
    String dayString = data['dayString'] as String? ?? '';
    if (dayString.isEmpty) {
      // Generate day string from scheduledAt if missing
      dayString = DateFormat('yyyy-MM-dd').format(scheduledAt);
    }
    
    final scheduleType = data['scheduleType'] as String? ?? 'daily';
    
    int hour;
    if (data['hour'] is int) {
      hour = data['hour'] as int;
    } else {
      // Extract hour from scheduledAt if missing
      hour = scheduledAt.hour;
    }
    
    // Ensure hour is within valid range
    if (hour < 0 || hour > 23) {
      throw ArgumentError('Hour must be between 0 and 23');
    }
    
    // Extract timezone information
    final timezone = data['timezone'] as String?;
    final timezoneOffset = data['timezoneOffset'] as int?;
    
    return ProgressEntry(
      id: id,
      reminderId: reminderId,
      medicationId: medicationId,
      scheduledAt: scheduledAt,
      respondedAt: respondedAt,
      responseDelayMs: responseDelayMs,
      taken: taken,
      dayString: dayString,
      scheduleType: scheduleType,
      hour: hour,
      timezone: timezone,
      timezoneOffset: timezoneOffset,
    );
  }

  /// Converts ProgressEntry to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'reminderId': reminderId,
      'medicationId': medicationId,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'responseDelayMs': responseDelayMs,
      'taken': taken,
      'dayString': dayString,
      'scheduleType': scheduleType,
      'hour': hour,
      'timezone': timezone,
      'timezoneOffset': timezoneOffset,
    };
  }
}