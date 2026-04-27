import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../config/colors.dart';
import '../models/medical_record.dart';
import '../models/appointment.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../l10n/app_localizations.dart';

/// تبويب السجلات الطبية للمريض — يعرض الملفات الطبية + تاريخ الوصفات من المواعيد
class PatientMedicalRecordsTab extends StatelessWidget {
  final String patientId;
  final FirestoreService _firestoreService = FirestoreService();

  PatientMedicalRecordsTab({super.key, required this.patientId});

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<MedicalRecord>>(
        stream: _firestoreService.getPatientMedicalRecords(patientId),
        builder: (context, recordsSnap) {
          return StreamBuilder<List<Appointment>>(
            stream: _firestoreService.getPatientAppointments(patientId),
            builder: (context, appsSnap) {
              final isLoading = recordsSnap.connectionState == ConnectionState.waiting ||
                  appsSnap.connectionState == ConnectionState.waiting;

              if (isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final l10n = AppLocalizations.of(context)!;
              final records = recordsSnap.data ?? [];
              // Show appointments that have prescriptions or notes regardless of status
              final appointments = (appsSnap.data ?? [])
                  .where((a) => (a.prescriptions.isNotEmpty ||
                          (a.doctorNotes != null && a.doctorNotes!.isNotEmpty)))
                  .toList();

              if (records.isEmpty && appointments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.medical_services_outlined,
                          size: 64, color: AppColors.textSecondary),
                      const SizedBox(height: 16),
                      Text(
                        l10n.ptRecordsEmpty,
                        style: TextStyle(
                            fontSize: 16, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  // ── Section 1: Uploaded Medical Files ──
                  if (records.isNotEmpty) ...[
                    _buildSectionHeader(context, 'ملفات طبية مرفوعة',
                        Icons.folder_special_rounded, AppColors.primaryBlue),
                    const SizedBox(height: 10),
                    ...records.map((r) => _buildRecordCard(context, r)),
                    const SizedBox(height: 20),
                  ],

                  // ── Section 2: Prescription History from Appointments ──
                  if (appointments.isNotEmpty) ...[
                    _buildSectionHeader(context, 'تاريخ الوصفات الطبية',
                        Icons.medication_rounded, const Color(0xFF7C3AED)),
                    const SizedBox(height: 10),
                    ...appointments.map((a) => _buildPrescriptionCard(context, a)),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            fontFamily: 'Cairo',
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordCard(BuildContext context, MedicalRecord record) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).languageCode;

    IconData getFileIcon(String type) {
      switch (type.toLowerCase()) {
        case 'pdf':
          return Icons.picture_as_pdf_rounded;
        case 'jpg':
        case 'jpeg':
        case 'png':
          return Icons.image_rounded;
        default:
          return Icons.insert_drive_file_rounded;
      }
    }

    Color getFileColor(String type) {
      switch (type.toLowerCase()) {
        case 'pdf':
          return Colors.redAccent;
        case 'jpg':
        case 'jpeg':
        case 'png':
          return Colors.green;
        default:
          return AppColors.primaryBlue;
      }
    }

    return InkWell(
      onTap: () => _openUrl(record.url),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: getFileColor(record.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: (['jpg', 'jpeg', 'png'].contains(record.type.toLowerCase()) && record.url.isNotEmpty)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: CachedNetworkImage(
                          imageUrl: record.url,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: getFileColor(record.type),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            getFileIcon(record.type),
                            color: getFileColor(record.type),
                            size: 26,
                          ),
                        ),
                      )
                    : Icon(getFileIcon(record.type),
                        color: getFileColor(record.type), size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.access_time_rounded,
                          size: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('d MMM yyyy', locale).format(record.date),
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          record.type.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.open_in_new_rounded,
                  color: AppColors.primaryBlue, size: 20),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildPrescriptionCard(BuildContext context, Appointment appointment) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).languageCode;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF7C3AED).withValues(alpha: 0.08),
                  const Color(0xFF7C3AED).withValues(alpha: 0.03),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.event_note_rounded,
                      color: Color(0xFF7C3AED), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, d MMMM yyyy', locale)
                            .format(appointment.dateTime),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Cairo',
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1E293B),
                        ),
                      ),
                      if (appointment.doctorName != null)
                        Text(
                          'Dr. ${appointment.doctorName}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7C3AED),
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Cairo',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor Notes
                if (appointment.doctorNotes != null &&
                    appointment.doctorNotes!.isNotEmpty) ...[
                  _infoSection(
                    context: context,
                    icon: Icons.notes_rounded,
                    title: 'ملاحظات الطبيب',
                    color: AppColors.primaryBlue,
                    isDark: isDark,
                    child: Text(
                      appointment.doctorNotes!,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        fontFamily: 'Cairo',
                        color: isDark ? Colors.grey[300] : Colors.grey[800],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Patient Report
                if (appointment.patientReport != null &&
                    appointment.patientReport!.isNotEmpty) ...[
                  _infoSection(
                    context: context,
                    icon: Icons.sick_rounded,
                    title: 'شكوى المريض',
                    color: Colors.orange,
                    isDark: isDark,
                    child: Text(
                      appointment.patientReport!,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        fontFamily: 'Cairo',
                        color: isDark ? Colors.grey[300] : Colors.grey[800],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Prescriptions
                if (appointment.prescriptions.isNotEmpty) ...[
                  _infoSection(
                    context: context,
                    icon: Icons.medication_rounded,
                    title: 'الوصفة الطبية',
                    color: const Color(0xFF7C3AED),
                    isDark: isDark,
                    child: Column(
                      children: appointment.prescriptions
                          .map((med) => _buildMedicineRow(med, isDark))
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoSection({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required bool isDark,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                fontFamily: 'Cairo',
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildMedicineRow(AppointmentMedicine med, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, color: Color(0xFF7C3AED), size: 8),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (med.dosage.isNotEmpty)
                      _pill(med.dosage, Icons.scale_rounded, isDark),
                    if (med.frequency.isNotEmpty)
                      _pill(med.frequency, Icons.schedule_rounded, isDark),
                    if (med.duration.isNotEmpty)
                      _pill(med.duration, Icons.calendar_month_rounded, isDark),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: const Color(0xFF7C3AED)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Add Medical Record Bottom Sheet ──────────────────────────────────────────

class _AddMedicalRecordSheet extends StatefulWidget {
  final String patientId;
  final FirestoreService firestoreService;

  const _AddMedicalRecordSheet({
    required this.patientId,
    required this.firestoreService,
  });

  @override
  State<_AddMedicalRecordSheet> createState() => _AddMedicalRecordSheetState();
}

class _AddMedicalRecordSheetState extends State<_AddMedicalRecordSheet> {
  final _nameController = TextEditingController();
  final _storageService = StorageService();
  
  Uint8List? _fileBytes;
  String? _fileName;
  String? _selectedType; // 'pdf', 'jpg', 'png'
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(bool isImage) async {
    try {
      if (isImage) {
        final XFile? image = await _storageService.pickImageFromGallery();
        if (image != null) {
          final bytes = await image.readAsBytes();
          final ext = image.path.split('.').last.toLowerCase();
          setState(() {
            _fileBytes = bytes;
            _fileName = image.name;
            _selectedType = (['jpg', 'jpeg', 'png'].contains(ext)) ? ext : 'jpg';
          });
        }
      } else {
        final result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'doc', 'docx'],
          withData: true,
        );

        if (result != null && result.files.single.bytes != null) {
          setState(() {
            _fileBytes = result.files.single.bytes;
            _fileName = result.files.single.name;
            _selectedType = result.files.single.extension?.toLowerCase() ?? 'pdf';
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error picking file: $e');
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a record name.')),
      );
      return;
    }

    if (_fileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file first.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      // 1. Upload to Storage
      final String contentType = _selectedType == 'pdf' ? 'application/pdf' : 'image/jpeg';
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String uploadFileName = 'record_${timestamp}_${_fileName ?? "file"}';

      final String? downloadUrl = await _storageService.uploadMedicalRecord(
        patientId: widget.patientId,
        fileName: uploadFileName,
        fileBytes: _fileBytes!,
        contentType: contentType,
      );

      if (downloadUrl == null) throw Exception('Failed to upload file');

      // 2. Save metadata to Firestore
      final record = MedicalRecord(
        id: '',
        name: name,
        url: downloadUrl,
        type: _selectedType ?? 'unknown',
        date: DateTime.now(),
      );

      await widget.firestoreService.addMedicalRecord(widget.patientId, record);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medical record added successfully!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: isDark ? Colors.grey[600] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add Medical Record',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                fontFamily: 'Cairo',
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 20),
            _buildField(
                controller: _nameController,
                label: 'Record Name',
                hint: 'e.g. Blood Test Results',
                icon: Icons.description_rounded,
                isDark: isDark),
            const SizedBox(height: 20),
            Text('Select File',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[300] : Colors.grey[700])),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildPickerBtn(
                  label: 'Image',
                  icon: Icons.image_rounded,
                  onTap: () => _pickFile(true),
                  isDark: isDark,
                  isSelected: _selectedType != 'pdf' && _fileBytes != null,
                ),
                const SizedBox(width: 12),
                _buildPickerBtn(
                  label: 'PDF / Doc',
                  icon: Icons.picture_as_pdf_rounded,
                  onTap: () => _pickFile(false),
                  isDark: isDark,
                  isSelected: _selectedType == 'pdf' && _fileBytes != null,
                ),
              ],
            ),
            if (_fileName != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _fileName!,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Text('Save Record',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Cairo')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerBtn({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    required bool isSelected,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryBlue.withValues(alpha: 0.1) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? AppColors.primaryBlue : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[300]!)),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppColors.primaryBlue : (isDark ? Colors.grey[400] : Colors.grey[600])),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 12, color: isSelected ? AppColors.primaryBlue : (isDark ? Colors.grey[400] : Colors.grey[600]))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : Colors.grey[700])),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]),
            prefixIcon: Icon(icon, color: AppColors.primaryBlue),
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey[100],
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
