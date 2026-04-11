import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @preferencesSection.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferencesSection;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageSubtitle;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get notificationsEnabled;

  /// No description provided for @notificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get notificationsDisabled;

  /// No description provided for @supportSection.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get supportSection;

  /// No description provided for @supportPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Technical Support'**
  String get supportPhoneTitle;

  /// No description provided for @supportCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Service'**
  String get supportCustomerTitle;

  /// No description provided for @supportWhatsappTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact us on WhatsApp'**
  String get supportWhatsappTitle;

  /// No description provided for @supportWhatsappSubtitle.
  ///
  /// In en, this message translates to:
  /// **'For inquiries and complaints'**
  String get supportWhatsappSubtitle;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get aboutSection;

  /// No description provided for @appVersionTitle.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersionTitle;

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyTitle;

  /// No description provided for @privacyPolicySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read our policy'**
  String get privacyPolicySubtitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navAppointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get navAppointments;

  /// No description provided for @navMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get navMessages;

  /// No description provided for @navPatients.
  ///
  /// In en, this message translates to:
  /// **'Patients'**
  String get navPatients;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @emergencyDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Request!'**
  String get emergencyDialogTitle;

  /// No description provided for @emergencyDialogPatient.
  ///
  /// In en, this message translates to:
  /// **'Patient: {name}'**
  String emergencyDialogPatient(String name);

  /// No description provided for @emergencyDialogDetails.
  ///
  /// In en, this message translates to:
  /// **'Details: {desc}'**
  String emergencyDialogDetails(String desc);

  /// No description provided for @emergencyDialogReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get emergencyDialogReject;

  /// No description provided for @emergencyDialogAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get emergencyDialogAccept;

  /// No description provided for @dashGreetingM.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get dashGreetingM;

  /// No description provided for @dashGreetingE.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get dashGreetingE;

  /// No description provided for @dashGreetingN.
  ///
  /// In en, this message translates to:
  /// **'Good Night'**
  String get dashGreetingN;

  /// No description provided for @dashGreetingMsg.
  ///
  /// In en, this message translates to:
  /// **'{greeting} 👋'**
  String dashGreetingMsg(String greeting);

  /// No description provided for @dashDrName.
  ///
  /// In en, this message translates to:
  /// **'Doctor {name}'**
  String dashDrName(String name);

  /// No description provided for @dashOnline.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get dashOnline;

  /// No description provided for @dashOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get dashOffline;

  /// No description provided for @dashScheduleBtn.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get dashScheduleBtn;

  /// No description provided for @dashStatsPatients.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Patients'**
  String get dashStatsPatients;

  /// No description provided for @dashStatsPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get dashStatsPending;

  /// No description provided for @dashStatsUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get dashStatsUpcoming;

  /// No description provided for @dashStatsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get dashStatsTotal;

  /// No description provided for @dashOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get dashOverview;

  /// No description provided for @dashTodayAppointments.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Appointments'**
  String get dashTodayAppointments;

  /// No description provided for @dashTodayAndNewAppointments.
  ///
  /// In en, this message translates to:
  /// **'Today & New Bookings'**
  String get dashTodayAndNewAppointments;

  /// No description provided for @dashViewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get dashViewAll;

  /// No description provided for @dashNoConnectionTitle.
  ///
  /// In en, this message translates to:
  /// **'No Connection'**
  String get dashNoConnectionTitle;

  /// No description provided for @dashNoConnectionSub.
  ///
  /// In en, this message translates to:
  /// **'Check your internet and try again.'**
  String get dashNoConnectionSub;

  /// No description provided for @dashRetryBtn.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get dashRetryBtn;

  /// No description provided for @dashNoAppointmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'No Incoming Bookings'**
  String get dashNoAppointmentsTitle;

  /// No description provided for @dashNoAppointmentsSub.
  ///
  /// In en, this message translates to:
  /// **'There are no appointments today or new requests waiting for you.'**
  String get dashNoAppointmentsSub;

  /// No description provided for @dashErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Error Loading Data'**
  String get dashErrorTitle;

  /// No description provided for @dashErrorNoDoctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor details not found.\nPlease contact admin.'**
  String get dashErrorNoDoctor;

  /// No description provided for @dashErrorSetupProfile.
  ///
  /// In en, this message translates to:
  /// **'Setup Profile'**
  String get dashErrorSetupProfile;

  /// No description provided for @dashAcceptSuccess.
  ///
  /// In en, this message translates to:
  /// **'Appointment Accepted'**
  String get dashAcceptSuccess;

  /// No description provided for @dashRejectSuccess.
  ///
  /// In en, this message translates to:
  /// **'Appointment Rejected'**
  String get dashRejectSuccess;

  /// No description provided for @dashRejectReason.
  ///
  /// In en, this message translates to:
  /// **'Rejected by doctor'**
  String get dashRejectReason;

  /// No description provided for @dashErrorGeneral.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get dashErrorGeneral;

  /// No description provided for @apptTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get apptTitle;

  /// No description provided for @apptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage all your appointments'**
  String get apptSubtitle;

  /// No description provided for @apptTabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get apptTabAll;

  /// No description provided for @apptTabPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get apptTabPending;

  /// No description provided for @apptTabConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get apptTabConfirmed;

  /// No description provided for @apptTabCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get apptTabCompleted;

  /// No description provided for @apptTabCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get apptTabCancelled;

  /// No description provided for @apptNoAppointments.
  ///
  /// In en, this message translates to:
  /// **'No Appointments'**
  String get apptNoAppointments;

  /// No description provided for @apptAcceptSuccess.
  ///
  /// In en, this message translates to:
  /// **'Appointment Accepted'**
  String get apptAcceptSuccess;

  /// No description provided for @apptRejectSuccess.
  ///
  /// In en, this message translates to:
  /// **'Appointment Rejected'**
  String get apptRejectSuccess;

  /// No description provided for @apptRejectReason.
  ///
  /// In en, this message translates to:
  /// **'Rejected by doctor'**
  String get apptRejectReason;

  /// No description provided for @apptError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get apptError;

  /// No description provided for @ptsTitle.
  ///
  /// In en, this message translates to:
  /// **'Patients'**
  String get ptsTitle;

  /// No description provided for @ptsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a patient...'**
  String get ptsSearchHint;

  /// No description provided for @ptsNoPatients.
  ///
  /// In en, this message translates to:
  /// **'No patients'**
  String get ptsNoPatients;

  /// No description provided for @ptsNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get ptsNoResults;

  /// No description provided for @profTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profTitle;

  /// No description provided for @profLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get profLogout;

  /// No description provided for @profLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get profLogoutConfirm;

  /// No description provided for @profCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get profCancel;

  /// No description provided for @profErrorLabel.
  ///
  /// In en, this message translates to:
  /// **'Error Loading Data'**
  String get profErrorLabel;

  /// No description provided for @profClinicInfo.
  ///
  /// In en, this message translates to:
  /// **'Clinic Information'**
  String get profClinicInfo;

  /// No description provided for @profClinicName.
  ///
  /// In en, this message translates to:
  /// **'Clinic Name'**
  String get profClinicName;

  /// No description provided for @profClinicUnspecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get profClinicUnspecified;

  /// No description provided for @profAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get profAddress;

  /// No description provided for @profPhone.
  ///
  /// In en, this message translates to:
  /// **'Clinic Phone'**
  String get profPhone;

  /// No description provided for @profFees.
  ///
  /// In en, this message translates to:
  /// **'Consultation Fee'**
  String get profFees;

  /// No description provided for @profFeesCurrency.
  ///
  /// In en, this message translates to:
  /// **'EGP'**
  String get profFeesCurrency;

  /// No description provided for @profWorkingHours.
  ///
  /// In en, this message translates to:
  /// **'Working Hours'**
  String get profWorkingHours;

  /// No description provided for @profPersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get profPersonalInfo;

  /// No description provided for @profEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profEmail;

  /// No description provided for @profPersonalPhone.
  ///
  /// In en, this message translates to:
  /// **'Personal Phone'**
  String get profPersonalPhone;

  /// No description provided for @profExperience.
  ///
  /// In en, this message translates to:
  /// **'Years of Experience'**
  String get profExperience;

  /// No description provided for @profExperienceYears.
  ///
  /// In en, this message translates to:
  /// **'{years} years'**
  String profExperienceYears(String years);

  /// No description provided for @profBio.
  ///
  /// In en, this message translates to:
  /// **'About the Doctor'**
  String get profBio;

  /// No description provided for @profEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profEditProfile;

  /// No description provided for @profDiagnostic.
  ///
  /// In en, this message translates to:
  /// **'Diagnostic Info'**
  String get profDiagnostic;

  /// No description provided for @profDiagnosticSub.
  ///
  /// In en, this message translates to:
  /// **'To identify data issues'**
  String get profDiagnosticSub;

  /// No description provided for @profHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get profHelpSupport;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get chatTitle;

  /// No description provided for @chatErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Error Loading Data'**
  String get chatErrorTitle;

  /// No description provided for @chatErrorNoDoctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor information not found'**
  String get chatErrorNoDoctor;

  /// No description provided for @chatErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'An error occurred: '**
  String get chatErrorPrefix;

  /// No description provided for @chatNoChatsTitle.
  ///
  /// In en, this message translates to:
  /// **'No chats yet'**
  String get chatNoChatsTitle;

  /// No description provided for @chatNoChatsSub.
  ///
  /// In en, this message translates to:
  /// **'When patients contact you,\nchats will appear here'**
  String get chatNoChatsSub;

  /// No description provided for @chatDateYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get chatDateYesterday;

  /// No description provided for @chatNoMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages'**
  String get chatNoMessages;

  /// No description provided for @apptCardStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get apptCardStatusPending;

  /// No description provided for @apptCardStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get apptCardStatusConfirmed;

  /// No description provided for @apptCardStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get apptCardStatusCompleted;

  /// No description provided for @apptCardStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get apptCardStatusCancelled;

  /// No description provided for @apptCardTypeNew.
  ///
  /// In en, this message translates to:
  /// **'New Consultation'**
  String get apptCardTypeNew;

  /// No description provided for @apptCardTypeFollowup.
  ///
  /// In en, this message translates to:
  /// **'Follow-up'**
  String get apptCardTypeFollowup;

  /// No description provided for @apptCardPatientFallback.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get apptCardPatientFallback;

  /// No description provided for @apptCardStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status: '**
  String get apptCardStatusLabel;

  /// No description provided for @apptCardBtnReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get apptCardBtnReject;

  /// No description provided for @apptCardBtnAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get apptCardBtnAccept;

  /// No description provided for @chatDetailSendError.
  ///
  /// In en, this message translates to:
  /// **'Failed to send message: '**
  String get chatDetailSendError;

  /// No description provided for @chatDetailStartPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation with the patient'**
  String get chatDetailStartPlaceholder;

  /// No description provided for @chatDetailInputHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get chatDetailInputHint;

  /// No description provided for @chatDetailToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get chatDetailToday;

  /// No description provided for @chatDetailYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get chatDetailYesterday;

  /// No description provided for @ptDetailAgeYears.
  ///
  /// In en, this message translates to:
  /// **'{age} years'**
  String ptDetailAgeYears(String age);

  /// No description provided for @ptDetailGenderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get ptDetailGenderMale;

  /// No description provided for @ptDetailGenderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get ptDetailGenderFemale;

  /// No description provided for @ptDetailTabInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get ptDetailTabInfo;

  /// No description provided for @ptDetailTabAppointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get ptDetailTabAppointments;

  /// No description provided for @ptDetailTabRecords.
  ///
  /// In en, this message translates to:
  /// **'Medical Records'**
  String get ptDetailTabRecords;

  /// No description provided for @ptInfoContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get ptInfoContactTitle;

  /// No description provided for @ptInfoPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get ptInfoPhone;

  /// No description provided for @ptInfoEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get ptInfoEmail;

  /// No description provided for @ptInfoAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get ptInfoAddress;

  /// No description provided for @ptInfoMedicalHistory.
  ///
  /// In en, this message translates to:
  /// **'Medical History'**
  String get ptInfoMedicalHistory;

  /// No description provided for @ptInfoChronic.
  ///
  /// In en, this message translates to:
  /// **'Chronic Diseases'**
  String get ptInfoChronic;

  /// No description provided for @ptInfoAllergies.
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get ptInfoAllergies;

  /// No description provided for @ptInfoSurgeries.
  ///
  /// In en, this message translates to:
  /// **'Previous Surgeries'**
  String get ptInfoSurgeries;

  /// No description provided for @ptInfoMedications.
  ///
  /// In en, this message translates to:
  /// **'Current Medications'**
  String get ptInfoMedications;

  /// No description provided for @ptApptErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'Error loading appointments'**
  String get ptApptErrorLoad;

  /// No description provided for @ptApptUpcomingTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Appointments'**
  String get ptApptUpcomingTitle;

  /// No description provided for @ptApptPastTitle.
  ///
  /// In en, this message translates to:
  /// **'Past Appointments'**
  String get ptApptPastTitle;

  /// No description provided for @ptApptDoctorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Doctor '**
  String get ptApptDoctorPrefix;

  /// No description provided for @ptApptBtnConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get ptApptBtnConfirm;

  /// No description provided for @ptApptBtnCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get ptApptBtnCancel;

  /// No description provided for @ptApptUpdateStatusSuccess.
  ///
  /// In en, this message translates to:
  /// **'Appointment status updated'**
  String get ptApptUpdateStatusSuccess;

  /// No description provided for @ptApptUpdateStatusError.
  ///
  /// In en, this message translates to:
  /// **'Error updating status'**
  String get ptApptUpdateStatusError;

  /// No description provided for @ptApptCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Appointment'**
  String get ptApptCancelTitle;

  /// No description provided for @ptApptCancelReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Reason for cancellation (optional)'**
  String get ptApptCancelReasonHint;

  /// No description provided for @ptApptCancelBtnBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get ptApptCancelBtnBack;

  /// No description provided for @ptApptCancelBtnConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel Appointment'**
  String get ptApptCancelBtnConfirm;

  /// No description provided for @ptApptCancelSuccess.
  ///
  /// In en, this message translates to:
  /// **'Appointment cancelled'**
  String get ptApptCancelSuccess;

  /// No description provided for @ptApptEmpty.
  ///
  /// In en, this message translates to:
  /// **'No appointments'**
  String get ptApptEmpty;

  /// No description provided for @ptRecordsErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'Error loading medical records'**
  String get ptRecordsErrorLoad;

  /// No description provided for @ptRecordsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No medical records'**
  String get ptRecordsEmpty;

  /// No description provided for @ptRecordsSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Symptoms'**
  String get ptRecordsSymptoms;

  /// No description provided for @ptRecordsPrescriptions.
  ///
  /// In en, this message translates to:
  /// **'Prescriptions'**
  String get ptRecordsPrescriptions;

  /// No description provided for @ptRecordsNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get ptRecordsNotes;

  /// No description provided for @ptRecordsAttachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get ptRecordsAttachments;

  /// No description provided for @ptRecordsAttachmentItem.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get ptRecordsAttachmentItem;

  /// No description provided for @ptRecordsDosage.
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get ptRecordsDosage;

  /// No description provided for @ptRecordsFrequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get ptRecordsFrequency;

  /// No description provided for @ptRecordsDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get ptRecordsDuration;

  /// No description provided for @ptRecordsInstructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get ptRecordsInstructions;

  /// No description provided for @ptRecordsOpenAttachmentMsg.
  ///
  /// In en, this message translates to:
  /// **'Opening attachment: '**
  String get ptRecordsOpenAttachmentMsg;

  /// No description provided for @apptDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointment Details'**
  String get apptDetailTitle;

  /// No description provided for @apptDetailPatientReport.
  ///
  /// In en, this message translates to:
  /// **'Patient\'s Report'**
  String get apptDetailPatientReport;

  /// No description provided for @apptDetailNoReport.
  ///
  /// In en, this message translates to:
  /// **'Patient did not provide a report'**
  String get apptDetailNoReport;

  /// No description provided for @apptDetailPrescriptions.
  ///
  /// In en, this message translates to:
  /// **'Prescriptions'**
  String get apptDetailPrescriptions;

  /// No description provided for @apptDetailAddMedicine.
  ///
  /// In en, this message translates to:
  /// **'Add Medicine'**
  String get apptDetailAddMedicine;

  /// No description provided for @apptDetailMedicineName.
  ///
  /// In en, this message translates to:
  /// **'Medicine Name'**
  String get apptDetailMedicineName;

  /// No description provided for @apptDetailDosage.
  ///
  /// In en, this message translates to:
  /// **'Dosage (e.g. 500mg)'**
  String get apptDetailDosage;

  /// No description provided for @apptDetailFrequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency (e.g. 3x daily)'**
  String get apptDetailFrequency;

  /// No description provided for @apptDetailDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration (e.g. 7 days)'**
  String get apptDetailDuration;

  /// No description provided for @apptDetailReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Medication Reminder'**
  String get apptDetailReminderTitle;

  /// No description provided for @apptDetailReminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set a time to remind the patient'**
  String get apptDetailReminderSubtitle;

  /// No description provided for @apptDetailReminderSet.
  ///
  /// In en, this message translates to:
  /// **'Reminder: {datetime}'**
  String apptDetailReminderSet(String datetime);

  /// No description provided for @apptDetailReminderBtn.
  ///
  /// In en, this message translates to:
  /// **'Set Reminder'**
  String get apptDetailReminderBtn;

  /// No description provided for @apptDetailSaveBtn.
  ///
  /// In en, this message translates to:
  /// **'Save & Complete'**
  String get apptDetailSaveBtn;

  /// No description provided for @apptDetailSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Prescription saved successfully'**
  String get apptDetailSaveSuccess;

  /// No description provided for @apptDetailSaveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save prescription'**
  String get apptDetailSaveError;

  /// No description provided for @apptDetailPatientName.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get apptDetailPatientName;

  /// No description provided for @apptDetailDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get apptDetailDate;

  /// No description provided for @apptDetailType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get apptDetailType;

  /// No description provided for @apptDetailStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get apptDetailStatus;

  /// No description provided for @apptDetailNotes.
  ///
  /// In en, this message translates to:
  /// **'Doctor Notes'**
  String get apptDetailNotes;

  /// No description provided for @apptDetailNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Add notes (optional)'**
  String get apptDetailNotesHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
