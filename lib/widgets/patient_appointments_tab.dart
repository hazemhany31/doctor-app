
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/colors.dart';
import '../config/constants.dart';
import '../models/appointment.dart';
import '../services/firestore_service.dart';
import '../l10n/app_localizations.dart';

/// تبويب مواعيد المريض
class PatientAppointmentsTab extends StatelessWidget {
  final String patientId;
  final FirestoreService _firestoreService = FirestoreService();

  PatientAppointmentsTab({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Appointment>>(
      stream: _firestoreService.getPatientAppointments(patientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final l10n = AppLocalizations.of(context)!;

        if (snapshot.hasError) {
          return Center(child: Text(l10n.ptApptErrorLoad));
        }

        final appointments = snapshot.data ?? [];

        if (appointments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: 16),
                Text(
                  l10n.ptApptEmpty, // fixed invalid getter
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        // تقسيم المواعيد إلى قادمة وسابقة
        // اعتبر المواعيد المعلقة والمؤكدة ضمن القادمة لتبقى في الأعلى
        final upcomingAppointments = appointments
            .where((a) => a.isUpcoming || a.status == AppConstants.appointmentPending || a.status == AppConstants.appointmentConfirmed)
            .toList();
        final pastAppointments = appointments
            .where((a) => !(a.isUpcoming || a.status == AppConstants.appointmentPending || a.status == AppConstants.appointmentConfirmed))
            .toList();

        return ListView(
          padding: EdgeInsets.all(16),
          children: [
            if (upcomingAppointments.isNotEmpty) ...[
              _buildSectionHeader(l10n.ptApptUpcomingTitle),
              SizedBox(height: 8),
              ...upcomingAppointments.map(
                (appointment) =>
                    _buildAppointmentCard(context, appointment, true),
              ),
              SizedBox(height: 24),
            ],
            if (pastAppointments.isNotEmpty) ...[
              _buildSectionHeader(l10n.ptApptPastTitle),
              SizedBox(height: 8),
              ...pastAppointments.map(
                (appointment) =>
                    _buildAppointmentCard(context, appointment, false),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildAppointmentCard(
    BuildContext context,
    Appointment appointment,
    bool isUpcoming,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat(
                          'EEEE, d MMMM yyyy',
                          Localizations.localeOf(context).languageCode,
                        ).format(appointment.dateTime),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_filled_rounded,
                            size: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat(
                              'h:mm a',
                              Localizations.localeOf(context).languageCode,
                            ).format(appointment.dateTime),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(context, appointment.status),
              ],
            ),
            if (appointment.doctorName != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person, size: 16, color: AppColors.primaryBlue),
                    const SizedBox(width: 8),
                    Text(
                      '${AppLocalizations.of(context)!.ptApptDoctorPrefix}${appointment.doctorName}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[300] : Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.orange.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                ),
                child: Text(
                  appointment.notes!,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.orange[200] : Colors.orange[800],
                  ),
                ),
              ),
            ],
            
            // ─── Patient Report ───
            if (appointment.patientReport != null && appointment.patientReport!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionTitle(context, AppLocalizations.of(context)!.ptInfoMedicalHistory, Icons.assignment_rounded, isDark),
              const SizedBox(height: 8),
              Text(
                appointment.patientReport!,
                style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[300] : Colors.grey[800]),
              ),
            ],

            // ─── Doctor Notes ───
            if (appointment.doctorNotes != null && appointment.doctorNotes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionTitle(context, AppLocalizations.of(context)!.ptRecordsNotes, Icons.medical_information_rounded, isDark),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.primaryBlue.withValues(alpha: 0.1) : AppColors.primaryBlue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
                ),
                child: Text(
                  appointment.doctorNotes!,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.blue[200] : AppColors.primaryBlue,
                  ),
                ),
              ),
            ],

            // ─── Prescriptions ───
            if (appointment.prescriptions.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionTitle(context, AppLocalizations.of(context)!.ptRecordsPrescriptions, Icons.medication_rounded, isDark),
              const SizedBox(height: 8),
              ...appointment.prescriptions.map((med) => _buildMedicineCard(context, med, isDark)),
            ],

            // أزرار تحديث الحالة (للمواعيد القادمة فقط)
            if (isUpcoming &&
                appointment.status != AppConstants.appointmentCompleted &&
                appointment.status != AppConstants.appointmentCancelled) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  if (appointment.status == AppConstants.appointmentPending)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateAppointmentStatus(
                          context,
                          appointment.id,
                          AppConstants.appointmentConfirmed,
                        ),
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                        label: Text(
                          AppLocalizations.of(context)!.ptApptBtnConfirm,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF10B981),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  if (appointment.status == AppConstants.appointmentPending)
                    const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showCancelDialog(context, appointment.id),
                      icon: const Icon(Icons.cancel_outlined, size: 20),
                      label: Text(
                        AppLocalizations.of(context)!.ptApptBtnCancel,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 18, color: isDark ? Colors.grey[400] : Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.grey[300] : Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildMedicineCard(BuildContext context, AppointmentMedicine med, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.vaccines_rounded, size: 16, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  med.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    decoration: med.isTaken ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (med.isTaken)
                Icon(Icons.check_circle, color: Colors.green[600], size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildMedDetail(isDark, Icons.monitor_weight_outlined, med.dosage),
              _buildMedDetail(isDark, Icons.repeat_rounded, med.frequency),
              if (med.frequencyHours != null)
                _buildMedDetail(isDark, Icons.access_time_rounded, 
                  Localizations.localeOf(context).languageCode == 'ar' 
                  ? 'كل ${med.frequencyHours} ساعة' 
                  : 'Every ${med.frequencyHours} hrs'),
              _buildMedDetail(isDark, Icons.date_range_rounded, med.duration),
              if (med.reminderTime != null)
                _buildMedDetail(isDark, Icons.alarm_on_rounded, 
                  Localizations.localeOf(context).languageCode == 'ar' 
                  ? 'تنبيه: ${DateFormat('hh:mm a', 'ar').format(med.reminderTime!)}' 
                  : 'Alarm: ${DateFormat('hh:mm a', 'en').format(med.reminderTime!)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedDetail(bool isDark, IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: isDark ? Colors.grey[500] : Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey[400] : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    Color color;
    String text;

    switch (status) {
      case AppConstants.appointmentPending:
        color = Colors.orange;
        text = l10n.apptCardStatusPending;
        break;
      case AppConstants.appointmentConfirmed:
        color = Colors.blue;
        text = l10n.apptCardStatusConfirmed;
        break;
      case AppConstants.appointmentCompleted:
        color = Colors.green;
        text = l10n.apptCardStatusCompleted;
        break;
      case AppConstants.appointmentCancelled:
        color = Colors.red;
        text = l10n.apptCardStatusCancelled;
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _updateAppointmentStatus(
    BuildContext context,
    String appointmentId,
    String status,
  ) async {
    try {
      await _firestoreService.updateAppointmentStatus(appointmentId, status);
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.ptApptUpdateStatusSuccess)));
      }
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.ptApptUpdateStatusError)));
      }
    }
  }

  void _showCancelDialog(BuildContext context, String appointmentId) {
    final l10n = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.ptApptCancelTitle),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(
            labelText: l10n.ptApptCancelReasonHint,
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.ptApptCancelBtnBack),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              navigator.pop();

              await _firestoreService.updateAppointmentStatus(
                appointmentId,
                AppConstants.appointmentCancelled,
                cancelReason: reasonController.text.isNotEmpty
                    ? reasonController.text
                    : null,
              );

              messenger.showSnackBar(
                SnackBar(content: Text(l10n.ptApptCancelSuccess)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.ptApptCancelBtnConfirm),
          ),
        ],
      ),
    );
  }
}
