// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsTitle => 'Settings';

  @override
  String get preferencesSection => 'Preferences';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSubtitle => 'English';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEnabled => 'Enabled';

  @override
  String get notificationsDisabled => 'Disabled';

  @override
  String get supportSection => 'Help & Support';

  @override
  String get supportPhoneTitle => 'Technical Support';

  @override
  String get supportCustomerTitle => 'Customer Service';

  @override
  String get supportWhatsappTitle => 'Contact us on WhatsApp';

  @override
  String get supportWhatsappSubtitle => 'For inquiries and complaints';

  @override
  String get aboutSection => 'About App';

  @override
  String get appVersionTitle => 'App Version';

  @override
  String get privacyPolicyTitle => 'Privacy Policy';

  @override
  String get privacyPolicySubtitle => 'Read our policy';

  @override
  String get navHome => 'Home';

  @override
  String get navAppointments => 'Appointments';

  @override
  String get navMessages => 'Messages';

  @override
  String get navPatients => 'Patients';

  @override
  String get navProfile => 'Profile';

  @override
  String get emergencyDialogTitle => 'Emergency Request!';

  @override
  String emergencyDialogPatient(String name) {
    return 'Patient: $name';
  }

  @override
  String emergencyDialogDetails(String desc) {
    return 'Details: $desc';
  }

  @override
  String get emergencyDialogReject => 'Reject';

  @override
  String get emergencyDialogAccept => 'Accept';

  @override
  String get dashGreetingM => 'Good Morning';

  @override
  String get dashGreetingE => 'Good Evening';

  @override
  String get dashGreetingN => 'Good Night';

  @override
  String dashGreetingMsg(String greeting) {
    return '$greeting 👋';
  }

  @override
  String dashDrName(String name) {
    return 'Doctor $name';
  }

  @override
  String get dashOnline => 'Available';

  @override
  String get dashOffline => 'Offline';

  @override
  String get dashScheduleBtn => 'Schedule';

  @override
  String get dashStatsPatients => 'Today\'s Patients';

  @override
  String get dashStatsPending => 'Pending';

  @override
  String get dashStatsUpcoming => 'Upcoming';

  @override
  String get dashStatsTotal => 'Total';

  @override
  String get dashOverview => 'Overview';

  @override
  String get dashTodayAppointments => 'Today\'s Appointments';

  @override
  String get dashTodayAndNewAppointments => 'Today & New Bookings';

  @override
  String get dashViewAll => 'View All';

  @override
  String get dashNoConnectionTitle => 'No Connection';

  @override
  String get dashNoConnectionSub => 'Check your internet and try again.';

  @override
  String get dashRetryBtn => 'Retry';

  @override
  String get dashNoAppointmentsTitle => 'No Incoming Bookings';

  @override
  String get dashNoAppointmentsSub =>
      'There are no appointments today or new requests waiting for you.';

  @override
  String get dashErrorTitle => 'Error Loading Data';

  @override
  String get dashErrorNoDoctor =>
      'Doctor details not found.\nPlease contact admin.';

  @override
  String get dashErrorSetupProfile => 'Setup Profile';

  @override
  String get dashAcceptSuccess => 'Appointment Accepted';

  @override
  String get dashRejectSuccess => 'Appointment Rejected';

  @override
  String get dashRejectReason => 'Rejected by doctor';

  @override
  String get dashErrorGeneral => 'An error occurred';

  @override
  String get apptTitle => 'Appointments';

  @override
  String get apptSubtitle => 'Manage all your appointments';

  @override
  String get apptTabAll => 'All';

  @override
  String get apptTabPending => 'Pending';

  @override
  String get apptTabConfirmed => 'Confirmed';

  @override
  String get apptTabCompleted => 'Completed';

  @override
  String get apptTabCancelled => 'Cancelled';

  @override
  String get apptNoAppointments => 'No Appointments';

  @override
  String get apptAcceptSuccess => 'Appointment Accepted';

  @override
  String get apptRejectSuccess => 'Appointment Rejected';

  @override
  String get apptRejectReason => 'Rejected by doctor';

  @override
  String get apptError => 'An error occurred';

  @override
  String get ptsTitle => 'Patients';

  @override
  String get ptsSearchHint => 'Search for a patient...';

  @override
  String get ptsNoPatients => 'No patients';

  @override
  String get ptsNoResults => 'No results found';

  @override
  String get profTitle => 'Profile';

  @override
  String get profLogout => 'Logout';

  @override
  String get profLogoutConfirm => 'Are you sure you want to logout?';

  @override
  String get profCancel => 'Cancel';

  @override
  String get profErrorLabel => 'Error Loading Data';

  @override
  String get profClinicInfo => 'Clinic Information';

  @override
  String get profClinicName => 'Clinic Name';

  @override
  String get profClinicUnspecified => 'Not specified';

  @override
  String get profAddress => 'Address';

  @override
  String get profPhone => 'Clinic Phone';

  @override
  String get profFees => 'Consultation Fee';

  @override
  String get profFeesCurrency => 'EGP';

  @override
  String get profWorkingHours => 'Working Hours';

  @override
  String get profPersonalInfo => 'Personal Information';

  @override
  String get profEmail => 'Email';

  @override
  String get profPersonalPhone => 'Personal Phone';

  @override
  String get profExperience => 'Years of Experience';

  @override
  String profExperienceYears(String years) {
    return '$years years';
  }

  @override
  String get profBio => 'About the Doctor';

  @override
  String get profEditProfile => 'Edit Profile';

  @override
  String get profDiagnostic => 'Diagnostic Info';

  @override
  String get profDiagnosticSub => 'To identify data issues';

  @override
  String get profHelpSupport => 'Help & Support';

  @override
  String get chatTitle => 'Messages';

  @override
  String get chatSubtitle => 'Message your patients directly';

  @override
  String get chatErrorTitle => 'Error Loading Data';

  @override
  String get chatErrorNoDoctor => 'Doctor information not found';

  @override
  String get chatErrorPrefix => 'An error occurred: ';

  @override
  String get chatNoChatsTitle => 'No chats yet';

  @override
  String get chatNoChatsSub =>
      'When patients contact you,\nchats will appear here';

  @override
  String get chatDateYesterday => 'Yesterday';

  @override
  String get chatNoMessages => 'No messages';

  @override
  String get apptCardStatusPending => 'Pending';

  @override
  String get apptCardStatusConfirmed => 'Confirmed';

  @override
  String get apptCardStatusCompleted => 'Completed';

  @override
  String get apptCardStatusCancelled => 'Cancelled';

  @override
  String get apptCardTypeNew => 'New Consultation';

  @override
  String get apptCardTypeFollowup => 'Follow-up';

  @override
  String get apptCardPatientFallback => 'Patient';

  @override
  String get apptCardStatusLabel => 'Status: ';

  @override
  String get apptCardBtnReject => 'Reject';

  @override
  String get apptCardBtnAccept => 'Accept';

  @override
  String get chatDetailSendError => 'Failed to send message: ';

  @override
  String get chatDetailStartPlaceholder =>
      'Start a conversation with the patient';

  @override
  String get chatDetailInputHint => 'Type a message...';

  @override
  String get chatDetailToday => 'Today';

  @override
  String get chatDetailYesterday => 'Yesterday';

  @override
  String ptDetailAgeYears(String age) {
    return '$age years';
  }

  @override
  String get ptDetailGenderMale => 'Male';

  @override
  String get ptDetailGenderFemale => 'Female';

  @override
  String get ptDetailTabInfo => 'Info';

  @override
  String get ptDetailTabAppointments => 'Appointments';

  @override
  String get ptDetailTabRecords => 'Medical Records';

  @override
  String get ptInfoContactTitle => 'Contact Information';

  @override
  String get ptInfoPhone => 'Phone Number';

  @override
  String get ptInfoEmail => 'Email';

  @override
  String get ptInfoAddress => 'Address';

  @override
  String get ptInfoMedicalHistory => 'Medical History';

  @override
  String get ptInfoChronic => 'Chronic Diseases';

  @override
  String get ptInfoAllergies => 'Allergies';

  @override
  String get ptInfoSurgeries => 'Previous Surgeries';

  @override
  String get ptInfoMedications => 'Current Medications';

  @override
  String get ptApptErrorLoad => 'Error loading appointments';

  @override
  String get ptApptUpcomingTitle => 'Upcoming Appointments';

  @override
  String get ptApptPastTitle => 'Past Appointments';

  @override
  String get ptApptDoctorPrefix => 'Doctor ';

  @override
  String get ptApptBtnConfirm => 'Confirm';

  @override
  String get ptApptBtnCancel => 'Cancel';

  @override
  String get ptApptUpdateStatusSuccess => 'Appointment status updated';

  @override
  String get ptApptUpdateStatusError => 'Error updating status';

  @override
  String get ptApptCancelTitle => 'Cancel Appointment';

  @override
  String get ptApptCancelReasonHint => 'Reason for cancellation (optional)';

  @override
  String get ptApptCancelBtnBack => 'Back';

  @override
  String get ptApptCancelBtnConfirm => 'Cancel Appointment';

  @override
  String get ptApptCancelSuccess => 'Appointment cancelled';

  @override
  String get ptApptEmpty => 'No appointments';

  @override
  String get ptRecordsErrorLoad => 'Error loading medical records';

  @override
  String get ptRecordsEmpty => 'No medical records';

  @override
  String get ptRecordsSymptoms => 'Symptoms';

  @override
  String get ptRecordsPrescriptions => 'Prescriptions';

  @override
  String get ptRecordsNotes => 'Notes';

  @override
  String get ptRecordsAttachments => 'Attachments';

  @override
  String get ptRecordsAttachmentItem => 'Attachment';

  @override
  String get ptRecordsDosage => 'Dosage';

  @override
  String get ptRecordsFrequency => 'Frequency';

  @override
  String get ptRecordsDuration => 'Duration';

  @override
  String get ptRecordsInstructions => 'Instructions';

  @override
  String get ptRecordsOpenAttachmentMsg => 'Opening attachment: ';

  @override
  String get apptDetailTitle => 'Appointment Details';

  @override
  String get apptDetailPatientReport => 'Patient\'s Report';

  @override
  String get apptDetailNoReport => 'Patient did not provide a report';

  @override
  String get apptDetailPrescriptions => 'Prescriptions';

  @override
  String get apptDetailAddMedicine => 'Add Medicine';

  @override
  String get apptDetailMedicineName => 'Medicine Name';

  @override
  String get apptDetailDosage => 'Dosage (e.g. 500mg)';

  @override
  String get apptDetailFrequency => 'Frequency (e.g. 3x daily)';

  @override
  String get apptDetailDuration => 'Duration (e.g. 7 days)';

  @override
  String get apptDetailReminderTitle => 'Medication Reminder';

  @override
  String get apptDetailReminderSubtitle => 'Set a time to remind the patient';

  @override
  String apptDetailReminderSet(String datetime) {
    return 'Reminder: $datetime';
  }

  @override
  String get apptDetailReminderBtn => 'Set Reminder';

  @override
  String get apptDetailSaveBtn => 'Save & Complete';

  @override
  String get apptDetailSaveSuccess => 'Prescription saved successfully';

  @override
  String get apptDetailSaveError => 'Failed to save prescription';

  @override
  String get apptDetailPatientName => 'Patient';

  @override
  String get apptDetailDate => 'Date';

  @override
  String get apptDetailType => 'Type';

  @override
  String get apptDetailStatus => 'Status';

  @override
  String get apptDetailNotes => 'Doctor Notes';

  @override
  String get apptDetailNotesHint => 'Add notes (optional)';

  @override
  String get settingsDarkTitle => 'Dark Mode';

  @override
  String get settingsLightTitle => 'Light Mode';

  @override
  String get settingsDarkSub => 'Tap to switch to Light Mode';

  @override
  String get settingsLightSub => 'Tap to switch to Dark Mode';

  @override
  String get settingsAccountSection => 'Account Management';

  @override
  String get settingsDeleteAccountTitle => 'Delete Account Permanently';

  @override
  String get settingsDeleteAccountSub =>
      'All your data and records will be permanently deleted';

  @override
  String get deleteDialogTitle => 'Confirm Account Deletion';

  @override
  String get deleteDialogMessage =>
      'Are you sure you want to delete your account permanently? This action is irreversible, and all your patient data and records will be completely erased from the system in compliance with privacy policies.';

  @override
  String get deleteDialogConfirm => 'Confirm & Delete';

  @override
  String get reauthDialogTitle => 'Confirm Identity';

  @override
  String get reauthDialogMessage =>
      'To delete your account, please enter your current password to confirm your identity.';

  @override
  String get passwordLabel => 'Password';
}
