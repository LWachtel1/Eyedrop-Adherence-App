/* 
    TO DO:
    - handle potential unknown route error
*/

import 'dart:developer';

import 'package:eyedrop/features/auth/controllers/auth_checker.dart';
import 'package:eyedrop/features/progress/screens/progress_overview_screen.dart';
import 'package:eyedrop/features/reminders/services/reminder_expiration_service.dart';
import 'package:eyedrop/features/schedule/screens/schedule_screen.dart';
import 'package:eyedrop/shared/services/firestore_service.dart';
import 'package:eyedrop/features/auth/screens/auth_gate.dart';
import 'package:eyedrop/features/medications/controllers/medication_form_controller.dart';
import 'package:eyedrop/features/medications/services/medication_service.dart';
import 'package:eyedrop/features/onboarding/screens/onetime_intro_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import 'core/firebase_options.dart';
import 'package:eyedrop/features/reminders/controllers/reminder_form_controller.dart';
import 'package:eyedrop/features/reminders/services/reminder_service.dart';
import 'package:eyedrop/features/reminders/screens/reminders_screen.dart';
import 'package:eyedrop/features/medications/screens/medications_screen.dart';
import 'package:eyedrop/features/notifications/services/notification_service.dart';
import 'package:eyedrop/features/notifications/controllers/notification_controller.dart';
import 'package:eyedrop/features/settings/screens/settings_screen.dart';
import 'package:eyedrop/features/notifications/services/notification_verification_service.dart';
import 'package:eyedrop/features/progress/controllers/progress_controller.dart';
import 'features/education/screens/education_screen.dart';

// Add these imports at the top of your file
import 'package:eyedrop/features/schedule/screens/daily_schedule_screen.dart';
import 'package:eyedrop/features/schedule/screens/weekly_schedule_screen.dart';
import 'package:eyedrop/features/schedule/screens/monthly_schedule_screen.dart';

// Global navigator key for notification navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Application Entry Point.
/// 
/// This function initializes Firebase and runs the application.
/// 
/// - Ensures Firebase services are available before launching the app.
/// - Uses `Provider` for dependency injection.
/// - Sets up authentication state management.
/// - Handles database services using Firestore.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialises Firebase before running app to ensure its services are available.
    // Uses Firebase config settings for app's specific platform as defined in firebase_options.dart.    
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    log("About to initialize Firebase");
  } catch (e, stackTrace) {
    log("Firebase failed to initialize: $e", stackTrace: stackTrace);
    return; // Prevents app from running if Firebase fails.
  }

  log("Firebase initialized successfully");
  log("Starting app with providers");

  //Registers providers globally, so all widgets can check use their functionalities.
  runApp(ChangeNotifierProvider(

    create: (context) => AuthChecker(),

    child: MultiProvider( // Groups Providers together to be used by the app.
      providers: [
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        ProxyProvider<FirestoreService, MedicationService>(
              update: (_, firestoreService, __) => MedicationService(firestoreService),
            ),    
            // ProxyProvider is a provider that builds a value based on other providers.    
        ChangeNotifierProvider(create: (context) => MedicationFormController(medicationService: context.read<MedicationService>())),
        Provider<ReminderService>(
          create: (context) => ReminderService(
            Provider.of<FirestoreService>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider<ReminderFormController>(
          create: (context) => ReminderFormController(
            reminderService: Provider.of<ReminderService>(context, listen: false),
          ),
        ),
        
        // Notification service provider.
        Provider<NotificationService>(
          create: (_) => NotificationService(),
        ),

        // Add this to your providers list in the MultiProvider widget
        Provider<ReminderExpirationService>(
          create: (context) => ReminderExpirationService(
            Provider.of<ReminderService>(context, listen: false),
          ),
        ),

        // And update the NotificationController provider:
        ChangeNotifierProvider<NotificationController>(
          create: (context) => NotificationController(
            notificationService: Provider.of<NotificationService>(context, listen: false),
            reminderService: Provider.of<ReminderService>(context, listen: false),
            expirationService: Provider.of<ReminderExpirationService>(context, listen: false),
          ),
        ),
        // NotificationController initializes when the app starts, ensuring notifications are scheduled right away
        // as it calls the notification service to initialize and schedule all reminders.

        // Add to your providers list in the MultiProvider widget
        Provider<NotificationVerificationService>(
          create: (context) => NotificationVerificationService(
            notificationController: Provider.of<NotificationController>(context, listen: false),
            notificationService: Provider.of<NotificationService>(context, listen: false),
            reminderService: Provider.of<ReminderService>(context, listen: false),
          ),
        ),
        
        // Add this provider
        ChangeNotifierProvider<ProgressController>(
          create: (context) => ProgressController(),
        ),
      ],
      child: Sizer( // Wraps the app in Sizer.
          builder: (context, orientation, deviceType) {
            return const MyApp();
          }),
    ),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  
  /// Builds Root Application Widget.
  /// 
  /// This widget is responsible for:
  /// - Navigation routes to different screens.
  /// - UI setup.
  /// - Authentication handling.
  /// 
  /// Parameters:
  /// - `context`: A reference to the widget's location in the widget tree.
  ///
  /// Returns:
  /// - The route-associated widget.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // Add navigator key for notification navigation
      
      //The initial route is the first-time user welcome screen.
      initialRoute: IntroScreen.id,

      routes: <String, WidgetBuilder>{
        IntroScreen.id: (BuildContext context) => IntroScreen(),
        '/home': (BuildContext context) => AuthGate(),
        RemindersScreen.id: (BuildContext context) => RemindersScreen(),
        MedicationsScreen.id: (BuildContext context) => MedicationsScreen(),
        SettingsScreen.id: (BuildContext context) => SettingsScreen(),
        ProgressOverviewScreen.id: (BuildContext context) => ProgressOverviewScreen(),
        ScheduleScreen.id: (BuildContext context) => ScheduleScreen(),
        // Add the new routes:
        DailyScheduleScreen.id: (BuildContext context) => DailyScheduleScreen(),
        WeeklyScheduleScreen.id: (BuildContext context) => WeeklyScheduleScreen(),
        MonthlyScheduleScreen.id: (BuildContext context) => MonthlyScheduleScreen(),
        EducationScreen.id: (BuildContext context) => EducationScreen(),
      },
      builder: (context, child) {
        return Stack(
          children: [
            // The app's actual content.
            child ?? const Center(child: Text("Something went wrong!")),
          ],
        );
      },
    );
  }
}
