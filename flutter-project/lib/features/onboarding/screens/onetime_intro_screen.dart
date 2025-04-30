/* 
    TO DO:
    - add content to IntroScreen widget (add to build method)
    - consider change this widget back to stateful widget as the previous implementation did not 
    have a slower loading time like this one does
    - potential risk of multiple rebuilds and therefore multiple navigations when using futurebuilder
*/
import 'dart:developer';
import 'package:eyedrop/features/onboarding/services/onboarding_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:sizer/sizer.dart';

/// A page that introduces a first-time user to the application.
///
/// If it is the user's first time, the welcome screen is displayed.
/// If the user has opened the app before, they are redirected to the home screen.
class IntroScreen extends StatelessWidget {
  static const String id = "/intro";
  const IntroScreen({super.key});


  /// Displays the introductory onboarding screen for first-time users and redirects established users to the home screen.
  @override
  Widget build(BuildContext context) {

    // `FutureBuilder` builds the widget based on its latest interaction with a snapshot of a future.
    // A future is an asyncrhonous operation. 
    // In this case, the future is the function checking whether the user is a first-time user or not.
    return FutureBuilder<bool>(
      future: OnboardingService.isFirstTime(),
      // The `builder` callback is executed whenever the future completes. 
      // `snapshot` stores the result of the future.
      builder: (context, snapshot) {

        // A loading screen is displayed until OnboardingService.isFirstTime() finishes.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        //If the OnboardingService throws an error
        if (snapshot.hasError) {
          return Scaffold(
          body: Center(child: Text("Something went wrong. Please try again.")),
          );
        }


        final isFirstTime = snapshot.data ?? true;
        
        // Directs established user to home screen.
        /*
        if (!isFirstTime) {
            //addPostFrameCallback ensures the UI fully finishes building before we navigate.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _directToHome(context);
            });

            // Prevents old screen from displaying while the app is navigating to the home screen.
            return const SizedBox.shrink();
        }*/

        // Directs established user to home screen.
        if (!isFirstTime) {
          //Ensures that navigation happens only after the current UI frame has been completely built.
          Future.microtask((){
              if (context.mounted) { 
                _directToHome(context);
              }
          });

          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        //If the user is a first-time user, they are 
        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(5.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  Center(
                    child: Text(
                      "Welcome to EyeDrop!",
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),

                  // App Purpose Section
                  Text(
                    "Your Eye Medication Companion",
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    "EyeDrop helps you manage your eye medications effectively by:",
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  SizedBox(height: 1.h),
                  _buildFeaturePoint("Setting up medication reminders"),
                  _buildFeaturePoint("Tracking your medication adherence"),
                  _buildFeaturePoint("Managing your medication schedule"),
                  _buildFeaturePoint("Providing educational resources"),
                  _buildFeaturePoint("Sharing and reading medication reviews"),
                  SizedBox(height: 2.h),

                  // Navigation Guide Section
                  Text(
                    "How to Navigate",
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  _buildNavigationPoint(
                    "Menu Button",
                    "Tap the menu icon in the bottom left to access all features",
                    Icons.menu,
                  ),
                  _buildNavigationPoint(
                    "Add Button",
                    "Use the + icon in the top bar to add new medications or reminders",
                    Icons.add_circle_outline,
                  ),
                  _buildNavigationPoint(
                    "Account",
                    "Access your profile via the person icon in the bottom right",
                    Icons.person_outline,
                  ),
                  _buildNavigationPoint(
                    "Settings",
                    "Access settings, including notification settings, via the settings icon in the top bar",
                    Icons.settings,
                  ),
                  
                  SizedBox(height: 3.h),

                  // Get Started Button
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await OnboardingService.markFirstTimeComplete();
                        } catch (e) {
                          log("Error marking onboarding as complete: $e");
                        }
                        if (context.mounted) {
                          _directToHome(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 1.5.h),
                        textStyle: TextStyle(fontSize: 16.sp),
                      ),
                      child: const Text("Get Started"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeaturePoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 16.sp, color: Colors.green),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationPoint(String title, String description, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16.sp, color: Colors.blue[700]),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _directToHome(BuildContext context) {
    Navigator.popAndPushNamed(context, '/home');
  }

}
