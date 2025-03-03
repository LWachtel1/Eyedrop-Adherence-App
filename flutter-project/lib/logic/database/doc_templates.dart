import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

///Returns user document template
/*
Map<String, dynamic> createUserDoc(String userId, String firstName, String lastName, String email,
  DateTime accountCreatedAt, bool signedIn, bool calendarLinked, bool locationEnabled) {
  return {
    "_id": userId,
    "firstName": firstName,
	  "lastName" : lastName,
	  "email" : email,
	  "accountCreatedAt" : accountCreatedAt,
	  "signedIn": signedIn,
	  "calendarLinked": calendarLinked,
	  "locationEnabled": locationEnabled,
    
  };
}*/

User? getCurrentUserDetails() {
  User? user = FirebaseAuth.instance.currentUser;
  return user;
}

Map<String, dynamic> createUserDocTemplate() {
  User? user = getCurrentUserDetails();
  if (user == null) {
    return {};
  } else {
    return {
      "_id": 'usr_${user.uid}',
      "email": user.email,
      "accountCreatedAt": user.metadata.creationTime,
      "lastSignedIn": user.metadata.lastSignInTime,
    };
  }
}

///Returns condition document template
Map<String, dynamic> createConditionDoc(
    String conditionId, String conditionName, List<String> medicationIds) {
  return {
    "_id": conditionId,
    "conditionName": conditionName,
    "medicationIds": medicationIds
  };
}

///Returns medication document template
Map<String, dynamic> createMedDoc(
    String medicationID,
    String medicationName,
    String recDurationUnits,
    double recDurationLength,
    String recSchedule,
    int recFrequency,
    String recDoseUnits,
    double recDoseQuantity,
    String medType,
    String recApplicationSite,
    List<String> conditionIds) {
  return {
    "medicationID": medicationID,
    "medicationName": medicationName,
    "recDurationUnits": recDurationUnits,
    "recDurationLength": recDurationLength,
    "recSchedule": recSchedule,
    "recFrequency": recFrequency,
    "recDoseUnits": recDoseUnits,
    "recDoseQuantity": recDoseQuantity,
    "recMedDelivery": {
      "medType": medType,
      "recApplicationSite": recApplicationSite
    },
    "conditionIDs":
        conditionIds, /**
	  potentially redundant as relationship already defined in Conditions**/
  };
}

///Returns user eye medication document template
Map<String, dynamic> createUserEyeMedDoc(
    String userEyeMedicationID,
    String medicationID,
    DateTime datePrescribed,
    String durationUnits,
    double durationLength,
    String schedule,
    int frequency,
    String doseUnits,
    double doseQuantity,
    String applicationSite,
    List<TimeOfDay> medTimings,
    bool reminderSet,
    String userID) {
  return {
    "_id": userEyeMedicationID, //primary key
    "medicationID": medicationID, //foreign key
    "datePrescribed":
        datePrescribed, //if user does not know exact day/month, need alternative
    "durationUnits": durationUnits,
    "durationLength": durationLength,
    "scheduleType": schedule, //daily, weekly, as needed, etc.
    "frequency": frequency,
    "doseUnits": doseUnits,
    "doseQuantity": doseQuantity,
    "applicationSite": applicationSite,
    "medTimings": medTimings, //optional
    /**
	  for purposes of scheduling reminders around medications that do not have reminders 
	  set but user still takes them
	  **/
    "reminderSet": reminderSet,
    "userID": userID //foreign key
  };
}

///Returns user non eye medication document template
Map<String, dynamic> createUserNonEyeMedDoc(
    String userNonEyeMedicationID,
    String medicationID,
    DateTime datePrescribed,
    String durationUnits,
    double durationLength,
    String schedule,
    int frequency,
    String doseUnits,
    double doseQuantity,
    String applicationSite,
    List<TimeOfDay> medTimings,
    String userID) {
  return {
    "_id": userNonEyeMedicationID, //primary key
    "medicationID": medicationID, //foreign key
    "datePrescribed":
        datePrescribed, //if user does not know exact day/month, need alternative
    "durationUnits": durationUnits,
    "durationLength": durationLength,
    "scheduleType": schedule, //daily, weekly, as needed, etc.
    "frequency": frequency,
    "doseUnits": doseUnits,
    "doseQuantity": doseQuantity,
    "medTimings": medTimings, //optional
    /**
	  for purposes of scheduling reminders around medications that do not have reminders 
	  set but user still takes them
	  **/
    "userID": userID //foreign key
  };
}

///Returns user med reminder document template
Map<String, dynamic> createUserMedReminderDoc(
    String medReminderId,
    String userEyeMedicationID,
    String medicationID,
    DateTime remStart,
    String remDurationUnits,
    double remDurationLength,
    bool smartScheduled,
    String userID) {
  return {
    "_id": medReminderId, //primary key
    "userEyeMedicationID": userEyeMedicationID, //foreign key
    "medicationID": medicationID, //foreign key
    "remStart": remStart,
    "remDurationUnits": remDurationUnits,
    "remDurationLength": 1,
    "smartScheduled": smartScheduled,

    //!!!INSERT FIELDS DESCRIBED IN COMMENT BELOW!!!

    /**uses userEyeMedicationID to get the following info from user_medication document:
	  schedule type (daily/weekly etc.)
	  frequency
	  dose units
	  dose quantity
	  application site i.e., left eye, right eye, both eyes
	  medTimings (if smartScheduled is false)
	  **/

    "userID": userID //foreign key
  };
}
