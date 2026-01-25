import 'package:flutter/material.dart';
import '../config/colors.dart';
import '../models/patient.dart';

/// تبويب معلومات المريض الشخصية
class PatientInfoTab extends StatelessWidget {
  final Patient patient;

  const PatientInfoTab({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16),
          // معلومات الاتصال
          _buildSection(context, 'معلومات الاتصال', [
            _buildInfoRow(Icons.phone, 'رقم الهاتف', patient.phone),
            _buildInfoRow(Icons.email, 'البريد الإلكتروني', patient.email),
            if (patient.address != null)
              _buildInfoRow(Icons.location_on, 'العنوان', patient.address!),
          ]),
          // السجل الطبي
          if (patient.chronicDiseases.isNotEmpty ||
              patient.allergies.isNotEmpty ||
              patient.previousSurgeries.isNotEmpty ||
              patient.currentMedications.isNotEmpty)
            _buildSection(context, 'السجل الطبي', [
              if (patient.chronicDiseases.isNotEmpty)
                _buildListTile('الأمراض المزمنة', patient.chronicDiseases),
              if (patient.allergies.isNotEmpty)
                _buildListTile('الحساسية', patient.allergies),
              if (patient.previousSurgeries.isNotEmpty)
                _buildListTile('العمليات السابقة', patient.previousSurgeries),
              if (patient.currentMedications.isNotEmpty)
                _buildListTile('الأدوية الحالية', patient.currentMedications),
            ]),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 24),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(String title, List<String> items) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
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
          ...items.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 4, right: 8),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 6, color: AppColors.primaryBlue),
                  SizedBox(width: 8),
                  Text(item, style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
