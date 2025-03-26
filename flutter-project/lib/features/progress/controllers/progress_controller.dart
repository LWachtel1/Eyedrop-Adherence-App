import 'dart:developer';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:eyedrop/features/progress/models/progress_entry.dart';
import 'package:eyedrop/features/progress/services/progress_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

/// Controller for managing medication adherence data and UI state
class ProgressController extends ChangeNotifier {
  final ProgressService _progressService = ProgressService();
  
  List<ProgressEntry> _entries = [];
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _scheduleTypeStats = {};
  bool _isLoading = false;
  String? _selectedMedicationId;
  String? _selectedReminderId;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _errorMessage;
  bool _hasError = false;
  bool _isActive = true;
  StreamSubscription<List<Map<String, dynamic>>>? _progressStreamSubscription;
  final BehaviorSubject<bool> _refreshTrigger = BehaviorSubject<bool>.seeded(false);
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  
  // Getters
  List<ProgressEntry> get entries => _entries;
  Map<String, dynamic> get stats => _stats;
  Map<String, dynamic> get scheduleTypeStats => _scheduleTypeStats;
  bool get isLoading => _isLoading;
  String? get selectedMedicationId => _selectedMedicationId;
  String? get selectedReminderId => _selectedReminderId;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String? get errorMessage => _errorMessage;
  bool get hasError => _hasError;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreData => _hasMoreData;
  Stream<bool> get refreshStream => _refreshTrigger.stream;
  bool get isActive => _isActive;
  
  /// Loads progress data with current filters
  Future<void> loadProgressData({bool reset = true, int pageSize = 50}) async {
    if (!_isActive) return;
    
    if (reset) {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      _entries = [];
      notifyListeners();
    } else {
      // Only update loading state for pagination
      _isLoadingMore = true;
      notifyListeners();
    }
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // User not authenticated 
        _entries = [];
        _stats = {};
        _scheduleTypeStats = {};
        _errorMessage = "You must be signed in to view progress data";
        _hasError = true;
        _isLoading = false;
        _isLoadingMore = false;
        notifyListeners();
        return;
      }


      // Get the next page of entries
      final lastEntry = _entries.isNotEmpty ? _entries.last : null;
      
      final newEntries = await _progressService.getProgressEntries(
        userId: user.uid,
        medicationId: _selectedMedicationId,
        reminderId: _selectedReminderId,
        startDate: _startDate,
        endDate: _endDate,
        pageSize: pageSize,
        lastDocument: reset ? null : lastEntry?.id,
      );
      
      // If refreshing, replace entries; if paginating, append entries
      if (reset) {
        _entries = newEntries;
      } else {
        _entries.addAll(newEntries);
      }
      
      _hasMoreData = newEntries.length >= pageSize;
      _stats = _progressService.calculateAdherenceStats(_entries);
      _scheduleTypeStats = _progressService.calculateScheduleTypeStats(_entries);
      
    } catch (e) {
      log('Error loading progress data: $e');
      _errorMessage = "Failed to load progress data: ${e.toString().split(':').last}";
      _hasError = true;
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
    if (_isActive) {
          notifyListeners();
    }
    }
  }
  
  /// Loads progress data for a specific medication
  Future<void> loadMedicationProgress(String medicationId) async {
    _selectedMedicationId = medicationId;
    _selectedReminderId = null;
    await loadProgressData();
  }
  
  /// Loads progress data for a specific reminder
  Future<void> loadReminderProgress(String reminderId) async {
    _selectedReminderId = reminderId;
    _selectedMedicationId = null;
    await loadProgressData();
  }
  
  /// Set date range filter
  Future<void> setDateRange(DateTime? start, DateTime? end) async {
    // Validate date range
    if (start != null && end != null) {
      if (end.isBefore(start)) {
        _errorMessage = "End date cannot be before start date";
        _hasError = true;
        notifyListeners();
        return;
      }
      
      // Ensure the date range isn't too large (e.g., max 1 year)
      final difference = end.difference(start).inDays;
      if (difference > 365) {
        _errorMessage = "Date range cannot exceed 1 year";
        _hasError = true;
        notifyListeners();
        return;
      }
    }
    
    _startDate = start;
    _endDate = end;
    _hasError = false;
    _errorMessage = null;
    await loadProgressData();
  }
  
  /// Reset all filters
  Future<void> resetFilters() async {
    _selectedMedicationId = null;
    _selectedReminderId = null;
    _startDate = null;
    _endDate = null;
    await loadProgressData();
  }
  
  /// Format a duration in milliseconds to a readable string
  String formatResponseDelay(int? milliseconds) {
    if (milliseconds == null) return 'N/A';
    
    if (milliseconds < 1000) {
      return '$milliseconds ms';
    } else if (milliseconds < 60000) {
      return '${(milliseconds / 1000).toStringAsFixed(1)} seconds';
    } else {
      return '${(milliseconds / 60000).toStringAsFixed(1)} minutes';
    }
  }
  
  // Add to ProgressController class
Map<String, List<ProgressEntry>> getEntriesByDay() {
  final entriesByDay = <String, List<ProgressEntry>>{};
  
  for (final entry in _entries) {
    if (!entriesByDay.containsKey(entry.dayString)) {
      entriesByDay[entry.dayString] = [];
    }
    entriesByDay[entry.dayString]!.add(entry);
  }
  
  // Sort entries by time
  entriesByDay.forEach((day, entries) {
    entries.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
  });
  
  // Sort days by date (newest first)
  final sortedKeys = entriesByDay.keys.toList()
    ..sort((a, b) => b.compareTo(a));
  
  return {
    for (var key in sortedKeys) key: entriesByDay[key]!
  };
}
  
  /// Format a day string (YYYY-MM-DD) to a readable format
  String formatDayString(String dayString) {
    try {
      final date = DateFormat('yyyy-MM-dd').parse(dayString);
      return DateFormat.yMMMd().format(date);
    } catch (e) {
      return dayString;
    }
  }

  // Add a method to clear errors
  void clearErrors() {
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
  }

  // Add to constructor or create an initialization method
  void initializeRealTimeUpdates() {
    if (!_isActive) return;
    
    // Cancel any existing subscription
    _progressStreamSubscription?.cancel();
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    // Check if the stream is already closed
    if (_refreshTrigger.isClosed) return;
    
    // Listen for changes to progress entries
    _progressStreamSubscription = _progressService.getProgressEntriesStream(user.uid)
      .listen((_) {
        if (!_isActive || _refreshTrigger.isClosed) return;
        
        log('Progress entries changed, refreshing data');
        // Trigger a refresh when data changes externally
        _refreshTrigger.add(true);
      });
  }

  // Add a clean-up method
  @override
  void dispose() {
    _isActive = false;
    _cleanupResources();
    super.dispose();
  }

  // Add method to load more data (for pagination)
  Future<void> loadMoreData({int pageSize = 50}) async {
    if (_isLoading || _isLoadingMore || !_hasMoreData) return;
    
    await loadProgressData(reset: false, pageSize: pageSize);
  }

  // Add this method to safely clean up when leaving a screen
  void cleanupScreenResources() {
    _progressStreamSubscription?.cancel();
    _progressStreamSubscription = null;
  }

  // Split resource cleanup from complete disposal
  void _cleanupResources() {
    _progressStreamSubscription?.cancel();
    _progressStreamSubscription = null;
    
    // Close stream safely
    if (!_refreshTrigger.isClosed) {
      _refreshTrigger.close();
    }
  }

  // Reset controller for reuse
  void resetController() {
    if (_isActive) return; // Don't reset if still active
    
    _isActive = true;
    _isLoading = false;
    _hasError = false;
    _errorMessage = null;
    _isLoadingMore = false;
    _hasMoreData = true;
  }

  /// Deletes all progress entries for a specific reminder
  Future<void> deleteProgressForReminder(String reminderId) async {
    if (!_isActive) return;
    
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User must be logged in to delete progress data");
      }
      
      // Delete all entries for this reminder
      await _progressService.deleteProgressEntriesForReminder(
        userId: user.uid,
        reminderId: reminderId,
      );
      
      // Refresh data
      await loadProgressData();
    } catch (e) {
      log('Error deleting progress data: $e');
      _errorMessage = "Failed to delete progress data: ${e.toString().split(':').last}";
      _hasError = true;
      _isLoading = false;
      notifyListeners();
    }
  }
}