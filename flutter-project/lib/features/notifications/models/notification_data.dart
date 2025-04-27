class NotificationData {
  final String reminderId;
  final String medicationId;
  final String medicationName;
  final String? payload;  
  final int? id;
  
  NotificationData({
    required this.reminderId,
    required this.medicationId,
    required this.medicationName,
    this.payload, 
    this.id,      
  });
}