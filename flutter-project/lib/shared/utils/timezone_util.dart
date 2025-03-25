import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Utility class for timezone operations
class TimezoneUtil {
  static bool _initialized = false;
  
  /// Initialize timezone data
  static void initialize() {
    if (!_initialized) {
      tz_data.initializeTimeZones();
      _initialized = true;
    }
  }
  
  /// Convert DateTime to a local timezone DateTime
  static DateTime toLocalTime(DateTime dateTime) {
    initialize();
    
    // If already in local timezone
    if (dateTime.isUtc) {
      return dateTime.toLocal();
    } else {
      return dateTime;
    }
  }
  
  /// Convert DateTime to UTC
  static DateTime toUtc(DateTime dateTime) {
    // If already in UTC
    if (dateTime.isUtc) {
      return dateTime;
    } else {
      return dateTime.toUtc();
    }
  }
  
  /// Get the start of day for a specific date in local timezone
  static DateTime startOfDay(DateTime dateTime) {
    final localTime = toLocalTime(dateTime);
    return DateTime(localTime.year, localTime.month, localTime.day, 0, 0, 0);
  }
  
  /// Get the end of day for a specific date in local timezone
  static DateTime endOfDay(DateTime dateTime) {
    final localTime = toLocalTime(dateTime);
    return DateTime(localTime.year, localTime.month, localTime.day, 23, 59, 59, 999);
  }
  
  /// Format a day string (YYYY-MM-DD) based on the user's locale and timezone
  static String formatDayString(String dayString, {bool useRelativeText = true}) {
    try {
      final date = DateFormat('yyyy-MM-dd').parse(dayString);
      final localDate = toLocalTime(date);
      
      if (useRelativeText) {
        final now = DateTime.now();
        final today = startOfDay(now);
        final yesterday = today.subtract(const Duration(days: 1));
        
        if (startOfDay(localDate).isAtSameMomentAs(today)) {
          return "Today";
        } else if (startOfDay(localDate).isAtSameMomentAs(yesterday)) {
          return "Yesterday";
        }
      }
      
      return DateFormat.yMMMMd().format(localDate);
    } catch (e) {
      return dayString;
    }
  }
  
  /// Generate a consistent day string for a DateTime
  static String generateDayString(DateTime dateTime) {
    final localTime = toLocalTime(dateTime);
    return DateFormat('yyyy-MM-dd').format(localTime);
  }
  
  /// Get the hour in the local timezone
  static int getLocalHour(DateTime dateTime) {
    final localTime = toLocalTime(dateTime);
    return localTime.hour;
  }
}