import 'package:eyedrop/features/onboarding/services/gdpr_consent_service.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// A screen that displays GDPR consent information and requires user consent before proceeding.
class GDPRConsentScreen extends StatefulWidget {
  static const String id = "/gdpr-consent";
  
  const GDPRConsentScreen({Key? key}) : super(key: key);

  @override
  _GDPRConsentScreenState createState() => _GDPRConsentScreenState();
}

class _GDPRConsentScreenState extends State<GDPRConsentScreen> {
  bool _hasGivenConsent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(5.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Text(
                  "Data Protection & Consent",
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 3.h),

              // Privacy Notice
              Text(
                "This app is part of a University of Birmingham research project. It helps users track their medication, receive reminders, and monitor adherence. As part of its function, the app collects and processes personal data.",
                style: TextStyle(
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                "We take your privacy seriously. Your data is stored securely and is only used for the purposes you've consented to.",
                style: TextStyle(fontSize: 14.sp),
              ),
              SizedBox(height: 2.h),

              // Data Collection
              Text(
                "Data We Collect",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 1.h),
              _buildDataPoint("Email address for account creation"),
              _buildDataPoint("Medication information and schedules"),
              _buildDataPoint("Adherence notification interactions"),
              _buildDataPoint("Reviews of medications you submit"),

              SizedBox(height: 2.h),

              // Data Usage
              Text(
                "How We Use Your Data",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 1.h),
              _buildDataPoint("Send medication reminders"),
              _buildDataPoint("Track your medication adherence"),
              _buildDataPoint("Analyse adherence patterns and show progress over time"),
              _buildDataPoint("Enable feedback features such as medication reviews"),
              SizedBox(height: 2.h),

              Text(
                "Legal Basis for Processing",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 1.h),
              _buildDataPoint("Your data is processed with your explicit consent in accordance with:- Article 6(1)(a) and Article 9(2)(a) of the UK General Data Protection Regulation (UK GDPR) - The Data Protection Act 2018"),
              SizedBox(height: 2.h),

              Text(
                "Data Security and Storage",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 1.h),
              _buildDataPoint("All data is encrypted in transit and at rest"),
              _buildDataPoint("Your data is stored in your private Firebase account and protected by secure authentication"),
              _buildDataPoint("Access is restricted by strict Firebase security rules"),
              _buildDataPoint("No data is shared with third parties"),
              SizedBox(height: 2.h),

              Text(
                "Your Rights",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 1.h),
              _buildDataPoint("Access, edit, or delete your data"),
              _buildDataPoint("Withdraw your consent at any time"),
              _buildDataPoint("Request the deletion of your account and all associated records"),
              SizedBox(height: 2.h),

              Text(
                "Data Retention",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 1.h),
              _buildDataPoint("Your data will be stored only as long as your account remains active. You can delete your account at any time, and all data will be permanently erased."),
              SizedBox(height: 2.h),

              // Consent Checkbox
              CheckboxListTile(
                value: _hasGivenConsent,
                onChanged: (bool? value) {
                  setState(() {
                    _hasGivenConsent = value ?? false;
                  });
                },
                title: Text(
                  "By ticking the box, you confirm that you are 16 years or older, have read and understood how your data will be used, and give explicit consent for us to process the aforementioned personal and health-related data as described",
                  style: TextStyle(fontSize: 14.sp),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              SizedBox(height: 2.h),

              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _hasGivenConsent
                      ? () async {
                          try {
                            await GDPRConsentService.markConsentGiven();
                            if (context.mounted) {
                              Navigator.pushReplacementNamed(context, '/home');
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Error saving consent. Please try again."),
                                ),
                              );
                            }
                          }
                        }
                      : null,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 1.h),
                    child: Text(
                      "Continue",
                      style: TextStyle(fontSize: 16.sp),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataPoint(String text) {
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
} 