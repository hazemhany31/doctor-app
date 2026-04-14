
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/colors.dart';
import '../../models/appointment.dart';
import '../../services/firestore_service.dart';
import '../../l10n/app_localizations.dart';
import '../../config/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import '../../models/prescription_template.dart';
import '../../services/auth_service.dart';

/// شاشة تفاصيل الموعد — الدكتور يشوف تقرير المريض ويكتب الوصفة ويضبط التنبيه
class AppointmentDetailScreen extends StatefulWidget {
  final Appointment appointment;

  const AppointmentDetailScreen({super.key, required this.appointment});

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  final _notesController = TextEditingController();

  // قائمة الأدوية
  final List<_MedicineEntry> _medicines = [];

  // وقت التنبيه
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // تحميل البيانات الموجودة مسبقاً
    _notesController.text = widget.appointment.doctorNotes ?? '';

    for (final med in widget.appointment.prescriptions) {
      _medicines.add(
        _MedicineEntry(
          nameController: TextEditingController(text: med.name),
          dosageController: TextEditingController(text: med.dosage),
          frequencyController: TextEditingController(text: med.frequency),
          hoursController: TextEditingController(text: med.frequencyHours?.toString() ?? ''),
          durationController: TextEditingController(text: med.duration),
          reminderTime: med.reminderTime,
          isTaken: med.isTaken,
        ),
      );
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final m in _medicines) {
      m.dispose();
    }
    super.dispose();
  }

  void _addMedicine() {
    setState(() {
      _medicines.add(_MedicineEntry(
        nameController: TextEditingController(),
        dosageController: TextEditingController(),
        frequencyController: TextEditingController(),
        hoursController: TextEditingController(),
        durationController: TextEditingController(),
      ));
    });
  }

  void _removeMedicine(int index) {
    setState(() {
      _medicines[index].dispose();
      _medicines.removeAt(index);
    });
  }

  Future<void> _pickMedicineReminder(int index) async {
    final now = DateTime.now();
    final currentReminder = _medicines[index].reminderTime;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: currentReminder ?? now.add(const Duration(minutes: 30)),
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
          currentReminder ?? now.add(const Duration(minutes: 30))),
    );
    if (pickedTime == null || !mounted) return;

    final finalDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      _medicines[index].reminderTime = finalDateTime;
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSaving = true);

    try {
      final prescriptionMaps = _medicines
          .where((m) => m.nameController.text.trim().isNotEmpty)
          .map(
            (m) => {
              'name': m.nameController.text.trim(),
              'dosage': m.dosageController.text.trim(),
              'frequency': m.frequencyController.text.trim(),
              'frequencyHours': int.tryParse(m.hoursController.text.trim()),
              'duration': m.durationController.text.trim(),
              'reminderTime': m.reminderTime != null
                  ? Timestamp.fromDate(m.reminderTime!)
                  : null,
              'isTaken': m.isTaken,
            },
          )
          .toList();

      // جلب الـ user ID علشان نكتب الـ fees في الـ appointment
      final currentUserId = _authService.currentUser?.uid;

      await _firestoreService.updateAppointmentDetails(
        widget.appointment.id,
        prescriptions: prescriptionMaps,
        doctorNotes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        status: AppConstants.appointmentCompleted,
        doctorId: currentUserId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.apptDetailSaveSuccess),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.apptDetailSaveError),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showTemplatePicker() async {
    final user = AuthService().currentUser;
    if (user == null) return;
    final doctor = await _firestoreService.getDoctorByUserId(user.uid);
    if (doctor == null) return;

    final templatesSnapshot = await FirebaseFirestore.instance
        .collection(AppConstants.doctorsCollection)
        .doc(doctor.id)
        .collection('templates')
        .get();

    final templates = templatesSnapshot.docs
        .map((d) => PrescriptionTemplate.fromFirestore(d))
        .toList();

    if (templates.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد قوالب محفوظة. يمكنك إنشاؤها من لوحة التحكم.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: templates.length,
          itemBuilder: (context, index) {
            final t = templates[index];
            return ListTile(
              leading: const Icon(Icons.description, color: AppColors.primary),
              title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              subtitle: Text('${t.medicines.length} أدوية', style: const TextStyle(fontFamily: 'Cairo')),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  for (var med in t.medicines) {
                    _medicines.add(_MedicineEntry(
                      nameController: TextEditingController(text: med.name),
                      dosageController: TextEditingController(text: med.dosage),
                      frequencyController: TextEditingController(text: med.frequency),
                      durationController: TextEditingController(text: med.duration),
                      hoursController: TextEditingController(),
                    ));
                  }
                });
              },
            );
          },
        );
      },
    );
  }

  Future<void> _exportPdf() async {
    // 🚀 Performance Fix: Show loading overlay to prevent UI freeze feeling
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final appt = widget.appointment;
      final pdf = pw.Document();

      // Defer font loading to microtask to allow UI to render the loading indicator
      await Future.delayed(const Duration(milliseconds: 100));

      final font = await PdfGoogleFonts.cairoRegular();
      final boldFont = await PdfGoogleFonts.cairoBold();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(
            base: font,
            bold: boldFont,
          ),
          build: (pw.Context context) {
            return pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Header(
                    level: 0,
                    child: pw.Text('الوصفة الطبية (Prescription)', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('الطبيب: ${appt.doctorName ?? ''}', style: const pw.TextStyle(fontSize: 16)),
                      pw.Text('التاريخ: ${DateFormat('yyyy-MM-dd').format(appt.dateTime)}', style: const pw.TextStyle(fontSize: 14)),
                    ]
                  ),
                  pw.Text('المريض: ${appt.patientName ?? ''}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Divider(),
                  pw.SizedBox(height: 10),
                  pw.Text('الأدوية:', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue600)),
                  pw.SizedBox(height: 10),
                  ..._medicines.map((m) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 15, right: 10),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('- ${m.nameController.text}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                          pw.Text('  الجرعة: ${m.dosageController.text}', style: const pw.TextStyle(fontSize: 14)),
                          pw.Text('  التكرار: ${m.frequencyController.text}', style: const pw.TextStyle(fontSize: 14)),
                          pw.Text('  المدة: ${m.durationController.text}', style: const pw.TextStyle(fontSize: 14)),
                        ]
                      )
                    );
                  }),
                  if (_notesController.text.isNotEmpty) ...[
                    pw.SizedBox(height: 20),
                    pw.Divider(),
                    pw.Text('ملاحظات:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue600)),
                    pw.Text(_notesController.text, style: const pw.TextStyle(fontSize: 14)),
                  ]
                ],
              ),
            );
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/prescription_${appt.id}.pdf');
      
      // Save it in isolated thread so it doesn't freeze the UI 
      final bytes = await pdf.save();
      await file.writeAsBytes(bytes);

      if (mounted) Navigator.pop(context); // hide loading

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'الوصفة الطبية الخاصة بك المرفقة كملف PDF.',
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // hide loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء تصدير الملف: $e')),
        );
      }
    }

  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appt = widget.appointment;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final dateStr = DateFormat(
      isAr ? 'dd MMMM yyyy  –  hh:mm a' : 'MMM dd, yyyy  –  hh:mm a',
      isAr ? 'ar' : 'en',
    ).format(appt.dateTime);

    return Scaffold(
      backgroundColor: AppColors.of(context).scaffoldBg,
      body: CustomScrollView(
        slivers: [
          // ─── Header ───
          SliverAppBar(
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.premiumHeaderGradient,
                ),
              ),
            ),
            pinned: true,
            expandedHeight: 100,
            leading: IconButton(
              icon: Icon(
                isAr
                    ? Icons.arrow_forward_ios_rounded
                    : Icons.arrow_back_ios_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.apptDetailTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Cairo',
                  ),
                ),
                Text(
                  appt.patientName ?? l10n.apptDetailPatientName,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TypeChip(type: appt.type, l10n: l10n),
                    const SizedBox(width: 8),
                    _StatusChip(status: appt.status, l10n: l10n),
                  ],
                ),
              ),
            ],
          ),

          // ─── Body ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Appointment DateTime ───
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('appointments').doc(appt.id).snapshots(),
                    builder: (context, snapshot) {
                      int totalDosesCount = 0;
                      int takenDosesCount = 0;
                      final String dateKey = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";

                      if (appt.prescriptions.isNotEmpty) {
                        for (var med in appt.prescriptions) {
                          final times = _getDosesPerDay(med.frequency, med.frequencyHours);
                          totalDosesCount += times;
                          
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final data = snapshot.data!.data() as Map<String, dynamic>?;
                            if (data != null && data['medicationTracker'] != null) {
                              final tracker = data['medicationTracker'];
                              if (tracker[dateKey] != null && tracker[dateKey][med.name] != null) {
                                final medData = tracker[dateKey][med.name];
                                final taken = medData['takenDoses'] as List? ?? [];
                                takenDosesCount += taken.length;
                              }
                            }
                          }
                        }
                      }

                      final double overallProgress = totalDosesCount > 0 ? (takenDosesCount / totalDosesCount) : 0.0;
                      final int percent = (overallProgress * 100).toInt();

                      return Column(
                        children: [
                          _CompactInfoRow(
                            icon: Icons.event_note_rounded,
                            label: l10n.apptDetailDate,
                            value: dateStr,
                            trailing: totalDosesCount > 0 ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    percent == 100 ? Icons.check_circle_rounded : Icons.pie_chart_rounded,
                                    color: AppColors.primary,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "$percent%",
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'Cairo'
                                    ),
                                  ),
                                ],
                              ),
                            ) : null,
                          ),
                        ],
                      );
                    }
                  ),

                  const SizedBox(height: 16),

                  // ─── Patient Report ───
                  _SectionHeader(
                    icon: Icons.description_rounded,
                    label: l10n.apptDetailPatientReport,
                    color: const Color(0xFF6366F1),
                  ),
                  const SizedBox(height: 6),
                  _SectionCard(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: appt.patientReport != null &&
                                appt.patientReport!.trim().isNotEmpty
                            ? Text(
                                appt.patientReport!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                  fontFamily: 'Cairo',
                                  height: 1.5,
                                ),
                              )
                            : Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 16,
                                    color: AppColors.textHint,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.apptDetailNoReport,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textHint,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ─── Prescriptions ───
                  Row(
                    children: [
                      _SectionHeader(
                        icon: Icons.medication_rounded,
                        label: l10n.apptDetailPrescriptions,
                        color: AppColors.primary,
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _showTemplatePicker,
                        icon: const Icon(Icons.file_copy_rounded, size: 16),
                        label: const Text('قالب'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF6366F1),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _addMedicine,
                        icon: const Icon(Icons.add_circle_rounded, size: 18),
                        label: Text(l10n.apptDetailAddMedicine),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  if (_medicines.isEmpty)
                    _SectionCard(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              l10n.apptDetailAddMedicine,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textHint,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    ...List.generate(
                      _medicines.length,
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _MedicineCard(
                          entry: _medicines[i],
                          index: i + 1,
                          l10n: l10n,
                          onRemove: () => _removeMedicine(i),
                          onPickReminder: () => _pickMedicineReminder(i),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // ─── Doctor Notes ───
                  _SectionHeader(
                    icon: Icons.notes_rounded,
                    label: l10n.apptDetailNotes,
                    color: const Color(0xFF059669),
                  ),
                  const SizedBox(height: 6),
                  _SectionCard(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: TextField(
                          controller: _notesController,
                          maxLines: 3,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: l10n.apptDetailNotesHint,
                            hintStyle: const TextStyle(
                              fontFamily: 'Cairo',
                              color: AppColors.textHint,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ─── Save Button ───
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(l10n.apptDetailSaveBtn),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ─── Export PDF Button ───
                  if (appt.status == AppConstants.appointmentCompleted || _medicines.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _exportPdf,
                        icon: const Icon(Icons.picture_as_pdf_rounded),
                        label: const Text('المشاركة كملف PDF'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent, width: 2),
                          textStyle: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _extractNumber(String text) {
    final match = RegExp(r'(\d+)').firstMatch(text);
    return match != null ? int.parse(match.group(1)!) : 1;
  }

  int _getDosesPerDay(String frequency, int? frequencyHours) {
    int intervalHours = 24;
    if (frequencyHours != null && frequencyHours > 0) {
      intervalHours = frequencyHours;
    } else {
      final count = _extractNumber(frequency);
      if (count > 0) intervalHours = 24 ~/ count;
    }
    return 24 ~/ intervalHours;
  }
}

// ─────────────────────────────── Helpers ────────────────────────────────────

class _MedicineEntry {
  final TextEditingController nameController;
  final TextEditingController dosageController;
  final TextEditingController frequencyController;
  final TextEditingController hoursController;
  final TextEditingController durationController;
  DateTime? reminderTime;
  bool isTaken;

  _MedicineEntry({
    required this.nameController,
    required this.dosageController,
    required this.frequencyController,
    required this.hoursController,
    required this.durationController,
    this.reminderTime,
    this.isTaken = false,
  });

  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    frequencyController.dispose();
    hoursController.dispose();
    durationController.dispose();
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final AppLocalizations l10n;

  const _StatusChip({required this.status, required this.l10n});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case AppConstants.appointmentConfirmed:
        color = AppColors.success;
        label = l10n.apptCardStatusConfirmed;
        break;
      case AppConstants.appointmentCompleted:
        color = AppColors.info;
        label = l10n.apptCardStatusCompleted;
        break;
      case AppConstants.appointmentCancelled:
        color = AppColors.error;
        label = l10n.apptCardStatusCancelled;
        break;
      default:
        color = AppColors.warning;
        label = l10n.apptCardStatusPending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: c.textPrimary,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String type;
  final AppLocalizations l10n;

  const _TypeChip({required this.type, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Text(
        type == AppConstants.appointmentTypeNew
            ? l10n.apptCardTypeNew
            : l10n.apptCardTypeFollowup,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }
}

class _CompactInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const _CompactInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: c.textHint,
                    fontFamily: 'Cairo',
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;

  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: c.cardShadow,
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _MedicineCard extends StatelessWidget {
  final _MedicineEntry entry;
  final int index;
  final AppLocalizations l10n;
  final VoidCallback onRemove;
  final VoidCallback onPickReminder;

  const _MedicineCard({
    required this.entry,
    required this.index,
    required this.l10n,
    required this.onRemove,
    required this.onPickReminder,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAr = Localizations.localeOf(context).languageCode == 'ar';
    final c = AppColors.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
        boxShadow: c.cardShadow,
      ),
      child: Column(
        children: [
          // Taken Status Badge (If taken)
          if (entry.isTaken)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    isAr ? 'تم تناول هذا الدواء' : 'This medicine was taken',
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          // Name and Remove header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.medication_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: entry.nameController,
                    decoration: InputDecoration(
                      hintText: l10n.apptDetailMedicineName,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 52),
            child: Divider(height: 1, color: AppColors.border),
          ),
          // Fields grid - Row 1
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _MiniField(
                    controller: entry.dosageController,
                    hint: l10n.apptDetailDosage,
                    icon: Icons.scale_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniField(
                    controller: entry.frequencyController,
                    hint: l10n.apptDetailFrequency,
                    icon: Icons.repeat_rounded,
                  ),
                ),
              ],
            ),
          ),
          // Fields grid - Row 2
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: _MiniField(
                    controller: entry.hoursController,
                    hint: 'كل كم ساعة؟',
                    icon: Icons.access_time_rounded,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniField(
                    controller: entry.durationController,
                    hint: l10n.apptDetailDuration,
                    icon: Icons.hourglass_bottom_rounded,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: AppColors.border),
          ),
          // Reminder Row
          InkWell(
            onTap: onPickReminder,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    entry.reminderTime != null
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                    size: 16,
                    color: entry.reminderTime != null
                        ? const Color(0xFFF59E0B)
                        : AppColors.textHint,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.reminderTime != null
                        ? DateFormat(
                                isAr ? 'hh:mm a' : 'hh:mm a', isAr ? 'ar' : 'en')
                            .format(entry.reminderTime!)
                        : l10n.apptDetailReminderBtn,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: entry.reminderTime != null
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: entry.reminderTime != null
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const Spacer(),
                  if (entry.reminderTime != null)
                    const Icon(Icons.check_circle_outline_rounded,
                        size: 14, color: AppColors.success),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded,
                      size: 16, color: AppColors.textHint),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;

  const _MiniField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.of(context).surfaceBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.of(context).border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textHint),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
              ),
              keyboardType: keyboardType,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  fontFamily: 'Cairo',
                  color: AppColors.textHint,
                  fontSize: 11,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
