import 'package:flutter/material.dart';

/// A confirmation dialog for deleting a medication.
///
/// This dialog prompts the user to confirm the deletion of a medication. 
/// It provides options to either cancel the action or proceed with deletion.
///
/// Parameters:
/// - `medicationName`: The name of the medication to be deleted (displayed in the dialog).
/// - `onConfirm`: A callback function executed when the user confirms the deletion.
/// - `isReminder`: Whether this is deleting a reminder (default: false).
///
/// Behavior:
/// - If the user presses **Cancel**, the dialog is dismissed without any action.
/// - If the user presses **Delete**, the dialog closes and `onConfirm` is executed.
class DeleteConfirmationDialog extends StatelessWidget {
  final String medicationName;
  final VoidCallback onConfirm;
  final bool isReminder;

  const DeleteConfirmationDialog({
    required this.medicationName,
    required this.onConfirm,
    this.isReminder = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final title = isReminder 
        ? "Delete Reminder?" 
        : "Delete Medication?";
    
    final content = isReminder
        ? "Are you sure you want to delete the reminder for $medicationName? All progress history for this reminder will also be permanently deleted. This action cannot be undone."
        : "Are you sure you want to delete $medicationName? Any reminders associated with this medication and their progress history will also be deleted. This action cannot be undone.";
    
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          child: Text("Delete"),
        ),
      ],
    );
  }
}

