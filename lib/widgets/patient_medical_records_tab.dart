import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/colors.dart';
import '../models/medical_record.dart';
import '../services/firestore_service.dart';

/// تبويب السجلات الطبية للمريض
class PatientMedicalRecordsTab extends StatelessWidget {
  final String patientId;
  final FirestoreService _firestoreService = FirestoreService();

  PatientMedicalRecordsTab({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MedicalRecord>>(
      stream: _firestoreService.getPatientMedicalRecords(patientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ في تحميل السجلات الطبية'));
        }

        final records = snapshot.data ?? [];

        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.medical_services,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: 16),
                Text(
                  'لا توجد سجلات طبية',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            return _buildRecordCard(context, record);
          },
        );
      },
    );
  }

  Widget _buildRecordCard(BuildContext context, MedicalRecord record) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: EdgeInsets.all(16),
        childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.medical_information, color: AppColors.primaryBlue),
        ),
        title: Text(
          record.diagnosis,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              DateFormat('d MMMM yyyy', 'ar').format(record.createdAt),
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            if (record.doctorName != null) ...[
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: AppColors.textSecondary),
                  SizedBox(width: 4),
                  Text(
                    'د. ${record.doctorName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        children: [
          // الأعراض
          if (record.symptoms.isNotEmpty) ...[
            _buildSubSection('الأعراض', [
              ...record.symptoms.map(
                (symptom) => Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.circle, size: 6, color: AppColors.primaryBlue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(symptom, style: TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              ),
            ]),
            SizedBox(height: 12),
          ],
          // الوصفات الطبية
          if (record.prescriptions.isNotEmpty) ...[
            _buildSubSection('الوصفات الطبية', [
              ...record.prescriptions.map(
                (prescription) => _buildPrescriptionCard(prescription),
              ),
            ]),
            SizedBox(height: 12),
          ],
          // الملاحظات
          if (record.notes != null && record.notes!.isNotEmpty) ...[
            _buildSubSection('ملاحظات', [
              Text(
                record.notes!,
                style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
              ),
            ]),
            SizedBox(height: 12),
          ],
          // المرفقات
          if (record.attachments.isNotEmpty) ...[
            _buildSubSection('المرفقات', [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: record.attachments.map((url) {
                  return InkWell(
                    onTap: () => _openAttachment(context, url),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.attach_file,
                            size: 16,
                            color: AppColors.primaryBlue,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'مرفق',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildSubSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildPrescriptionCard(Prescription prescription) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            prescription.medication,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          _buildPrescriptionDetail('الجرعة', prescription.dosage),
          _buildPrescriptionDetail('عدد المرات', prescription.frequency),
          _buildPrescriptionDetail('المدة', prescription.duration),
          if (prescription.instructions != null &&
              prescription.instructions!.isNotEmpty)
            _buildPrescriptionDetail('تعليمات', prescription.instructions!),
        ],
      ),
    );
  }

  Widget _buildPrescriptionDetail(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  void _openAttachment(BuildContext context, String url) {
    // يمكن فتح المرفق في متصفح أو عارض مناسب
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('فتح المرفق: $url')));
    // TODO: يمكن استخدام url_launcher لفتح الرابط
  }
}
