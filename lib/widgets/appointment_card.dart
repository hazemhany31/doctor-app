import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/colors.dart';
import '../models/appointment.dart';

/// بطاقة الموعد
class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onTap;
  final bool showActions;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onAccept,
    this.onReject,
    this.onTap,
    this.showActions = false,
  });

  Color _getStatusColor() {
    switch (appointment.status) {
      case 'pending':
        return AppColors.pendingColor;
      case 'confirmed':
        return AppColors.confirmedColor;
      case 'completed':
        return AppColors.completedColor;
      case 'cancelled':
        return AppColors.cancelledColor;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText() {
    switch (appointment.status) {
      case 'pending':
        return 'معلق';
      case 'confirmed':
        return 'مؤكد';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      default:
        return appointment.status;
    }
  }

  String _getTypeText() {
    switch (appointment.type) {
      case 'new':
        return 'كشف جديد';
      case 'followup':
        return 'متابعة';
      default:
        return appointment.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('hh:mm a', 'ar');
    final dateFormat = DateFormat('EEEE، d MMMM yyyy', 'ar');

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // صورة المريض
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: appointment.patientPhotoUrl != null
                        ? NetworkImage(appointment.patientPhotoUrl!)
                        : null,
                    child: appointment.patientPhotoUrl == null
                        ? Icon(Icons.person, size: 30)
                        : null,
                  ),
                  SizedBox(width: 12),
                  // معلومات المريض
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.patientName ?? 'مريض',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          dateFormat.format(appointment.dateTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          timeFormat.format(appointment.dateTime),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // نوع الزيارة
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getTypeText(),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              // الحالة
              Row(
                children: [
                  Icon(Icons.circle, size: 12, color: _getStatusColor()),
                  SizedBox(width: 6),
                  Text(
                    'الحالة: ${_getStatusText()}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              // الإجراءات
              if (showActions && appointment.status == 'pending') ...[
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // رفض
                    TextButton.icon(
                      onPressed: onReject,
                      icon: Icon(Icons.close, size: 18),
                      label: Text('رفض'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                    ),
                    SizedBox(width: 8),
                    // قبول
                    ElevatedButton.icon(
                      onPressed: onAccept,
                      icon: Icon(Icons.check, size: 18),
                      label: Text('قبول'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
