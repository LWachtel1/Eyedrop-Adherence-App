import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmButtonText;
  final String cancelButtonText;
  final Color confirmButtonColor;
  final VoidCallback onConfirm;
  
  const ConfirmationDialog({
    Key? key,
    required this.title,
    required this.message,
    this.confirmButtonText = "Delete",
    this.cancelButtonText = "Cancel",
    this.confirmButtonColor = Colors.red,
    required this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        message,
        style: TextStyle(fontSize: 14.sp),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            cancelButtonText,
            style: TextStyle(fontSize: 12.sp),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: TextButton.styleFrom(
            foregroundColor: confirmButtonColor,
          ),
          child: Text(
            confirmButtonText,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}