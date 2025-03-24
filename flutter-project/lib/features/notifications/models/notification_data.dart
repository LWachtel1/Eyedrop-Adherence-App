/// Data model for notification payloads.
class NotificationData {
  final String reminderId;
  final String medicationId;
  final String medicationName;
  
  NotificationData({
    required this.reminderId,
    required this.medicationId,
    required this.medicationName,
  });
}