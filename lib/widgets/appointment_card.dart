import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/colors.dart';
import '../models/appointment.dart';
import '../services/firestore_service.dart';
import '../l10n/app_localizations.dart';
import '../config/animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'animated_press_button.dart';

/// بطاقة الموعد — Premium Glassmorphic Design
class AppointmentCard extends StatefulWidget {
  final Appointment appointment;
  final Future<void> Function()? onAccept;
  final Future<void> Function()? onReject;
  final VoidCallback? onTap;
  final Future<void> Function()? onDelete;
  final bool showActions;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onAccept,
    this.onReject,
    this.onTap,
    this.onDelete,
    this.showActions = false,
  });

  @override
  State<AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<AppointmentCard> {
  bool _isProcessing = false;
  bool get isArabic => Localizations.localeOf(context).languageCode == 'ar';


  Future<void> _handleAction(Future<void> Function()? action) async {
    if (action == null || _isProcessing) return;
    if (mounted) setState(() => _isProcessing = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Color _statusColor() {
    switch (widget.appointment.status) {
      case 'pending':   return AppColors.pendingColor;
      case 'confirmed': return AppColors.pendingColor; // Consider patient-confirmed as awaiting doctor
      case 'accepted':  return AppColors.confirmedColor;
      case 'completed': return AppColors.completedColor;
      case 'cancelled': return AppColors.cancelledColor;
      default:          return AppColors.textSecondary;
    }
  }

  IconData _statusIcon() {
    switch (widget.appointment.status) {
      case 'pending':   return Icons.hourglass_top_rounded;
      case 'confirmed': return Icons.warning_amber_rounded;
      case 'accepted':  return Icons.check_circle_rounded;
      case 'completed': return Icons.task_alt_rounded;
      case 'cancelled': return Icons.cancel_rounded;
      default:          return Icons.help_outline_rounded;
    }
  }

  String _statusText(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (widget.appointment.status) {
      case 'pending':   return isArabic ? 'بانتظار تأكيد المريض' : 'Waiting for Patient';
      case 'confirmed': return isArabic ? 'طلب جديد (بانتظار موافقتك)' : 'New Request (Awaiting Action)';
      case 'accepted':  return l10n.apptCardStatusConfirmed;
      case 'completed': return l10n.apptCardStatusCompleted;
      case 'cancelled': return l10n.apptCardStatusCancelled;
      default:          return widget.appointment.status;
    }
  }

  String _typeText(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (widget.appointment.type) {
      case 'new':      return l10n.apptCardTypeNew;
      case 'followup': return l10n.apptCardTypeFollowup;
      default:         return widget.appointment.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final timeFormat = DateFormat('hh:mm a', locale);
    final dateFormat = DateFormat('EEE, d MMM', locale);
    final statusColor = _statusColor();
    final initials = (widget.appointment.patientName ?? 'P')
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();



    return Dismissible(
      key: Key(widget.appointment.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: isArabic ? Alignment.centerLeft : Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                const SizedBox(width: 8),
                Text(
                  isArabic ? 'حذف الموعد' : 'Delete Appointment',
                  style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: Text(
              isArabic 
                ? 'هل أنت متأكد من حذف هذا الموعد نهائياً؟ لا يمكن التراجع عن هذا الإجراء.' 
                : 'Are you sure you want to permanently delete this appointment? This action cannot be undone.',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 15),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  isArabic ? 'إلغاء' : 'Cancel',
                  style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  isArabic ? 'حذف' : 'Delete',
                  style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (direction) async {
        if (widget.onDelete != null) {
          widget.onDelete!();
        } else {
          try {
            await FirestoreService().deleteAppointment(widget.appointment.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isArabic ? 'تم حذف الموعد' : 'Appointment deleted'),
                  backgroundColor: Colors.grey.shade800,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isArabic ? 'حدث خطأ أثناء الحذف' : 'Error deleting appointment'),
                  backgroundColor: AppColors.error,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.cardShadow,
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [statusColor, statusColor.withValues(alpha: 0.5)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.tealGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: widget.appointment.patientPhotoUrl != null
                                  ? ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl: widget.appointment.patientPhotoUrl!,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => const Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) => const Icon(Icons.error),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        initials,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.appointment.patientName ?? l10n.apptCardPatientFallback,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                      fontFamily: 'Cairo',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 4,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.calendar_today_rounded,
                                            size: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            dateFormat.format(widget.appointment.dateTime),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                              fontFamily: 'Cairo',
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.schedule_rounded,
                                            size: 12,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            timeFormat.format(widget.appointment.dateTime),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                              fontFamily: 'Cairo',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.glassTeal,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Text(
                                  _typeText(context),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    fontFamily: 'Cairo',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_statusIcon(), size: 13, color: statusColor),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      _statusText(context),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: statusColor,
                                        fontFamily: 'Cairo',
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (widget.showActions && (widget.appointment.status == 'pending' || widget.appointment.status == 'confirmed')) ...[
                          const SizedBox(height: 14),
                          const Divider(height: 1, color: AppColors.border),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: AnimatedPressButton(
                                  onPressed: _isProcessing ? null : () => _handleAction(widget.onReject),
                                  backgroundColor: AppColors.error.withValues(alpha: 0.1),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _isProcessing 
                                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error))
                                          : const Icon(Icons.close_rounded, size: 14, color: AppColors.error),
                                      const SizedBox(width: 6),
                                      Text(
                                        l10n.apptCardStatusCancelled, 
                                        style: const TextStyle(
                                          fontFamily: 'Cairo', 
                                          fontWeight: FontWeight.w700, 
                                          color: AppColors.error,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AnimatedPressButton(
                                  onPressed: _isProcessing ? null : () => _handleAction(widget.onAccept),
                                  backgroundColor: AppColors.confirmedColor,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _isProcessing
                                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                                      const SizedBox(width: 6),
                                      Text(
                                        _isProcessing ? '...' : l10n.apptCardBtnAccept,
                                        style: const TextStyle(
                                          fontFamily: 'Cairo',
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else if (widget.appointment.status == 'accepted' || widget.appointment.status == 'confirmed') ...[
                          const SizedBox(height: 14),
                          const Divider(height: 1, color: AppColors.border),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: AnimatedPressButton(
                                  onPressed: widget.onTap,
                                  backgroundColor: AppColors.primary,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.medication_rounded, size: 18, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text(
                                          'Prescribe Medicene',
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
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
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ).animate(key: ValueKey(widget.appointment.id))
   .fadeIn(duration: AppAnimations.entrance, curve: AppAnimations.easeOut)
   .slideY(begin: 0.05, end: 0, duration: AppAnimations.entrance, curve: AppAnimations.easeOut);
}
}
