/* 
    TO DO:
    - add content to IntroScreen widget (add to build method)
*/
import 'package:eyedrop/logic/onboarding/onboarding_service.dart';
import 'package:flutter/material.dart';

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
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Welcome to the App!", style: TextStyle(fontSize: 24)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    // Button is pressed when first-time user finishes with the onboarding screen.
                    // User can go to the home screen and their first time is marked as complete.
                    await OnboardingService.markFirstTimeComplete();
                    if(context.mounted) {
                      _directToHome(context);
                    }
                  },
                  child: const Text("Get Started"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _directToHome(BuildContext context) {
    Navigator.popAndPushNamed(context, '/home');
  }

}
