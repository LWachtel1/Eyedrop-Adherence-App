import 'package:flutter/material.dart';

/// Safely navigates to a new screen.
/// 
/// - Closes any open popups or drawers before navigating.
/// - Ensures `context.mounted` before calling `Navigator.push()`.
void safeNavigate(BuildContext context, Widget destinationScreen) {
  if (!context.mounted) return; // Prevents navigation if widget is unmounted

  // Close any open popups, dialogs, or drawers first
  Navigator.popUntil(context, (route) => route.isFirst);

  // Uses Future.microtask() to process navigation when safe
  // as it schedules a microtask to run asap after the current synchronous code  completes.
  Future.microtask(() {
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => destinationScreen),
      );
    }
  });
}