import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:rxdart/subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:eyedrop/features/reminders/services/reminder_service.dart';
import 'package:eyedrop/features/notifications/models/notification_data.dart';

/// NotificationService is a singleton class responsible for handling all local notification logic.
/// 
/// It handles scheduling, displaying, and cancelling medication reminders. 
/// It supports manual and smart scheduling and integrates with the timezone and shared preferences packages.
/// 
/// 
class NotificationService {

  // Singleton instance.
  static final NotificationService _instance = NotificationService._internal();

  // Flutter plugin for local notifications, providing cross-platform functionality for local notification display.
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Stream controller for handling notification taps.
  final BehaviorSubject<NotificationData?> _notificationSubject = BehaviorSubject<NotificationData?>();

  // Keys used for storing user preferences in SharedPreferences.
  final String _enabledKey = 'notifications_enabled';
  final String _soundEnabledKey = 'notifications_sound_enabled';
  final String _vibrationEnabledKey = 'notifications_vibration_enabled';
  
  bool _isInitialized = false;
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  
  // A cache to track all scheduled notifications
  final Map<String, List<Map<String, dynamic>>> _scheduledNotificationsCache = {};
  
  factory NotificationService() => _instance;
  
  NotificationService._internal();
  
  /// Exposes stream of notification taps.
  Stream<NotificationData?> get notificationStream => _notificationSubject.stream;
  
  //// Getters for notification state.
  bool get notificationsEnabled => _notificationsEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  
  /// Initializes timezone data, permissions, and the notification plugin.
  Future<void> initialize() async {
    try{
    if (_isInitialized) return;
    
    log("Starting notification service initialization");
    // Load settings
    await _loadSettings();
    
    // Initialises timezone database.
    tz_data.initializeTimeZones();
    
    // Requests permission (iOS)s
    final permission = await _requestPermission();
    if (!permission) {
      log('Notification permissions denied');
      _notificationsEnabled = false;
      await _saveSettings();
    }
    
    // Initialises notification plugin.
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    _isInitialized = true;
    } catch (e) {
      log("Error initializing notification service: $e");
      _isInitialized = true;
    }
  }
  
  /// Requests permissions for notifications on supported platforms.
  Future<bool> _requestPermission() async {
    if (Platform.isIOS || Platform.isMacOS) {
    final iosPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final macPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();

    return await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        await macPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;
  }
    if (Platform.isAndroid) {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  return true;

}

  
  
  /// Parses and processes tapped notifications.
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final parts = response.payload!.split('|');
        final data = NotificationData(
          reminderId: parts[0],
          medicationId: parts.length > 1 ? parts[1] : '',
          medicationName: parts.length > 2 ? parts[2] : 'Medication',
        );
        _notificationSubject.add(data);
      } catch (e) {
        log('Error parsing notification payload: $e');
      }
    }
  }
  
  /// Schedules a local notification for a specific reminder.
  Future<int> scheduleReminderNotification({
    required String reminderId,
    required String medicationId,
    required String medicationName,
    required DateTime scheduledTime,
    String? applicationSite,
    String? doseInfo,
  }) async {
    if (!_isInitialized) await initialize();
    if (!_notificationsEnabled) return -1;
    
    // Creates a unique notification ID based on the reminder ID and time.
    final hour = scheduledTime.hour;
    final minute = scheduledTime.minute;
    final timeString = '$hour:$minute';
    final notificationId = '${reminderId}_$timeString'.hashCode;
    final scheduledTimestamp = scheduledTime.millisecondsSinceEpoch.toString();

    log('Attempting to schedule notification: ID=$notificationId, time=${scheduledTime.toString()}');
    
    // Build notification details.
    final notificationDetails = await _buildNotificationDetails(
      title: 'Medication Reminder',
      body: _buildNotificationBody(medicationName, applicationSite, doseInfo),
    );
    
    try {
      // Creates payload string with key reminder data including scheduled time.
      final payload = '$reminderId|$medicationId|$medicationName|$scheduledTimestamp';
      
      // Schedules notification.
      await _localNotifications.zonedSchedule(
        notificationId,
        'Medication Reminder',
        _buildNotificationBody(medicationName, applicationSite, doseInfo),
        tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      
      // Save this notification to our cache
      if (!_scheduledNotificationsCache.containsKey(reminderId)) {
        _scheduledNotificationsCache[reminderId] = [];
      }
      
      _scheduledNotificationsCache[reminderId]!.add({
        'id': notificationId,
        'reminderId': reminderId,
        'medicationId': medicationId,
        'medicationName': medicationName,
        'scheduledTime': scheduledTime.millisecondsSinceEpoch,
        'payload': payload
      });
      
      log('Successfully scheduled notification for $medicationName at ${scheduledTime.toString()}');
      return notificationId;
    } catch (e) {
      log('Error scheduling notification: $e');
      return -1;
    }
  }
  
  /// Build the notification body text based on available information.
  String _buildNotificationBody(String medicationName, String? applicationSite, String? doseInfo) {
    String body = 'Time to take $medicationName';
    
    if (doseInfo != null && doseInfo.isNotEmpty) {
      body += ' - $doseInfo';
    }
    
    if (applicationSite != null && applicationSite.isNotEmpty) {
      // Format application site (left/right/both eyes)
      body += ' (${applicationSite.toLowerCase()})';
    }
    
    return body;
  }
  
  /// Cancels a specific scheduled notification by ID.
  Future<void> cancelNotification(int id) async {
    if (!_isInitialized) await initialize();
    
    try {
      await _localNotifications.cancel(id);
      log('Cancelled notification with ID: $id');
    } catch (e) {
      log('Error cancelling notification: $e');
    }
  }
  
  /// Cancel all notifications for a SPECIFIC active reminder.
  Future<void> cancelReminderNotifications(String reminderId) async {
    if (!_isInitialized) await initialize();
    
    try {
      log('Attempting to cancel notifications for reminder: $reminderId');
      
      // Get all pending notifications
      final pendingNotifications = await _localNotifications.pendingNotificationRequests();
      int cancelCount = 0;
      
      // Identify and cancel notifications based on payload
      for (final notification in pendingNotifications) {
        if (notification.payload != null) {
          final payloadParts = notification.payload!.split('|');
          if (payloadParts.isNotEmpty && payloadParts[0] == reminderId) {
            await _localNotifications.cancel(notification.id);
            cancelCount++;
            log('Cancelled notification with ID: ${notification.id}');
          }
        }
      }
      
      // Clear this reminder from our cache
      _scheduledNotificationsCache.remove(reminderId);
      
      log('Cancelled $cancelCount notifications for reminder: $reminderId');
    } catch (e) {
      log('Error cancelling reminder notifications: $e');
    }
  }
  
  /// Schedule notifications for all reminders of a specific user.
  Future<void> scheduleAllReminders(String userId, ReminderService reminderService) async {
    if (!_isInitialized) await initialize();
    if (!_notificationsEnabled) return;
    
    try {
      // First cancel all existing notifications.
      await cancelAllNotifications();
      
      // Gets all enabled reminders.
      final reminders = await reminderService.getAllEnabledReminders(userId);
      log('Scheduling notifications for ${reminders.length} enabled reminders');
      
      for (final reminder in reminders) {
        final reminderId = reminder['id'];
        final medicationId = reminder['userMedicationId'];
        final medicationName = reminder['medicationName'] ?? 'Medication';
        final doseQuantity = reminder['doseQuantity']?.toString() ?? '';
        final doseUnits = reminder['doseUnits'] ?? '';
        final doseInfo = '$doseQuantity $doseUnits'.trim();
        String? applicationSite;
        
        if (reminder['medicationType'] == 'Eye Medication') {
          applicationSite = reminder['applicationSite'];
        }
        
        // Handles different reminder types.
        if (reminder['smartScheduling'] == false && reminder['timings'] is List) {
          // Manual scheduling with specific times.
          log('Scheduling manual reminder for ${reminder['medicationName']}');
          await scheduleManualReminder(
            reminderId: reminderId,
            medicationId: medicationId,
            medicationName: medicationName,
            applicationSite: applicationSite,
            doseInfo: doseInfo,
            timings: reminder['timings'],
          );
        } else {
          // Smart scheduling.
          log('Scheduling smart reminder for ${reminder['medicationName']}');
          await scheduleSmartReminder(
            reminderId: reminderId,
            medicationId: medicationId,
            medicationName: medicationName,
            applicationSite: applicationSite,
            doseInfo: doseInfo,
            frequency: reminder['frequency'] ?? 1,
            scheduleType: reminder['scheduleType'] ?? 'daily', // Add scheduleType parameter
            startTime: reminder['startTime'],
            endTime: reminder['endTime'],
          );
        }
      }
      
      log('Scheduled all reminders for user: $userId');
    } catch (e, stackTrace) {
      log('Error scheduling all reminders: $e');
      log('Stack trace: $stackTrace');
    }
  }
  
  /// Schedule a manually configured reminder with specific times.
  Future<void> scheduleManualReminder({
    required String reminderId,
    required String medicationId,
    required String medicationName,
    String? applicationSite,
    String? doseInfo,
    required List timings,
  }) async {
    final now = DateTime.now();
    
    log('Scheduling manual reminder for $medicationName with ${timings.length} timings');
    
    for (final timing in timings) {
      try {
        // Log the timing for debugging
        log('Processing timing: $timing (${timing.runtimeType})');
        
        // Handle timings as Map with hour/minute fields.
        int hour;
        int minute;
        
        if (timing is Map) {
          // Extracts hour and minute from the map.
          hour = timing['hour'] is int ? timing['hour'] : int.tryParse(timing['hour']?.toString() ?? '0') ?? 0;
          minute = timing['minute'] is int ? timing['minute'] : int.tryParse(timing['minute']?.toString() ?? '0') ?? 0;
          log('Extracted time from map: $hour:$minute');
        } else if (timing is String) {
          // Handle string format (like "21:35").
          final parts = timing.split(':');
          hour = int.parse(parts[0]);
          minute = int.parse(parts[1]);
          log('Extracted time from string: $hour:$minute');
        } else {
          // Skip invalid format.
          log('Invalid timing format: $timing');
          continue;
        }
        
        // Create a DateTime for today with the specified time.
        var scheduledTime = DateTime(
          now.year, now.month, now.day, hour, minute);
        
        // If the time is in the past, schedule for tomorrow.
        if (scheduledTime.isBefore(now)) {
          scheduledTime = scheduledTime.add(const Duration(days: 1));
          log('Time already passed today, scheduling for tomorrow: ${scheduledTime.toString()}');
        }
        
        // Schedule the notification.
        final notificationId = await scheduleReminderNotification(
          reminderId: reminderId,
          medicationId: medicationId,
          medicationName: medicationName,
          scheduledTime: scheduledTime,
          applicationSite: applicationSite,
          doseInfo: doseInfo,
        );
        
        log('Scheduled notification with ID: $notificationId for time: $hour:$minute');
      } catch (e) {
        log('Error scheduling manual reminder: $e');
      }
    }
  }
  
  /// Schedule a smart reminder with calculated times based on frequency and schedule type.
  Future<void> scheduleSmartReminder({
    required String reminderId,
    required String medicationId,
    required String medicationName,
    String? applicationSite,
    String? doseInfo,
    required int frequency,
    required String scheduleType, // Add scheduleType parameter
    String? startTime,
    String? endTime,
  }) async {
    try {
      // Calculates reminder times based on schedule type and frequency
      final times = _calculateScheduleTimes(
        frequency: frequency,
        scheduleType: scheduleType, // Pass scheduleType
        startTime: startTime,
        endTime: endTime,
      );
      
      log('Smart scheduling for $medicationName: ${times.length} times calculated');
      
      // Schedules a notification for each calculated time
      for (final time in times) {
        await scheduleReminderNotification(
          reminderId: reminderId,
          medicationId: medicationId,
          medicationName: medicationName,
          scheduledTime: time,
          applicationSite: applicationSite,
          doseInfo: doseInfo,
        );
      }
    } catch (e) {
      log('Error scheduling smart reminder: $e');
    }
  }

  /// Calculates schedule times based on frequency and schedule type
  List<DateTime> _calculateScheduleTimes({
    required int frequency,
    required String scheduleType,
    String? startTime,
    String? endTime,
  }) {
    scheduleType = scheduleType.toLowerCase();
    
    // Use different scheduling strategies based on schedule type
    if (scheduleType == 'weekly') {
      return _calculateWeeklyScheduleTimes(frequency, startTime, endTime);
    } else if (scheduleType == 'monthly') {
      return _calculateMonthlyScheduleTimes(frequency, startTime, endTime);
    } else {
      // Default to daily scheduling for daily or any other schedule types
      return _calculateDailyScheduleTimes(frequency, startTime, endTime);
    }
  }

  /// Calculates evenly distributed times for daily schedules
  List<DateTime> _calculateDailyScheduleTimes(
    int frequency, 
    String? startTime, 
    String? endTime
  ) {
    final now = DateTime.now();
    final List<DateTime> times = [];
    
    // Default time window (8:00 AM to 10:00 PM)
    final defaultStartHour = 8;
    final defaultEndHour = 22;
    
    int startHour = defaultStartHour;
    int startMinute = 0;
    int endHour = defaultEndHour;
    int endMinute = 0;
    
    // Parse start time if provided
    if (startTime != null && startTime.isNotEmpty) {
      final parts = startTime.split(':');
      if (parts.length >= 2) {
        startHour = int.tryParse(parts[0]) ?? defaultStartHour;
        startMinute = int.tryParse(parts[1]) ?? 0;
      }
    }
    
    // Parse end time if provided
    if (endTime != null && endTime.isNotEmpty) {
      final parts = endTime.split(':');
      if (parts.length >= 2) {
        endHour = int.tryParse(parts[0]) ?? defaultEndHour;
        endMinute = int.tryParse(parts[1]) ?? 0;
      }
    }
    
    // Calculate total minutes in the active period
    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;
    final totalMinutes = endMinutes - startMinutes;
    
    // Calculate interval between doses
    final interval = frequency > 1 ? totalMinutes ~/ (frequency - 1) : totalMinutes;
    
    // Calculate times
    for (int i = 0; i < frequency; i++) {
      final minutes = startMinutes + (i * interval);
      final hour = minutes ~/ 60;
      final minute = minutes % 60;
      
      // Create DateTime for the calculated time
      DateTime time = DateTime(now.year, now.month, now.day, hour, minute);
      
      // If the time is in the past, schedule for tomorrow
      if (time.isBefore(now)) {
        time = time.add(const Duration(days: 1));
      }
      
      times.add(time);
    }
    
    return times;
  }

  /// Calculates evenly distributed times for weekly schedules
  List<DateTime> _calculateWeeklyScheduleTimes(
    int frequency, 
    String? startTime, 
    String? endTime
  ) {
    final now = DateTime.now();
    final List<DateTime> times = [];
    
    // Parse default time from start/end time params
    var defaultTime = _parseTimeOfDay(startTime) ?? TimeOfDay(hour: 9, minute: 0);
    
    // Calculate how many days to distribute the doses over
    int daysToUse = math.min(7, frequency);
    
    // Calculate days between doses
    int interval = frequency <= 7 ? (7 / frequency).floor() : 1;
    
    // Starting from today, calculate the next 'frequency' days
    int currentDay = 0;
    while (times.length < frequency) {
      final dayToSchedule = now.add(Duration(days: currentDay));
      final hour = defaultTime.hour;
      final minute = defaultTime.minute;
      
      // Create DateTime for this day
      DateTime time = DateTime(
        dayToSchedule.year, 
        dayToSchedule.month, 
        dayToSchedule.day, 
        hour, 
        minute
      );
      
      // If it's today and the time has passed, move to tomorrow
      if (currentDay == 0 && time.isBefore(now)) {
        currentDay++;
        continue;
      }
      
      times.add(time);
      
      // Move to next day based on interval
      currentDay += interval;
      
      // For frequencies greater than 7, we need to add multiple per day
      if (frequency > 7 && times.length % daysToUse == 0) {
        // Reset to start of week and use a different time
        currentDay = 0;
        
        // Add 2 hours to the time for the next round
        defaultTime = TimeOfDay(
          hour: (defaultTime.hour + 2) % 24,
          minute: defaultTime.minute
        );
      }
    }
    
    return times;
  }

  /// Calculates evenly distributed times for monthly schedules
  List<DateTime> _calculateMonthlyScheduleTimes(
    int frequency, 
    String? startTime, 
    String? endTime
  ) {
    final now = DateTime.now();
    final List<DateTime> times = [];
    
    // Parse default time from start/end time params
    var defaultTime = _parseTimeOfDay(startTime) ?? TimeOfDay(hour: 9, minute: 0);
    
    // Get days in current month
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    
    // Calculate how many days to distribute the doses over
    int daysToUse = math.min(daysInMonth, frequency);
    
    // Calculate days between doses
    int interval = frequency <= daysInMonth 
        ? (daysInMonth / frequency).floor() 
        : 1;
    
    // Start from today or day 1 if today is past day 28
    int startDay = now.day;
    if (startDay > 28) startDay = 1;
    
    // Track the current day of month
    int currentDay = startDay;
    
    while (times.length < frequency) {
      // If we've gone past the end of the month, wrap to next month
      if (currentDay > daysInMonth) {
        currentDay = 1;
      }
      
      // Calculate date for this day
      DateTime dateToUse;
      if (currentDay >= now.day) {
        // This month
        dateToUse = DateTime(now.year, now.month, currentDay);
      } else {
        // Next month
        dateToUse = DateTime(now.year, now.month + 1, currentDay);
      }
      
      final hour = defaultTime.hour;
      final minute = defaultTime.minute;
      
      // Create DateTime for this day
      DateTime time = DateTime(
        dateToUse.year, 
        dateToUse.month, 
        dateToUse.day, 
        hour, 
        minute
      );
      
      // If it's today and the time has passed, skip
      if (dateToUse.day == now.day && 
          dateToUse.month == now.month && 
          dateToUse.year == now.year && 
          time.isBefore(now)) {
        currentDay += interval;
        continue;
      }
      
      times.add(time);
      
      // Move to next day based on interval
      currentDay += interval;
      
      // For frequencies greater than days in month
      if (frequency > daysInMonth && times.length % daysToUse == 0) {
        // Reset to start day and use a different time
        currentDay = startDay;
        
        // Add 2 hours to the time for the next round
        defaultTime = TimeOfDay(
          hour: (defaultTime.hour + 2) % 24,
          minute: defaultTime.minute
        );
      }
    }
    
    return times;
  }

  /// Helper method to parse a time string into TimeOfDay
  TimeOfDay? _parseTimeOfDay(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;
    
    final parts = timeString.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      
      if (hour != null && minute != null) {
        return TimeOfDay(hour: hour, minute: minute);
      }
    }
    
    return null;
  }
  
  /// Creates notification channel details depending on platform and user settings.
  Future<NotificationDetails> _buildNotificationDetails({
    required String title,
    required String body,
  }) async {
    // Android specific notification details
    final androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Medication Reminders',
      channelDescription: 'Notifications for medication reminders',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: _vibrationEnabled,
      playSound: _soundEnabled,
      vibrationPattern: _vibrationEnabled ? Int64List.fromList([0, 500, 200, 500]) : null, // Add vibration pattern
      icon: '@mipmap/ic_launcher',
      channelShowBadge: true,
      fullScreenIntent: true, // Makes notification appear even when screen is on
      category: AndroidNotificationCategory.alarm, // Treat as an alarm
      visibility: NotificationVisibility.public, 
      );
      
    // iOS specific notification details
    final iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: _soundEnabled,
      sound: _soundEnabled ? 'default' : null,
      interruptionLevel: InterruptionLevel.timeSensitive, // Make it more likely to show

    );
    
    return NotificationDetails(android: androidDetails, iOS: iOSDetails);
  }
  
  /// Cancels all notifications.
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) await initialize();
    
    try {
      await _localNotifications.cancelAll();
      // Clear our cache
      _scheduledNotificationsCache.clear();
      log('All notifications cancelled');
    } catch (e) {
      log('Error cancelling all notifications: $e');
    }
  }
  
  /// Enable or disable notifications globally.
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _saveSettings();
    
    if (!enabled) {
      // Cancel all existing notifications
      await cancelAllNotifications();
    }
    
    log('Notifications ${enabled ? 'enabled' : 'disabled'}');
  }
  
  /// Enable or disable notification sounds.
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    await _saveSettings();
    log('Notification sound ${enabled ? 'enabled' : 'disabled'}');
  }
  
  /// Enable or disable notification vibration.
  Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
    await _saveSettings();
    log('Notification vibration ${enabled ? 'enabled' : 'disabled'}');
  }
  
  /// Load notification settings from shared preferences.
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationsEnabled = prefs.getBool(_enabledKey) ?? true;
      _soundEnabled = prefs.getBool(_soundEnabledKey) ?? true;
      _vibrationEnabled = prefs.getBool(_vibrationEnabledKey) ?? true;
    } catch (e) {
      log('Error loading notification settings: $e');
    }
  }
  
  /// Save notification settings to shared preferences.
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, _notificationsEnabled);
      await prefs.setBool(_soundEnabledKey, _soundEnabled);
      await prefs.setBool(_vibrationEnabledKey, _vibrationEnabled);
    } catch (e) {
      log('Error saving notification settings: $e');
    }
  }

  /// Shows a test notification immediately to verify functionality.
  Future<void> showTestNotification() async {
    if (!_isInitialized) await initialize();
    if (!_notificationsEnabled) return;
    
    try {
      final notificationDetails = await _buildNotificationDetails(
        title: 'Test Notification',
        body: 'This is a test notification. If you see this, notifications are working!',
      );
      
      // Show notification immediately
      await _localNotifications.show(
        9999, // Use a unique ID
        'Test Notification',
        'This is a test notification. If you see this, notifications are working!',
        notificationDetails,
      );
      
      log('Test notification displayed');
    } catch (e) {
      log('Error showing test notification: $e');
    }
  }

  /// Gets the count of pending notifications
  Future<int> getPendingNotificationCount() async {
    if (!_isInitialized) await initialize();
    
    try {
      final pendingNotifications = await _localNotifications.pendingNotificationRequests();
      return pendingNotifications.length;
    } catch (e) {
      log('Error getting pending notification count: $e');
      return 0;
    }
  }

  /// Gets all pending notification requests with their payloads
  Future<List<PendingNotificationRequest>> getPendingNotificationRequests() async {
    if (!_isInitialized) await initialize();
    
    try {
      return await _localNotifications.pendingNotificationRequests();
    } catch (e) {
      log('Error getting pending notification requests: $e');
      return [];
    }
  }

  /// Gets all pending notification requests with complete information
  Future<List<Map<String, dynamic>>> getPendingNotificationsWithInfo() async {
    if (!_isInitialized) await initialize();
    
    try {
      final pendingRequests = await _localNotifications.pendingNotificationRequests();
      
      return pendingRequests.map((request) {
        final payload = request.payload?.split('|') ?? [];
        
        return {
          'id': request.id,
          'title': request.title ?? 'Medication Reminder',
          'body': request.body ?? '',
          'reminderId': payload.isNotEmpty ? payload[0] : '',
          'medicationId': payload.length > 1 ? payload[1] : '',
          'medicationName': payload.length > 2 ? payload[2] : 'Medication',
        };
      }).toList();
    } catch (e) {
      log('Error getting pending notifications with info: $e');
      return [];
    }
  }

  /// Add this method to get all cached notifications
  Future<List<Map<String, dynamic>>> getAllScheduledNotifications() async {
    if (!_isInitialized) await initialize();
    
    final List<Map<String, dynamic>> allNotifications = [];
    
    try {
      // First, get the actual pending notifications from the system
      final pendingRequests = await _localNotifications.pendingNotificationRequests();
      
      // Create a set of notification IDs that are actually pending
      final Set<int> pendingIds = pendingRequests.map((req) => req.id).toSet();
      
      // Flatten our cache and filter to only include notifications that are still pending
      // or scheduled for the future
      final now = DateTime.now().millisecondsSinceEpoch;
      
      for (final reminderNotifications in _scheduledNotificationsCache.values) {
        for (final notification in reminderNotifications) {
          // Only include if it's still pending (in the system) or scheduled for the future
          final scheduledTime = notification['scheduledTime'] as int;
          if (pendingIds.contains(notification['id']) || scheduledTime > now) {
            // Create a fake PendingNotificationRequest-like object
            allNotifications.add({
              'id': notification['id'],
              'title': 'Medication Reminder',
              'body': 'Time to take ${notification['medicationName']}',
              'payload': notification['payload'],
              'scheduledDateTime': DateTime.fromMillisecondsSinceEpoch(scheduledTime),
            });
          }
        }
      }
      
      // Sort by scheduled time
      allNotifications.sort((a, b) => 
        (a['scheduledDateTime'] as DateTime).compareTo(b['scheduledDateTime'] as DateTime)
      );
      
      return allNotifications;
    } catch (e) {
      log('Error getting all scheduled notifications: $e');
      return [];
    }
  }
}