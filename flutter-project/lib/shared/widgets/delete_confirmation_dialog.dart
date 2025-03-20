import 'package:flutter/material.dart';

/// A confirmation dialog for deleting a medication.
///
/// This dialog prompts the user to confirm the deletion of a medication. 
/// It provides options to either cancel the action or proceed with deletion.
///
/// Parameters:
/// - `medicationName`: The name of the medication to be deleted (displayed in the dialog).
/// - `onConfirm`: A callback function executed when the user confirms the deletion.
///
/// Behavior:
/// - If the user presses **Cancel**, the dialog is dismissed without any action.
/// - If the user presses **Delete**, the dialog closes and `onConfirm` is executed.
class DeleteConfirmationDialog extends StatelessWidget {
  final String medicationName;
  final VoidCallback onConfirm;

  const DeleteConfirmationDialog({
    required this.medicationName,
    required this.onConfirm,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Delete Medication?"),
      content: Text("Are you sure you want to delete $medicationName?"),
      actions: [
        // Cancel Button - Closes the dialog without any action
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),

        // Delete Button - Executes onConfirm callback safely
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            try {
              onConfirm();
            } catch (e) {
              debugPrint("Error in onConfirm callback: $e");
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Failed to delete medication.")),
              );
            }
          },
          child: const Text("Delete", style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}

