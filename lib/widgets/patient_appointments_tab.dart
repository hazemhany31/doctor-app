import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/colors.dart';
import '../config/constants.dart';
import '../models/appointment.dart';
import '../services/firestore_service.dart';

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

        if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ في تحميل المواعيد'));
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
                  'لا توجد مواعيد',
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
        final upcomingAppointments = appointments
            .where((a) => a.isUpcoming)
            .toList();
        final pastAppointments = appointments.where((a) => a.isPast).toList();

        return ListView(
          padding: EdgeInsets.all(16),
          children: [
            if (upcomingAppointments.isNotEmpty) ...[
              _buildSectionHeader('المواعيد القادمة'),
              SizedBox(height: 8),
              ...upcomingAppointments.map(
                (appointment) =>
                    _buildAppointmentCard(context, appointment, true),
              ),
              SizedBox(height: 24),
            ],
            if (pastAppointments.isNotEmpty) ...[
              _buildSectionHeader('المواعيد السابقة'),
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
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
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
                          'EEEE، d MMMM yyyy',
                          'ar',
                        ).format(appointment.dateTime),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        DateFormat('h:mm a', 'ar').format(appointment.dateTime),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(appointment.status),
              ],
            ),
            if (appointment.doctorName != null) ...[
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person, size: 18, color: AppColors.primaryBlue),
                  SizedBox(width: 8),
                  Text(
                    'د. ${appointment.doctorName}',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
            if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                appointment.notes!,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
            // أزرار تحديث الحالة (للمواعيد القادمة فقط)
            if (isUpcoming &&
                appointment.status != AppConstants.appointmentCompleted &&
                appointment.status != AppConstants.appointmentCancelled) ...[
              SizedBox(height: 12),
              Row(
                children: [
                  if (appointment.status == AppConstants.appointmentPending)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _updateAppointmentStatus(
                          context,
                          appointment.id,
                          AppConstants.appointmentConfirmed,
                        ),
                        icon: Icon(Icons.check, size: 18),
                        label: Text('تأكيد'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: BorderSide(color: Colors.green),
                        ),
                      ),
                    ),
                  if (appointment.status == AppConstants.appointmentPending)
                    SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showCancelDialog(context, appointment.id),
                      icon: Icon(Icons.close, size: 18),
                      label: Text('إلغاء'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red),
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

  Widget _buildStatusChip(String status) {
    Color color;
    String text;

    switch (status) {
      case AppConstants.appointmentPending:
        color = Colors.orange;
        text = 'قيد الانتظار';
        break;
      case AppConstants.appointmentConfirmed:
        color = Colors.blue;
        text = 'مؤكد';
        break;
      case AppConstants.appointmentCompleted:
        color = Colors.green;
        text = 'مكتمل';
        break;
      case AppConstants.appointmentCancelled:
        color = Colors.red;
        text = 'ملغي';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تم تحديث حالة الموعد')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ في تحديث الحالة')));
      }
    }
  }

  void _showCancelDialog(BuildContext context, String appointmentId) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إلغاء الموعد'),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(
            labelText: 'سبب الإلغاء (اختياري)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('تراجع'),
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
                SnackBar(content: Text('تم إلغاء الموعد')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('إلغاء الموعد'),
          ),
        ],
      ),
    );
  }
}
