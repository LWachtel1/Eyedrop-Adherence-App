class NotificationData {
  final String reminderId;
  final String medicationId;
  final String medicationName;
  final String? payload;  // Add this field
  
  NotificationData({
    required this.reminderId,
    required this.medicationId,
    required this.medicationName,
    this.payload,  // Add this parameter
  });
}